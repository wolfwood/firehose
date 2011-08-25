// INSERT MAGIC

module lib.server.FirehoseServerManager;

import lib.Params;
import lib.FirehoseManager;

import util.BitMap;
import util.Converter;

import lib.NetworkInterface;

//import tango.io.Console;
import tango.io.FileConduit;

import util.Heap;

import lib.SeqNum;

import tango.core.Array;

import tango.core.BitArray;

import tango.io.Stdout;

//const FileConduit.Style fileStyle = {FileConduit.Access.Write, FileConduit.Open.Create};

import lib.Packet;

import lib.VirtualFrame;
import lib.Statistics;

class FirehoseServerManager : FirehoseManager{

	Statistics _stat;

	ServerNetworkInterface _net;

	VirtualFrame _vf;

	this(Params params, ServerNetworkInterface net, Statistics stat){
		_stat = stat;

		// deal with args
		_net = net;
		super(params);

		// init

		_vf = new VirtualFrame(_params);
	}

	void astrobaseGo(){
		// init stuff
		ulong filesize = 0;


		uint minAck = _ackNum;

		while(1){
			Packet guesspkt = _vf.getGuessPkt();

			// build guesses
			
			// XXX: htonl
			guesspkt.setFrameNum(_frameNum);
			guesspkt.setAckNum(_ackNum);

			_ackNum++;


			// --- SEND ---
			_net.send_s(guesspkt.getPacket());
			//Stdout.formatln("post send");

			/// check for ACK

			if(!_net.isEmpty()){
				//Stdout.formatln("not empty");

				// --- RECEIVE ---
				Packet ackpkt = new Packet(_params, _net.recv_s());


				// XXX: ntohl
				seqNum_t frameNum = ackpkt.getFrameNum();
				seqNum_t ackNum = ackpkt.getAckNum();

				// XXX: multi ack
				
				// if the client thinks we are done exit;
				if(ackNum == EOS){
					filesize = ackpkt.getPayload();

					break;
				}

				if(frameNum > _frameNum){
					_frameNum = frameNum;

					_vf.checkAck(ackNum, ackpkt.getBitArray());

					_vf.trim(ackNum);
				}else{
					// XXX out of sequence frameHandler
				}

			}else{
				//Stdout.formatln("empty");
			}

			//Stdout.formatln("post everything");
		}// while()

		//send E0Fack
		
		_vf.close(filesize);

		_stat.display(filesize);
	}
	

} // end class
