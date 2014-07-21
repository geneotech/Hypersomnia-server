#pragma once
#include "utilities/lua_state_wrapper.h"
#include "game_framework/game_framework.h"

#include "utilities/error/error.h"

using namespace augs;

int main() {
	augs::global_log.open(L"engine_errors.txt");
	
	framework::init();

	augs::lua_state_wrapper lua_state;
	framework::bind_whole_engine(lua_state);

	lua_state.dofile("init.lua"); 

	framework::deinit();
	return 0;
}