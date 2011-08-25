// network driver

module NetworkManager;

import lib.Params;
import lib.client.NetClientManager;
import lib.server.NetServerManager;
import tango.net.Socket;
import tango.io.Stdout;
import tango.core.Thread;

int main(char[][] args) {
	if (args.length < 2) {
		Stdout.formatln("usage:  {} <server or client>", args[0]);
		return 0;
	}	
	
	if (args[1] == "server") {
		char[] recv;
		Stdout.formatln("creating server...");
		NetServer server = new NetServer();
		Stdout.format("waiting").flush;
		while (server.isEmpty())
			Stdout.format(".").flush;
		Stdout.formatln("");
		recv = cast(char[])server.recv_s();
		Stdout.formatln("server:  received~{}~", recv);
		Thread.sleep(.2);
		server.send_s(cast(ubyte[])"hallo yourself!");
	} else {
		char[] recv;
		Stdout.formatln("creating client...");
		NetClient client = new NetClient(new IPv4Address("localhost"));
		client.send_c(cast(ubyte[])"why hallo thar!");
		recv = cast(char[])client.recv_c();
		Stdout.formatln("client:  received~{}~", recv);
	}
	
	return 0;
}

