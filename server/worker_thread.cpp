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
		auto completion_result = completion_port->get_completion(completion_object);
		completion_object.get_operation_info(current_operation);

		if (completion_result == FALSE) {
			/* overlapped is null: dequeue error: failed to dequeue anything (eg. timeout) */
			if (!current_operation) {
				// completion_port->post_completion(threads::iocp::QUIT); // quit
			}
			/* i/o error: i/o operation failed */
			else {
				// completion_port->post_completion(threads::iocp::QUIT); // quit
			}
		}
		else {
			/* succesfull i/o operation */
			if (current_operation) {
				current_operation->userdata->on_completion(current_operation);
			}
			/* else it must have been a custom completion posted */
			else {
				completion_port->post_completion(threads::iocp::QUIT); // quit
				break;
			}
		}
	}
}
