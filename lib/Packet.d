module util.Packet;

import lib.Params;
import lib.SeqNum;

import tango.core.BitArray;

import tango.io.Stdout;

import tango.net.Socket;


class Packet{
	bool _isAck;

	Params _params;

	ubyte[] _packet, _hdr, _data;

	ulong[] _payload;

	seqNum_t[] _Hdr;

	BitArray _ba;

	uint _bits;


	this(Params params, bool isAck = false){
		this(params, params.numGroups*params.groupSize, isAck);
	}

	this(Params params, uint bits,  bool isAck = false){
		uint bytes = bits / 8;

		//Stdout.formatln("bb {} {}", bits, bytes);

		if(bytes * 8 < bits){
			bytes++;
		}

		//Stdout.formatln("bb {} {}", bits, bytes);

		if((bytes & 3) != 0){
			bytes += 4 - (bytes & 3);
		}

		//Stdout.formatln("bb {} {}", bits, bytes);

		ubyte[] packet = new ubyte[](params.protocolOverhead + bytes);

		this(params, bits, packet, isAck);
	}

	this(Params params, ubyte[] packet,  bool isAck = false){

		//Stdout.formatln("{} {} {}", packet.length, params.protocolOverhead, packet);

		uint bits = (packet.length) - params.protocolOverhead;

		bits = bits * 8;

		this(params, bits, packet, isAck);
	}

	this(Params params, uint bits, ubyte[] packet, bool isAck = false){
		_isAck = isAck;

		_params = params;

		_bits = bits;

		_packet = packet;

		_hdr = _packet[0.._params.protocolOverhead];

		_data = _packet[_params.protocolOverhead..$];

		_Hdr = cast(seqNum_t[])_hdr;

		//Stdout.formatln("{} {}", _data.length, bits);

		_ba.init(_data, bits);

		//	Stdout.formatln("{} {}", _data.length, bits);
	}

	Packet makeCopy(){
		ubyte[] copy = _packet.dup;

		return new Packet(_params, _bits, copy);
	}

	ubyte[] getPacket(){
		uint bytes = _bits / 8;

		//Stdout.formatln("bb {} {}", bits, bytes);

		if(bytes * 8 < _bits){
			bytes++;
		}

		// can't remove this, 'third' byte ia first one trimmed?
		if((bytes & 3) != 0){
			bytes += 4 - (bytes & 3);
		}
		

		if(_isAck){
			//recodeAck();
		}

		if( (bytes + _params.protocolOverhead) < _packet.length){
			return _packet[0..(bytes + _params.protocolOverhead)];
		}else{
			return _packet;
		}
	}

	
	BitArray getBitArray(){
		return _ba;
	}
		// XXX: htonl()
	seqNum_t getFrameNum(){
		return cast(seqNum_t)ntohl(_Hdr[0]);
	}
		// XXX: htonl()
	seqNum_t getAckNum(){
		return cast(seqNum_t)ntohl(_Hdr[1]);
	}

	void setFrameNum(seqNum_t frameNum){
		_Hdr[0] = cast(seqNum_t)htonl(frameNum);
	}

	void setAckNum(seqNum_t ackNum){
		_Hdr[1] = cast(seqNum_t)htonl(ackNum);
	}


	void setPayload(ulong pay){
		_payload = cast(ulong[])_data[0..8]; 
		_payload[0] = cast(seqNum_t)htonl(pay);
	}

	ulong getPayload(){
		// XXX: htonl()
		_payload = cast(ulong[])_data[0..8]; 
		return cast(seqNum_t)ntohl(_payload[0]);
	}

	void setNumBits(uint bits){
		//

		if(_isAck){
			recodeAck();
			_isAck = false;
		}//else{
			//}
		_bits = bits;
	}

