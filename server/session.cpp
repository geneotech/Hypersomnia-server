#pragma once
#include "stdafx.h"
#include "session.h" 

using namespace augs;

session::session() {}

session::connection::connection(session& owner_session) : owner_session(owner_session) {}

void session::connection::handle_packet(augs::network::udp::recv_result data) {
	/* decompress it */

}

void session::loop() {
	decltype(incoming_packets) new_packets;

	{
		std::lock_guard<std::mutex> lock(packet_queue_mutex);
		new_packets = incoming_packets;
		incoming_packets.clear();
	}

	for (auto& new_packet : new_packets) {
		std::pair<std::unordered_map<unsigned long, connection>::iterator, bool> existing_or_new_connection;

		{
			std::lock_guard<std::mutex> lock(connections_mutex);

			/* map the received packet to an existing connection or create a new one */
			existing_or_new_connection = connections.emplace(new_packet.sender_address.get_address_as_uint(), *this);
		}

		if (existing_or_new_connection.second) {
			/* we have a new connection! */
			std::cout << "Somebody connected." << std::endl;
		}

		(*existing_or_new_connection.first).second.last_received_packet.reset();

		/* dispatch connection-specific logic into worker thread
		at this moment the iterator MUST be valid as only an incoming packet can stimulate connection removal
		and packets come one-by-one only in this thread
		or it may be timeout but timeout checks are only done in this thread after packet handling
		*/

		std::cout << "Bytes: " << new_packet.bytes_transferred << "\nMessage: " << new_packet.message.data.data() << std::endl;
	}


	/* finally, check for timeouts */
	if (timeout_check_timer.get<std::chrono::milliseconds>() >= check_for_timeouts_every_ms) {
		/* it is time to check for timeouts, lock connection state */
		std::lock_guard<std::mutex> lock(connections_mutex);

		std::vector<decltype(connections.begin())> connections_to_remove;

		for (auto iter = connections.begin(); iter != connections.end(); ++iter) {
			if ((*iter).second.request_removal || (*iter).second.last_received_packet.get<std::chrono::milliseconds>() > timeout_after_ms) {
				connections_to_remove.push_back(iter);
				std::cout << "Connection timed out." << std::endl;
			}
		}

		for (auto& iter : connections_to_remove) {
			connections.erase(iter);
		}

		timeout_check_timer.reset();
	}
}

void session::network_thread_procedure() {
	while (!requesting_shutdown) {
		auto result = udp_socket.recv();

		if (result.result == network::io_result::SUCCESSFUL && result.bytes_transferred > 0) {
			std::lock_guard<std::mutex> lock(packet_queue_mutex);

			incoming_packets.push_back(result);
		}

		/* do send-related stuff */
	}
}

bool session::start_network_thread(int port) {
	using namespace network;

	if (udp_socket.open()) {
		udp_socket.set_blocking(false);

		if (udp_socket.bind(port))
			network_thread = std::thread(std::bind(&session::network_thread_procedure, this));
	}
}