#pragma once
#include "misc/timer.h"
#include "utilities/network/network.h"

struct connected_user {
	augs::misc::timer last_received_packet;
};