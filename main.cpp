#pragma once
#include "stdafx.h"
#include "game_framework/resources/lua_state_wrapper.h"
#include "game_framework/game_framework.h"

#include "utilities/network/network.h"
#include "utilities/error/error.h"

#include "server/worker_thread.h"
#include "server/connected_user.h"

using namespace augs;

int main() {
	framework::init();

	resources::lua_state_wrapper lua_state;
	lua_state.bind_whole_engine();

	lua_state.dofile("init.lua"); 
	
	std::vector<std::function<void()>> worker_functions;
	std::unique_ptr<worker_thread_info[]> worker_infos;

	if (network::init()) {
		threads::iocp completion_port;
		using namespace network;
		udp udp_socket; 

		if (udp_socket.open()) {
			completion_port.open();
			completion_port.associate(udp_socket, 0);

			int worker_amount = threads::get_num_cores() * 2; 

			worker_functions.resize(worker_amount);
			worker_infos.reset(new worker_thread_info[worker_amount]);
			
			for (int i = 0; i < worker_amount; ++i) {
				worker_infos[i].owner_iocp = &completion_port;
				worker_functions[i] = std::bind(main_hypersomnia_worker_thread, std::ref(worker_infos[i]));
				completion_port.add_worker(&worker_functions[i]);
			}

			if (udp_socket.bind(27017)) {
				/* initialize several pending reads on the main channel */
				
				//int sres = udp_socket.send(to, buf("he he hellmanns", strlen("he he hellmanns") + 1), &tsend);
			}
		}

		completion_port.close();
	} 
	augs::network::deinit();
	 
	framework::deinit();
	return 0;
}  