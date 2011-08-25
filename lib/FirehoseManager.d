// that which runs the show, man behind curtain, etc...

module lib.FirehoseManager;

import lib.Params;

import lib.SeqNum;

class FirehoseManager{
protected:
	Params _params;

	const seqNum_t EOS = 0xFFFFFFFF;

	const uint _groupSize = 4;
	const uint _protocolOverhead;
	const uint _numGroups;

	seqNum_t _ackNum = 1, _frameNum = 1;//, _counterAck = 0, _counterFrame = 0;


public:
	this(Params params){
		_params = params;

		_protocolOverhead = seqNum_t.sizeof * 2; //(1 + _groupSize);

		_numGroups = ((_params.MTU - _params.ipOverhead - _protocolOverhead) 
									* 8) / _groupSize;

		// make sure it ends on a byte boundary
		assert(_numGroups * _groupSize % 8 == 0);


		// make sure it ends on a word (uint) boundary
		assert(_numGroups * _groupSize % 32 == 0);

		
		_params.groupSize = _groupSize;
		_params.numGroups = _numGroups;
		_params.protocolOverhead = _protocolOverhead;
	}


	void astrobaseGo(){};

}