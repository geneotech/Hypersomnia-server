#pragma once
#include <vector>
#include "game_framework/resources/lua_state_wrapper.h"
#include "network/udp.h"

#include "misc/timer.h"
#include "threads/pool.h"

#include <mutex>
#include <unordered_map>

struct session {
	struct connection {
		augs::misc::timer last_received_packet;

		bool request_removal = false;

		/* handles incoming packet in the context of connection, executed in thread pool
		whenever it needs to interact with some global, shared state, it enters an according critical section
		*/
		void handle_packet(augs::network::udp::recv_result data);

		/* just a draft; sending functions with several modes that may or may not guarantee the delivery. */
		void send_unreliable(augs::network::packet);
		void send_reliable(augs::network::packet);

		session& owner_session;
		connection(session&);
	};

	session();

	resources::lua_state_wrapper global_lua_state;

	double timeout_after_ms = 3000.0;
	double check_for_timeouts_every_ms = 500.0;

	augs::misc::timer timeout_check_timer;

	std::mutex connections_mutex;

	/* map ip address as uint to the connection structure */
	std::unordered_map<unsigned long, connection> connections;

	std::mutex packet_queue_mutex;
	std::vector<augs::network::udp::recv_result> incoming_packets;
	
	augs::network::udp udp_socket;

	std::thread network_thread;

	void network_thread_procedure();
	bool start_network_thread(int port);

	void loop();

	bool requesting_shutdown = false;
};