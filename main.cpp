#pragma once
#include "stdafx.h"
#include "game_framework/resources/lua_state_wrapper.h"
#include "game_framework/game_framework.h"

#include "utilities/network/udp.h"
#include "utilities/error/error.h"

#include "server/worker_thread.h"
#include "server/connected_user.h"

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
		new_session.start_receiving_packets(27017);
	}  
	augs::network::deinit();
	 
	framework::deinit();
	return 0;
}  