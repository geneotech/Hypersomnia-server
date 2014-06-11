#pragma once
#include "network/network_interface.h"

#include "game_framework/resources/lua_state_wrapper.h"
#include "game_framework/game_framework.h"

#include "utilities/error/error.h"

using namespace augs;

enum GameMessages
{
	ID_GAME_MESSAGE_1 = ID_USER_PACKET_ENUM + 1
};

int main() {
	augs::global_log.open(L"engine_errors.txt");
	
	framework::init();

	resources::lua_state_wrapper lua_state;
	lua_state.bind_whole_engine();

	lua_state.dofile("init.lua"); 
	 
	network::network_interface server;
	server.listen(37017, 2, 4);

	network::network_interface::packet received;

	while (1)
	{ 
		if (server.receive(received))
		{
			switch (received.byte(0))
			{
			case ID_NEW_INCOMING_CONNECTION:
				printf("A connection is incoming.\n");
				break;
			case ID_DISCONNECTION_NOTIFICATION:
				printf("A client has disconnected.\n");
				break;
			case ID_CONNECTION_LOST:
				printf("A client lost the connection.\n");
				break;

			case ID_GAME_MESSAGE_1:
			{
				RakNet::RakString rs;
				RakNet::BitStream bsIn(received.info->data, received.info->length, false);
				bsIn.IgnoreBytes(sizeof(RakNet::MessageID));
				bsIn.Read(rs);
				printf("%s\n", rs.C_String());


				RakNet::BitStream bsOut;
				bsOut.Write((RakNet::MessageID)ID_GAME_MESSAGE_1);
				bsOut.Write("Hello world");
				server.peer->Send(&bsOut, HIGH_PRIORITY, RELIABLE_ORDERED, 0, (received.info->guid), false);
			}
				break;

			default:
				printf("Message with identifier %i has arrived.\n", received.info->data[0]);
				break;
			}
		}
	}

	framework::deinit();
	return 0;
}  