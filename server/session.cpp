#pragma once
#include "stdafx.h"
#include "session.h" 

using namespace augs;
 
void session::start_receiving_packets(int port) {
	using namespace augs::network;
	udp udp_socket;

	if (udp_socket.open()) {
		udp_socket.set_blocking(true);

		if (udp_socket.bind(port)) {
			network::ip from;
			wsabuf output;
			char buffer[10000];
			memset(buffer, 0, sizeof(buffer));
			output.set(buffer, sizeof(buffer));
			unsigned long bytes_received = 0;
			unsigned long flags = 0;

			udp_socket.recv(from, output, bytes_received, flags);
		}
	}
}