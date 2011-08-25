// INSERT MAGIC

module lib.client.FirehoseClientManager;

import lib.Params;
import lib.SeqNum;
import lib.NetworkInterface;
import lib.FirehoseManager;
import lib.VirtualFrame;

import util.BitMap;

import tango.core.BitArray;
import tango.io.Stdout;

import lib.Packet;

import lib.Statistics;

import tango.io.FileConduit;

class FirehoseClientManager : FirehoseManager {

	Statistics _stat;

	ClientNetworkInterface _net;

	VirtualFrame _vf;

	FileConduit _data;

	this(Params params, ClientNetworkInterface net, Statistics stat){
		_stat = stat;

		_net = net;

		super(params);

		_vf = new VirtualFrame(_params); 

		_data = new FileConduit("stats/data", FileConduit.WriteCreate);
	}

	void astrobaseGo(){
		// init
		seqNum_t minFrame = 1;

		while(_vf.isData()){
			// --- RECEIVE ---
			ubyte[] pkt = _net.recv_c();

			//Stdout.formatln("len {}", pkt.length);

			Packet packet = new Packet(_params, pkt);

			// XXX: ntohl()
			seqNum_t foreignFrame = packet.getFrameNum();
			seqNum_t foreignAck   = packet.getAckNum();

			//XXX: maybe in not needed
			if(foreignFrame >= minFrame){

				// possibly rotate in new groups?
				if(foreignFrame > minFrame){
					
					//Stdout.formatln("client pre checkAck");

					_vf.checkAck(foreignFrame);

					//Stdout.formatln("client post checkAck");

					minFrame = foreignFrame;

					_vf.trim(minFrame);
				}// if frame shift
				

				//Stdout.formatln("q");
				
				// confirm guesses

				Packet ackpkt = _vf.checkGuess(packet);
				
				// build + buffer? ACK
				if(!(ackpkt is null)){

					_frameNum++;

					ackpkt.setFrameNum(_frameNum);

					// --- SEND ---
					_data.write(ackpkt.getPacket());

					_net.send_c(ackpkt.getPacket());

				}


			}// if(Frame)

			//Stdout.formatln("g");
		}// end while
		
		//Stdout.formatln("w");

		// send EOF

		_frameNum++;


		Packet fin = new Packet(_params, 64);

		fin.setFrameNum(_frameNum);
		fin.setAckNum(EOS);

		ulong filesize = _vf.getFileSize();

		fin.setPayload(filesize);

		_net.send_c(fin.getPacket());

		// wait for EOFack (or timeout?)
		

		_stat.display(filesize);
	}// astrobaseGo()

}// class
