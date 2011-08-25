// this should work like FTP

module lib.client.DummyClientManager;

import lib.Params;
import lib.FirehoseManager;

import lib.NetworkInterface;
import lib.SeqNum;


import tango.io.FileConduit;

import tango.core.Array;

import tango.io.Stdout;


class DummyClientManager :FirehoseManager{


 private:

	FileConduit _infile;
	ClientNetworkInterface _net;


 public:

	this(Params params, ClientNetworkInterface net){
		_net = net;

		params.protocolOverhead = 4;

		super(params);


		_infile = new FileConduit(_params.filename, FileConduit.ReadExisting);
	}

	void astrobaseGo(){
		seqNum_t seq = 1;


		while( 1 ){

			uint pktsize = (_params.MTU - _params.ipOverhead);


			ubyte[] pkt = new ubyte[](pktsize);

			seqNum_t[] pkthdr = cast(seqNum_t[])pkt[0.._params.protocolOverhead];
			
			ubyte[] pktdata = pkt[_params.protocolOverhead..$];
			
			uint bytes = _infile.read(pktdata);
			
			if(seq == EOS){
				seq = 0;
			}
			
			
			if(bytes < (pktsize - pkthdr.length*pkthdr[0].sizeof) ){
				seq = EOS;
			}
			
			pkthdr[0] = seq;
			
			pkt.length = pkthdr.length*pkthdr[0].sizeof + bytes;
			
			_net.send_c(pkt);
			
			if(seq == EOS){
				break;
			}
			
			seq++;
		}// end while()
		
		
		Stdout.formatln("End Of Client");
	}
	
}