	void recodeAck(){
		uint nackTrim, ackTrim;

		uint limit = _bits;

		//nackTrim = ackTrim = _ba.length() +1;

		//		assert(_ba.length() >= _params.groupSize);

		bool firstBit = _ba[0];
		uint i;

		for(i = 1; i < limit; i++){
			if(_ba[i] != firstBit){
				break;
			}
		}

		if(firstBit){
			nackTrim = i;
		}else{
			ackTrim = i;
		}

		BitArray revBits = _ba.dup();

		revBits = revBits.reverse();
		
		firstBit = revBits[0];

		for(i = 1; i < limit; i++){
			if(revBits[i] != firstBit){
				break;
			}
		}
		
		if(firstBit){
			if(nackTrim < i){
				nackTrim = i;
			}
		}else{
			if(ackTrim < i){
				ackTrim = i;
			}
		}

		nackTrim = limit - nackTrim;
		ackTrim  = limit - ackTrim;

		uint idxCode, nidxCode;

		for(i = 0; i < limit; i++){
			if(_ba[i]){
				idxCode++;
			}else{
				nidxCode++;
			}
		}

		uint idxSize  = bitsToStoreAlphabetOf(ackTrim);
		uint nidxSize = bitsToStoreAlphabetOf(nackTrim);

		uint numRuns, maxRunLen, runLen, nrunLen;
		uint numNruns, maxNrunLen;


		bool isRun, isNrun;

		for(i = 0; i < limit; i++){
			if(_ba[i]){

				if(!isRun){

					numRuns++;

					isRun = true;

					//assert(isNrun);

					if(nrunLen > maxNrunLen){
						maxNrunLen = nrunLen;
					}
					nrunLen = 0;
					
					isNrun = false;
				}

				runLen++;

			}else{
				
				if(!isNrun){

					numNruns++;

					isNrun = true;

					//assert(isRun);

					if(runLen > maxRunLen){
						maxRunLen = runLen;
					}
					runLen = 0;
					
					isRun = false;
				}

				nrunLen++;
			}
		}
		
		if(isRun){
			if(runLen > maxRunLen){
				maxRunLen = runLen;
			}

		}else if(isNrun){
			if(nrunLen > maxNrunLen){
				maxNrunLen = nrunLen;
			}
		}

		uint runIdxSize  = bitsToStoreAlphabetOf(maxRunLen);
		uint nrunIdxSize = bitsToStoreAlphabetOf(maxNrunLen);

 
		uint ackOverhead = 3;
		uint overhead = ackOverhead;

		uint minBits = _bits + ackOverhead;
		uint minIdx = 0;

		if(minBits > (ackTrim + overhead)){
			minBits = ackTrim + overhead;
			minIdx = 1;
		}

		if(minBits > (nackTrim + overhead)){
			minBits = nackTrim + overhead;
			minIdx = 2;
		}
		
		overhead = _params.groupSize + ackOverhead;
		
		if(minBits > ((idxCode * idxSize) + overhead) ){
			minBits = (idxCode * idxSize) + overhead;
			minIdx = 3;
		}

		
		if(minBits > ((nidxCode * nidxSize) + overhead) ){
			minBits = (nidxCode * nidxSize) + overhead;
			minIdx = 4;
		}

		overhead = (2*_params.groupSize) + ackOverhead;
		
		if(minBits > ((numRuns * (idxSize + runIdxSize)) + overhead) ){
			minBits = (numRuns * (idxSize + runIdxSize)) + overhead;
			minIdx = 5;
		}
		
		
		if(minBits > ((numNruns * (nidxSize + nrunIdxSize)) +overhead) ){
			minBits = (numNruns * (nidxSize + nrunIdxSize)) + overhead;
			minIdx = 6;
		}
		
		_params.stats.applyProps(minBits, minIdx);
	}

	uint bitsToStoreAlphabetOf(uint numSymbols){
		uint size = 0;

		while( (1 << size) < numSymbols){
			size++;
		}
	
		return size;
	}
} // end class