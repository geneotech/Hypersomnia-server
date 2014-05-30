#pragma once
#include "stdafx.h"
#include "game_framework/resources/lua_state_wrapper.h"
#include "game_framework/game_framework.h"

#include "utilities/network/udp.h"
#include "utilities/error/error.h"

#include "server/worker_thread.h"
#include "server/connected_user.h"

using namespace augs;

int main() {
	augs::global_log.open(L"engine_errors.txt");
	
	framework::init();
	
	resources::lua_state_wrapper lua_state;
	lua_state.bind_whole_engine();

	lua_state.dofile("init.lua"); 

	if (network::init()) { 
		using namespace network;
		udp udp_socket; 

		if (udp_socket.open()) {
			udp_socket.set_blocking(true);

			int worker_amount = threads::get_num_cores() * 2; 

			if (udp_socket.bind(27017)) {
				//while (true) { 
					network::ip from;
					wsabuf output;
					char buffer[10000];
					output.set(buffer, sizeof(buffer));
					unsigned long bytes_received;
					unsigned long flags;

					udp_socket.recv(from, output, bytes_received, flags);
				//}
			}
		}
	}  
	augs::network::deinit();
	 
	framework::deinit();
	return 0;
}  