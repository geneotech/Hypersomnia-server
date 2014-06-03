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

		/* handles incoming packet in the context of connection, executed in thread pool
		whenever it needs to interact with some global, shared state, it enters an according critical section
		*/
		void handle_packet(augs::network::udp::recv_result data);

		session& owner_session;
		connection(session&);
	};

	session() = default;
	session(unsigned num_of_workers);

	augs::network::udp socket;

	resources::lua_state_wrapper global_lua_state;


	std::mutex connection_vector_mutex;

	/* map ip address as uint to the connection structure */
	std::unordered_map<unsigned long, connection> connections;

	void start_receiving_packets(int port);

	augs::threads::pool main_worker_pool;
};