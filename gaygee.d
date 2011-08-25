// firehose - converting uploads to downloads for fun and profit

module NetFirehose;

import lib.Params;

import lib.NetworkInterface;
import lib.server.NetServerManager;
import lib.client.NetClientManager;

import tango.core.Thread;
import tango.io.Stdout;
import tango.net.Socket;
import tango.core.BitArray;

import lib.Statistics;
import lib.Params;
import util.DynamicRangeEncoder;

int num_iters = 10;

//char[][] files = ["in10", "in11", "in12", "in13", "in14", "in15", "in16", "in17", "in18", "in19"];
//int curfile = 0;


ulong rdtsc()
{
    asm
    {
        naked;
        rdtsc;
        ret;
    }
}


Params parseArgs(char[][] args)
{
	Params params;

	if (args[1] == "client") {
		params.isServer = false;
		params.filename = args[2];
	}
	else
		params.isServer = true;

	params.groupSize = 8;
	
	return params;
}

int main(char[][] args){
	if (args.length < 2) {
		Stdout.formatln("usage:  {} <server or client>", args[0]);
		return 1;
	}
	if ((args[1] == "client") && (args.length < 4)) {
		Stdout.formatln("usage:  {} client <file to send> <IP to send to>", args[0]);
		return 1;
	}
	
	auto params = parseArgs(args);
		
	Statistics stat = new Statistics();
	
	params.stats = stat;
	ubyte[] buf;
	BitArray code;
	uint[] counts;
	uint[] len;
	uint total = 0;

	if (params.isServer) {
		ServerNetworkInterface serverNIC = new NetServer(stat);
		
		counts.length = (1 << params.groupSize);
		for (int i = 0; i < (1 << params.groupSize); i++) {
			counts[i] = 1;
		}
		
		dynamicranger decoder = new dynamicranger(params, counts);
		
		for (int i = 0; i < num_iters; i++) {
			// wait for init packet
			while (serverNIC.isEmpty()) {
				//Stdout.format(".");
				//Stdout.flush();
			}
			
			buf = serverNIC.recv_s();
			len = cast(uint[])buf[0 .. 4];
			
			buf = cast(ubyte[])decoder.getcounts();
			serverNIC.send_s(buf);
			
			// wait for code word
			///while (serverNIC.isEmpty()) {
				//Stdout.format("*");
				//Stdout.flush();
			//}
			//Stdout.formatln("");
			
			//Stdout.formatln("{}:  file length:  {}", i, len[0]);
			
			ubyte[] codebuf;
			buf = serverNIC.recv_s();
			while (buf[0] != 'E') {
				codebuf ~= buf[1 .. $];
				buf = serverNIC.recv_s();
			}
			
			code.init(codebuf, (codebuf.length * 8));
			
			//Stdout.formatln("{}:  code length:  {}", i, code.length());
			//Stdout.formatln("{}:  code buf length:  {}", i, codebuf.length);
			
			decoder.decode(code, len[0]);
			
			total += len[0];
			stat.display(total);
			
			//Stdout.formatln("{}:  DONE!", i);
			Stdout.formatln("=======================================");
			//Thread.sleep(0.1);
		}
	} else {
		ClientNetworkInterface clientNIC = new NetClient(new IPv4Address(args[3]), stat);
		dynamicranger encoder = new dynamicranger(params, counts);
		
		for (int i = 0; i < 10; i++) {
			len.length = 1;
			len[0] = encoder.getfilelen();
			buf = cast(ubyte[])len;
			clientNIC.send_c(buf);
			
			buf = clientNIC.recv_c();
			counts = cast(uint[])buf;
			
			encoder.newcounts(counts);

			ulong before = rdtsc();

			code = encoder.encode(len[0]);
			
			ulong after = rdtsc();

			Stdout.formatln("cycles to encode: {}", (after - before));
			
			//Stdout.formatln("{}:  file length:  {}", i, len[0]);
			//Stdout.formatln("{}:  code length:  {}", i, code.length());
			
			buf = cast(ubyte[])(code.opCast());
			
			//Stdout.formatln("{}:  code buf length:  {}", i, buf.length);
			
			int sent = 0;
			int mod = 0;
			while (sent < buf.length) {
				mod = buf.length - sent;
				if (mod > 1499)
					mod = 1499;
					
				clientNIC.send_c(((cast(ubyte)'N') ~ buf[sent .. (sent + mod)]));
				
				sent += mod;
			}
			
			buf.length = 1;
			buf[0] = cast(ubyte)'E';
			clientNIC.send_c(buf);
			
			total += len[0];
			stat.display(total);
			
			//Stdout.formatln("{}:  DONE!", i);
			Stdout.formatln("=======================================");
		}
	}
	
	return 0;
}
