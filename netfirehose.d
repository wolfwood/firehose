// firehose - converting uploads to downloads for fun and profit

module NetFirehose;

import lib.Params;
import util.GroupSet;

import lib.FirehoseManager;

import lib.client.FirehoseClientManager;
import lib.server.FirehoseServerManager;

import lib.server.DummyServerManager;
import lib.client.DummyClientManager;

import lib.NetworkInterface;
import lib.server.NetServerManager;
import lib.client.NetClientManager;

import tango.core.Thread;
import tango.io.Stdout;
import tango.net.Socket;

import lib.Statistics;

Params parseArgs(char[][] args)
{
	Params params;
	if (args.length < 2)
		Stdout.formatln("usage:  {} <server or client>", args[0]);
		
	if (args[1] == "server") {
		params.isServer = true;
		params.filename = "outfile";
	} else {
		params.isServer = false;
		params.filename = "infile";
	}
	
	return params;
}

int main(char[][] args){
	// thats mah dummy!
	bool dummy = false;

	Statistics stat = new Statistics();
	
	auto myParams = parseArgs(args);
	
	myParams.stats = stat;

	FirehoseManager manager;


	if (myParams.isServer) {
		ServerNetworkInterface serverNIC = new NetServer(new IPv4Address("localhost"), stat);
		
		if(dummy) {
			manager = new DummyServerManager(myParams, serverNIC);
		} else {
			manager = new FirehoseServerManager(myParams, serverNIC, stat);
		}
	} else {
		ClientNetworkInterface clientNIC = new NetClient(new IPv4Address("localhost"), stat);
		
		if(dummy){
			manager = new DummyClientManager(myParams, clientNIC);
		}else{
			manager = new FirehoseClientManager(myParams, clientNIC, stat);
		}
	}
	
	manager.astrobaseGo();
	return 0;
}
