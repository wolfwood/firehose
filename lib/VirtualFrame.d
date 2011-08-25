// provides the data abstraction of Firehose

module lib.VirtualFrame;

import tango.core.BitArray;
import tango.core.Array;

import lib.Params;

import util.BitStream;

import util.BitGroupStream;

import lib.SeqNum;
import lib.Packet;

import tango.io.Stdout;

import lib.GuessModel;

// make bitgroup(array) obj?
// make packet obj


class VirtualFrame{
	Params _params;

	//alias _params.groupSize _groupSize;

	seqNum_t _minIdx; // a very classy fudge factor

	uint _bitsInGroup;

	bool _trimArrays, _inplaceReplacement;

	BitArray _bits;
	BitArray[] _oldBits;
	uint _numBits;


	uint[] _guessLoc;
	uint[][] _guessLocs;
	uint _currLoc;

	BitStream _bitstream;
	BitGroupStream _bgs;

	Packet _guesspkt;

	GuessTable _model;
	GuessTable[] _models;

	this(Params params){
//		_inplaceReplacement = true;
	
		_params = params;

		_minIdx = 1;

		_guessLoc = new uint[](_params.numGroups);

		_currLoc = 0;

		for(uint i = 0; i < _guessLoc.length; i++){
			_guessLoc[i] = _currLoc;
			_currLoc++;
		}


		_numBits = _params.numGroups * _params.groupSize;


		if(_params.isServer){

			_guesspkt = new Packet(_params, _numBits);

			_bits = _guesspkt.getBitArray();

			_bgs = new BitGroupStream(_params);


			_model = new GuessTable(_params);

			_models = new GuessTable[](_params.numGroups);

			for(uint i = 0; i < _models.length; i++){
				_models[i] = new GuessTable(_params, _model);
				_models[i].setNextGuess(_bits, i);
			}


		}else{
			_minIdx++;

			_bits.length(_numBits);

			_bitstream = new BitStream(_params.filename);

			uint i;

			for(i = 0; i < _numBits; i++){
				//Stdout.formatln("boo");
	
				bool flag = _bitstream.readAbit();
			
				if(_bitstream.EOF()){
					break;
				}

				_bits.opIndexAssign(flag,
														i);
			}

			if(i != _numBits){
				//Stdout.formatln("boo");
				_numBits = i;
			}

		}

		_trimArrays = true;
	}
	

	void shiftGroups(uint startIdx, uint endIdx, uint replaced){
		uint replacedBits = replaced * _params.groupSize;

		//Stdout.formatln("{} {} {} {}",startIdx,endIdx, replaced, _guessLoc.length);

		for(uint i = startIdx; i <= endIdx; i++){
			//Stdout.formatln("{} {} {} {} {}",i, replaced, _guessLoc.length,startIdx,endIdx);

			_guessLoc[i - replaced] = _guessLoc[i];

			if(_params.isServer){
				_models[i - replaced] = _models[i];
			}

			uint offset = i*_params.groupSize;

			for(uint j = 0; j < _params.groupSize; j++){
				_bits.opIndexAssign(_bits.opIndex(offset + j),
														offset + j - replacedBits);
			}
		}

	}

	void replaceGroups(uint replaced){
		if(_params.isServer){
			// get bits from guessModel

			for(uint i = (_models.length) - (replaced); i < (_models.length); i++){
				//_bits.opIndexAssign(false,
				//										i);

				_models[i] = new GuessTable(_params, _model); 

				_models[i].setNextGuess(_bits, i);
			}

		}else{
			// get bits from file
			uint replacedBits = replaced*_params.groupSize;

			if(_bitstream.EOF()){
				for(uint i = _numBits - (replacedBits); i < _numBits; i++){
					_bits.opIndexAssign(false, i);
				}

				if(replacedBits >= _numBits){
					_numBits = 0;
				}else{
					_numBits -= replacedBits;
				}
				
			}else{
				for(uint i = _numBits-(replacedBits); i < _numBits; i++){
					_bits.opIndexAssign(_bitstream.readAbit(),
															i);
					
					if(_bitstream.EOF()){
						_numBits -= (replacedBits - (_numBits - i));
						break;
					}
				}
			}
		}
		
		for(uint i = (_guessLoc.length) - replaced; i < _guessLoc.length; i++){
			_guessLoc[i] = _currLoc;
			_currLoc++;
		}
	}

	void replaceIdx(uint idx){
		_guessLoc[idx] = _currLoc;
		_currLoc++;

		if(_params.isServer){
			// get bits from guessModel
			
			_models[idx] = new GuessTable(_params, _model); 
			
			_models[idx].setNextGuess(_bits, idx);
		
		
		}else{
			uint offset = idx * _params.groupSize;
			
			// get bits from file
			
			if(_bitstream.EOF()){
				for(uint i = 0; i < _params.groupSize; i++){
					_bits.opIndexAssign(false, offset+i);
				}
				
				if(_params.groupSize >= _numBits){
					_numBits = 0;
				}else{
					_numBits -= _params.groupSize;
				}
				
			}else{
				for(uint i = 0; i < _params.groupSize; i++){
					_bits.opIndexAssign(_bitstream.readAbit(),
															offset + i);
					
					if(_bitstream.EOF()){
						// assume a full group is always read
						//_numBits ;
						assert( (i+1) == _params.groupSize);

						break;
					}
				}
			}
		}
	}
		


