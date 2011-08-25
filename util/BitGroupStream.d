/* write fixed size bitGroups, reordering and buffering them until we
	 are writing the appropriate region in the file */

module util.bitGroupStream;

import tango.core.BitArray;
import tango.io.FileConduit;

import lib.Params;


class BitGroupStream{

	FileConduit _file;

	Params _params;

	//alias _params.groupSize _groupSize;

	uint _nextWrite;

	BitArray[] _fileData;
	BitArray[] _fileAcks;
	uint[] _fileCount;

	bool _writeflag;

	this(Params params){
		// store args
		_params = params;

		// initialize
		_writeflag = false;
		_nextWrite = 0;

		_file = new FileConduit(_params.filename, FileConduit.WriteCreate);
	}

	void bufferGroup(uint loc, BitArray groups, uint idx){
		uint entry = loc / _params.numGroups;
		uint offset = loc % _params.numGroups;
		
		_writeflag = true;
		
		// check size and grow arrays
		if(entry >= _fileData.length){
			_fileData.length = (entry +1);
			_fileAcks.length = (entry +1);
			_fileCount.length = (entry+1);
		}
		
		if(_fileData[entry].length == 0){
			_fileData[entry].length(_params.numGroups * _params.groupSize);
			_fileAcks[entry].length(_params.numGroups);
		}
		
		
		assert(_fileAcks[entry].opIndex(offset) == false);
		
		//  record existence of group in timeline
		_fileAcks[entry].opIndexAssign(true, offset);
		_fileCount[entry]++;

		// save acked guess
		for(uint i = 0; i < _params.groupSize; i++){
			_fileData[entry].opIndexAssign(groups.opIndex((idx*_params.groupSize) + i), 
																		 (offset*_params.groupSize) + i);
		}

		// if we have a full set, flush
		if(entry == _nextWrite){
			while(_nextWrite < _fileCount.length && 
						_fileCount[_nextWrite] == _params.numGroups){
				uint len = _fileData[_nextWrite].length() / 8;

				if( _fileData[_nextWrite].length() > len * 8){
				    	//assert(false);
					len++;
				}

				_file.write( cast(ubyte[])(_fileData[_nextWrite].opCast())[0..len]);
				_nextWrite++;
			}
		}
	}


	bool testBufferLoc(uint loc){
		uint entry = loc / _params.numGroups;
		uint offset = loc % _params.numGroups;
		
		if(_writeflag){
			if(_fileAcks.length > entry && _fileAcks[entry].length() > offset ){
				
				return _fileAcks[entry].opIndex(offset);
			}
		}
		
		return false;
	}


	void flushBuffer(ulong filesize = 0){
		uint i;
		
		if(_writeflag){
			if((_fileData.length - _nextWrite) > 1){
				for(; _nextWrite < (_fileData.length) -1;){
					uint len = _fileData[_nextWrite].length() / 8;

					if( _fileData[_nextWrite].length() > (len * 8) ){
						//assert(false);
						len++;
					}

					_file.write(cast(ubyte[])(_fileData[_nextWrite].opCast())[0..len]);
					_nextWrite++;
				}
			}
			
			//uint idx = _nextWrite;
			uint stop = _fileAcks[$-1].length();
			stop--;
			for(; stop > 0; stop--){
				if(_fileAcks[$-1].opIndex(stop)){
					break;
				}
			}
			
			stop++;

			uint len = (stop * _params.groupSize) / 8;

			if(stop > (len * 8)){
				len++;
			}

			_file.write(cast(ubyte[])(_fileData[$-1].opCast())[0..len]);
		}
		
		if(filesize != 0){
			_file.seek(filesize);
			_file.truncate();
		}

		_file.close();
	}

}// end of class
