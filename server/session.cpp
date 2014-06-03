#pragma once
#include "stdafx.h"
#include "session.h" 

using namespace augs;
 
session::session(unsigned num_of_workers) : main_worker_pool(num_of_workers) {}

session::connection::connection(session& owner_session) : owner_session(owner_session) {}

void session::connection::handle_packet(augs::network::udp::recv_result data) {
	/* decompress it */

}

void session::start_receiving_packets(int port) {
	using namespace network;
	udp udp_socket;

	if (udp_socket.open()) {
		udp_socket.set_blocking(true);

		if (udp_socket.bind(port)) {
			while (true) {
				auto result = udp_socket.recv();
				
				if (result.result == network::io_result::SUCCESSFUL && result.bytes_transferred > 0) {
					/* map the received packet to an existing connection or create a new one */
					auto existing_or_new_connection = connections.emplace(result.sender_address.get_address_as_uint(), *this);
					
					if (existing_or_new_connection.second) {
						/* we have a new connection! */
						// std::cout << "somebody connected." << std::endl;
					}

					/* dispatch connection-specific logic into worker thread */
					main_worker_pool.enqueue(std::bind(&session::connection::handle_packet, &(*existing_or_new_connection.first).second, result));
				}
				
				// std::cout << "Bytes: " << result.bytes_transferred << "\nMessage: " << result.message.data.data() << std::endl;
			}
		}
	}
}