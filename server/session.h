#pragma once
#include <vector>

#include "game_framework/resources/lua_state_wrapper.h"
#include "network/udp.h"
#include "connected_user.h"

struct session {
	augs::network::udp socket;

	resources::lua_state_wrapper global_lua_state;

	std::vector<connected_user> connections;

	void start_receiving_packets(int port);
};