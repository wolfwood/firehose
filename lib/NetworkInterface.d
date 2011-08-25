// teh nets -- plz hide them from me

module lib.NetworkInterface;

import lib.Packet;


interface ClientNetworkInterface
{
	void send_c(ubyte[] data);
	ubyte[] recv_c();
}

interface ServerNetworkInterface
{
	void send_s(ubyte[] data);
	ubyte[] recv_s();
	bool isEmpty();
}
