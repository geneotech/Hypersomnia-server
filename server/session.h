#pragma once
#include <vector>

#include "game_framework/resources/lua_state_wrapper.h"
#include "connected_user.h"

class session {
public:
	resources::lua_state_wrapper global_lua_state;

	std::vector<connected_user> connections;
};