// delovely

module lib.FakeNIC;

import lib.NetworkInterface;

import tango.core.sync.Mutex;
import tango.core.sync.Semaphore;


import tango.io.Stdout;

import tango.core.Thread; 

//const debugFlag = true;
const debugFlag = true;

class FakeNIC: ClientNetworkInterface, ServerNetworkInterface {
	// receive queues
	ubyte[][] client, server;

	Mutex cmtx, smtx;

	Semaphore csem, ssem;

	this(){
		cmtx = new Mutex;
		smtx = new Mutex;

		csem = new Semaphore(0);
		ssem = new Semaphore(0);
	}

	void send_c(ubyte[] data){
		
		static if(debugFlag){Stdout.formatln("Csend: {}", data);}

		smtx.lock();
		//server ~= data.dup;
		server ~= data;
		static if(debugFlag){Stdout.formatln("Csend in lock: {}", data[0..4]);}
		smtx.unlock();

		ssem.notify();

		
		static if(debugFlag){Stdout.formatln("Csend post notify: {}", data[0..4]);}
		Thread.yield();
		static if(debugFlag){Stdout.formatln("Csend post yield: {}", data[0..4]);}
	}

	ubyte[] recv_c(){
		//assert(client.length != 0);
		//if(client.length == 0){
		//block until data
		//}

		static if(debugFlag){Stdout.formatln("Crecv: prewait");}
		csem.wait();
		static if(debugFlag){Stdout.formatln("Crecv: postwait");}

		cmtx.lock();
		ubyte[] data = client[0];

		client = client[1..$];

		static if(debugFlag){Stdout.formatln("Crecv: in lock - {}", data);}
		cmtx.unlock();

		return data;

	}

	void send_s(ubyte[] data){

		static if(debugFlag){Stdout.formatln("Ssend: {}", data);}

		cmtx.lock();

		//client ~= data.dup;
		client ~= data;
		static if(debugFlag){Stdout.formatln("Ssend in lock: {}", data[0..4]);}

		cmtx.unlock();

		csem.notify();

		static if(debugFlag){Stdout.formatln("Ssend post notify: {}", data[0..4]);}
		Thread.yield();
		static if(debugFlag){Stdout.formatln("Ssend post yield: {}", data[0..4]);}
	}

	ubyte[] recv_s(){
		//assert(server.length != 0);
		//if(server.length == 0){
		//block until data
		//}

		static if(debugFlag){Stdout.formatln("Srecv: prewait");}
		ssem.wait();
		static if(debugFlag){Stdout.formatln("Srecv: postwait");}

		assert(server.length != 0);

		smtx.lock();
		ubyte[] data = server[0];

		server = server[1..$];

		static if(debugFlag){Stdout.formatln("Srecv: in lock - {}", data);}
		smtx.unlock();

		return data;
	}

	bool isEmpty(){
		Thread.yield();
		
		smtx.lock();
		auto tmp = server.length;
		smtx.unlock();

		return (tmp == 0);
	}

}