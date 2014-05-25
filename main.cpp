#pragma once
#include "stdafx.h"
#include "game_framework/resources/lua_state_wrapper.h"
#include "game_framework/game_framework.h"

#include "utilities/network/network.h"
#include "utilities/error/error.h"


//struct user : public db::network::overlapped {
//	char buffer[1000];
//	buf b;
//	tcp client;
//	user() : b(buffer, 1000) {
//		trecv.who = tsend.who = this;
//	}
//
//	struct uoverlapped : public db::network::overlapped {
//		user* who;
//	} trecv, tsend;
//
//} users[10];
//int ui = -1;

using namespace augs;
int work(threads::iocp* io) {
	threads::completion comp;
	network::overlapped_accept* acc, tacc;
	//user* u, *root;
	//user::uoverlapped *uov;
	
	while (true) {
		if (io->get_completion(comp)) {
	//
	//		if (comp.get_user(u)) {
	//			if (comp.get_key() == 0) {
	//				++ui; ui %= 10;
	//				comp.get_overlapped(acc);
	//				users[ui].client.open(*acc);
	//
	//				s.accept(&tacc);
	//
	//				users[ui].client.linger(true, 100);
	//
	//				io->associate(users[ui].client, 1);
	//
	//				users[ui].client.recv(&users[ui].b, 1, &users[ui].trecv);
	//				users[ui].client.send(&bb, 1, &users[ui].tsend);
	//
	//				//	users[ui].client.close();
	//			}
	//			else if (comp.get_key() == 1) {
	//				uov = (user::uoverlapped*)u;
	//				root = (uov->who);
	//				if (uov == &(root->tsend)) {
	//					cout << uov->get_result() << " bytes sent." << endl;
	//				}
	//				else {
	//					cout << "from: " << root->client.addr.get_ipv4() << endl;
	//					cout << root->buffer << endl;
	//				}
	//			}
	//		}
	//		else {
	//			io->post_completion(io->QUIT); // quit
	//			break;
	//		}
	//	}
	//	else if (!comp.get_user(u)) {
	//		// timeout
	//	}
	//	else {
	//
		}// error
	}
	//
	return 0;
}

int main() {
	framework::init();

	resources::lua_state_wrapper lua_state;
	lua_state.bind_whole_engine();

	lua_state.dofile("init.lua"); 

	//RedirectIOToConsole();
	augs::network::tcp accept_socket;
	if (augs::network::init())
	{
		char buffer[1000];

		augs::network::overlapped_accept tacc;
		augs::threads::iocp completion_port;

		if (accept_socket.open()) {

			//s.linger(true, 100);
			accept_socket.nagle(false);
			accept_socket.bind(27017);
			if (accept_socket.listen(27017)) {
				completion_port.open();
				completion_port.associate(accept_socket, 0);
				completion_port.create_pool(work, &completion_port, 0);

				int accres = accept_socket.accept(&tacc);

				std::cout << accres << std::endl;
				work(&completion_port);
			}
		}

		accept_socket.close();
		//for (int i = 0; i < 10; ++i)
		//	users[i].~user();

		completion_port.close();
	} 
	augs::network::deinit();
	 
	framework::deinit();
	return 0;
}  