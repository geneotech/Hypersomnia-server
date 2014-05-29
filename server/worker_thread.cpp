#pragma once
#include "stdafx.h"
#include "worker_thread.h"
#include "utilities/network/network.h"

#include "connected_user.h"
#include "io_operations.h"
#include "game_framework/resources/lua_state_wrapper.h"

using namespace augs;

worker_thread_info::worker_thread_info() : pending_recv_operation_slot(new main_channel_recv_op) {}

void main_hypersomnia_worker_thread(worker_thread_info& worker_info) {
	/* initialize thread-specific lua state to perform scripted callbacks */
	resources::lua_state_wrapper lua_state;
	lua_state.bind_whole_engine();

	threads::completion completion_object;
	threads::overlapped* current_operation;

	auto* completion_port = worker_info.owner_iocp;

	while (true) {
		auto completion_object = completion_port->get_completion();
		completion_object.get_operation_info(current_operation);
		
		switch (completion_object.result_type) {
		case threads::completion::result::FAILED_TO_DEQUEUE_OR_TIMEOUT:
			break;

		case threads::completion::result::FAILED_IO_OPERATION:
			break;

		case threads::completion::result::SUCCESSFUL_IO_OP_OR_CUSTOM:
			current_operation->userdata->on_completion(current_operation);
			break;

		case threads::completion::result::CUSTOM_POST:
			completion_port->post_completion(threads::iocp::QUIT); // quit
			break;

		default: break;
		}
	}
}
