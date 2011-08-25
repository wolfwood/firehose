// this should work like FTP

module lib.server.DummyServerManager;

import lib.Params;
import lib.FirehoseManager;

import lib.NetworkInterface;

import tango.io.FileConduit;

import tango.core.Array;

import tango.io.Stdout;

class DummyServerManager :FirehoseManager{

 private:

	FileConduit _outfile;
	ServerNetworkInterface _net;


 public:

	this(Params params, ServerNetworkInterface net){
		_net = net;

		params.protocolOverhead = 4;

		super(params);

		_outfile = new FileConduit(_params.filename, FileConduit.ReadWriteCreate);
	}

	void astrobaseGo(){

		while( 1 ){

			ubyte[] pkt = _net.recv_s();

			uint[] pkthdr = cast(uint[])pkt[0.._params.protocolOverhead];



			if(pkt.length > _params.protocolOverhead){

				ubyte[] pktdata = pkt[_params.protocolOverhead..$];

				_outfile.write(pktdata);
			}


			if(pkthdr[0] == EOS){
				break;
			}

		}// end while()
		

		_outfile.close();

		Stdout.formatln("End Of Server");
	}


}