	Packet getGuessPkt(){
		assert(_params.isServer);

		// copy the packet, send the old one keep the new one
		Packet response = _guesspkt.makeCopy();

		//_guesspkt = response.makeCopy();


		// remember what we guessed and where it belongs
		_oldBits ~= response.getBitArray();

		//_bits = _guesspkt.getBitArray();

		assert(_bits.opCast().ptr != _oldBits[_oldBits.length -1].opCast().ptr);


		_guessLocs ~= _guessLoc.dup;

		//_guessLoc = _guessLoc.dup;

		assert(_guessLocs[_guessLocs.length -1].ptr != _guessLoc.ptr);

		//Stdout.format("<");
		//Stdout.flush();
		// increment gueses
		for(uint i = 0; i < _params.numGroups; i++){

			/*			uint offset = i * _params.groupSizae;
				for(uint k = 0; k < _params.groupSize; k++){
					if( _bits.opIndex(offset+k) ){
						_bits.opIndexAssign(false, offset+k);
					}else{
						_bits.opIndexAssign(true, offset+k);
						break;
					}
				}
				}*/

			bool outcome = _models[i].setNextGuess(_bits, i);

			if( !outcome ){
				_models[i] = new GuessTable(_params, _model);

				outcome = _models[i].setNextGuess(_bits, i);

				assert(outcome);
			}
		}
		//Stdout.format(">");
		//Stdout.flush();

		return response;
	}


	void checkAck(seqNum_t frameNum){
		assert(!_params.isServer);

		//Stdout.formatln("client checkAck");

		checkAck(frameNum, _oldBits[frameNum-_minIdx]);
	}

	void checkAck(seqNum_t ackNum, BitArray ack){
		uint replaced = 0;
		
		// move out acked groups
		uint oldIdx;
		
		/*Stdout.formatln("checkAck start {} {}\n{}\n{}", ackNum, _minIdx,
										_guessLocs[ackNum -_minIdx],
										_guessLoc);
		*/

		for(uint i = 0; i < ack.length(); i++){
			if(ack.opIndex(i)){
				// XXX: write guesses[i] to file!
				
				uint loc = _guessLocs[ackNum -_minIdx][i];
				
				
				// this is a test of whether we have already replaced this
				// group. the server is the only one with the _bgs class, the
				// client assumes a failed find inside the if means that this
				// is the case.

				if(!_params.isServer || _bgs.testBufferLoc(loc) == false){
					
					if(_params.isServer){
						_bgs.bufferGroup(loc, _oldBits[ackNum-_minIdx], i);

						_model.update(_oldBits[ackNum-_minIdx], i);
					}

					uint currIdx = _guessLoc.find(loc);
					
					//Stdout.formatln("{} {}", loc, guessLoc, guessLocs[]);
					
					if(!_params.isServer && currIdx == _guessLoc.length){
						// assume the group has already been replaced
						
					}else{
					
						if(_inplaceReplacement){
							replaceIdx(currIdx);

						}else{
							assert( currIdx < _params.numGroups);
							assert( currIdx <= i );

					
							if(replaced == 0){
								oldIdx = currIdx;
							}else{
								
								shiftGroups(oldIdx +1, currIdx -1, replaced);
								
							}
							
							oldIdx = currIdx;
						}

						replaced++;
					}
				}
			}else{
				if(_params.isServer){			
					_model.nack(_oldBits[ackNum-_minIdx], i);
				}
			}
		}

		if(_params.isServer){
			_model.learn();
		}

		//Stdout.formatln("checkAck doneish");

		if( !_inplaceReplacement && (replaced > 0) ){
		


			shiftGroups(oldIdx +1,  (_bits.length/_params.groupSize) -1, replaced);

			//Stdout.formatln("checkAck shifted");

			replaceGroups(replaced);
		}

		//Stdout.formatln("checkAck replaced");
	}		

	bool isData(){
		assert(!_params.isServer);

		if(_numBits == 0 && _bitstream.EOF()){
			return false;
		}else{
			return true;
		}
	}

	void close(ulong filesize){
		if(_params.isServer){
			_bgs.flushBuffer(filesize);
		}else{
			
		}
	}

	ulong getFileSize(){
		return _bitstream.filesize();
	}

	Packet checkGuess(Packet pkt){
		assert(!_params.isServer);

		BitArray guesses = pkt.getBitArray();
		
		uint guessBits = guesses.length();

		if(guessBits > _numBits && !_inplaceReplacement){
			guessBits = _numBits;
		}
		
		uint numGuesses = guessBits / _params.groupSize;
		
		Packet ackpkt = new Packet(_params, numGuesses, true);
		BitArray ack  = ackpkt.getBitArray();
		
		uint acked = 0;
		uint maxIdx = 0;
		
		for(uint i = 0; i < numGuesses; i++){
			bool flag = true;
			
			uint offset = i * _params.groupSize;
			
			for(uint k = 0; k < _params.groupSize; k++){
				if( _bits.opIndex(offset +k) != guesses.opIndex(offset +k) ){
					flag = false;
					break;
				}
			}// inner for
			
			if(flag){
				maxIdx = i;

				acked++;
				ack.opIndexAssign(true, i);
			}
			
		}// outer for

		if(acked > 0){
			ackpkt.setAckNum(pkt.getAckNum());

			_oldBits ~= ack;

			_guessLocs ~= _guessLoc.dup;

			//_guessLoc = _guessLoc.dup;

			assert(_guessLocs[_guessLocs.length -1].ptr != _guessLoc.ptr);

			ackpkt.setNumBits(maxIdx);

			return ackpkt;
		}else{
			return null;
		}
	}

	void trim(seqNum_t idx){
		if(!_trimArrays){
			return;
		}

		if(_minIdx < idx){
			seqNum_t offset = idx - _minIdx;
			_oldBits = _oldBits[offset..$];
			_guessLocs = _guessLocs[offset..$];
			
			_minIdx = idx;
		}
	}
} // end class
