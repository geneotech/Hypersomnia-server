#pragma once
#include "utilities/threads/threads.h"
#include "utilities/network/network.h"

struct worker_thread_info {
	augs::threads::iocp* owner_iocp;
	augs::network::overlapped pending_recv_operation_slot;

	worker_thread_info();
};

void main_hypersomnia_worker_thread(worker_thread_info&);

