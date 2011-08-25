// firehose - converting uploads to downloads for fun and profit

module Firehose;

import lib.Params;
import lib.VirtualFrame;
import util.GroupSet;

import lib.FirehoseManager;

import lib.client.FirehoseClientManager;
import lib.server.FirehoseServerManager;

import lib.server.DummyServerManager;
import lib.client.DummyClientManager;

import lib.NetworkInterface;
import lib.FakeNIC;

import lib.Statistics;

import tango.core.Thread; 

/*
import tango.io.Stdout,
	tango.io.FileConduit;

import tango.text.ArgParser,
	tango.text.LineIterator;
*/

Params parseArgs(char[][] args)
{
	Params params;

	/*
	char[][] fileList;
	char[] responseFile = null;
	char[] varx = null;
	bool coolAction = false;
	bool displayHelp = false;
	char[] helpText = "Available options:\n\t\t-h\tthis 
         help\n\t\t-cool-option\tdo cool things to your 
         files\n\t\t@filename\tuse filename as a response 
         file with extra arguments\n\t\tall other arguments 
         are handled as files to do cool things with.";
	ArgParser parser = new ArgParser((char[] value,uint ordinal){
			Stdout.format("Added file number {0} to list of files", ordinal).newline;
			fileList ~= value;
    });

	parser.bind("-", "h",{
			displayHelp=true;
    });

	parser.bind("-", "cool-action",{
			coolAction=true;
    });

	parser.bind("-", "X=",(char[] value){
			varx=value;
    });
	
	parser.bindDefault("@",(char[] value, uint ordinal){
			if (ordinal > 0) {
				throw new Exception("Only one response file can be given.");
			}
			responseFile = value;
    });
	if (args.length < 2) {
		Stdout(helpText).newline;
		return;
	}
	parser.parse(args[1..$]);

	if (displayHelp) {
		Stdout(helpText).newline;
	}
	else {
		if (responseFile !is null) {
			auto file = new FileConduit(responseFile);
			// create an iterator and bind it to the file
			auto lines = new LineIterator(file);
			// process file one line at a time
			char[][] arguments;
			foreach (line; lines) {
				arguments ~= line;

			}
			parser.parse(arguments);
		}
		if (coolAction) {
			Stdout("Listing the files to be actioned in a cool way.").newline;
			foreach (id, file; fileList) {
				Stdout.format("{0}. {1}", id + 1, file).newline;
			}
			Stdout("Cool and secret action performed.").newline;
		}
		if (varx !is null) {
			Stdout.format("User set the X factor to \"{0}\".", varx).newline;
		}
	}

*/

	return params;
}

int main(char[][] args){
	auto globalParams = parseArgs(args);

	bool fake = true, dummy = false;

	FakeNIC nic = new FakeNIC;

	ClientNetworkInterface clientNIC;
	ServerNetworkInterface serverNIC;

	Statistics cstat = new Statistics();
	Statistics sstat = new Statistics();

	
	if(fake){
		clientNIC = nic;
		serverNIC = nic;

		auto serverParams = globalParams;

		serverParams.isServer = true;
		serverParams.filename = "outfile";

		FirehoseManager smanager;

		if(dummy){
			smanager = new DummyServerManager(serverParams, serverNIC);
		}else{
			smanager = new FirehoseServerManager(serverParams, serverNIC, sstat);
		}

		// launch
		auto serverthread = new Thread(&smanager.astrobaseGo);
		serverthread.start();



		// init ReceiverManager

		auto clientParams = globalParams;

		clientParams.isServer = false;
		clientParams.filename = "infile";

		FirehoseManager cmanager;

		if(dummy){
			cmanager = new DummyClientManager(clientParams, clientNIC);
		}else{
			cmanager = new FirehoseClientManager(clientParams, clientNIC, cstat);
		}

		// launch
		auto clientthread = new Thread(&cmanager.astrobaseGo);
		clientthread.start();


		serverthread.join();
		clientthread.join();
	}else{

		// init network




		if(globalParams.isServer){

			// do init packet stuffs
			



			// init ServerManager
			auto manager = new FirehoseServerManager(globalParams, serverNIC, sstat);
		
			// launch
			manager.astrobaseGo();
		}else{

			// do init packet stuffs
			



			// init ReceiverManager
			auto manager = new FirehoseClientManager(globalParams, clientNIC, cstat);
			
			// launch
			manager.astrobaseGo();
		}
	}

	return 0;
}
