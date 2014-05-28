#pragma once
#include "utilities/threads/threads.h"
#include "utilities/network/network.h"

struct connected_user;

struct main_channel_recv_op : augs::threads::overlapped_userdata {
	void on_completion(augs::threads::overlapped* owner) override;
};

struct main_channel_send_op : augs::threads::overlapped_userdata {
	void on_completion(augs::threads::overlapped* owner) override;
};