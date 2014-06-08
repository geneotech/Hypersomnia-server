#pragma once
#include "stdafx.h"
#include "game_framework/resources/lua_state_wrapper.h"
#include "game_framework/game_framework.h"

#include "utilities/network/udp.h"
#include "utilities/error/error.h"

#include "server/worker_thread.h"

#include "server/session.h"

using namespace augs;

int main() {
	augs::global_log.open(L"engine_errors.txt");
	
	framework::init();
	
	resources::lua_state_wrapper lua_state;
	lua_state.bind_whole_engine();

	lua_state.dofile("init.lua"); 

	if (network::init()) {  
		session new_session;
		if (new_session.start_network_thread(27017)) {
			while (true)
				new_session.loop();
		}
	}  

	augs::network::deinit(); 
	 
	framework::deinit();
	return 0;
}  