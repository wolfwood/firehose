module util.BitStream;

import tango.io.FileConduit;
import tango.io.Stdout;

class BitStream{
	FileConduit _file;

	ubyte[1] _buffer;
	
	ubyte _numBits;

	bool _EOF;
	
	this(char[] filename, bool writer=false){
		if (writer)
			_file = new FileConduit(filename, FileConduit.WriteCreate);
		else
			_file = new FileConduit(filename);

		_numBits = 0;
		_buffer[0] = 0;
	}

	bool EOF(){
		if( (_numBits == 0) && _EOF){
			return true;
		}else{
			return false;
		}
	}

	bool readAbit(){
		if(EOF()){
			return false;
		}else{
			if(_numBits == 0){
				/*if(_file.position() >= _file.length()){
					_EOF = true;
					return false;					
					}*/


				uint bytes = _file.read(_buffer);
				
				if(bytes != 1){
					_EOF = true;
					return false;
				}		

				_numBits = 8;
			}

			/*
			_numBits--;

			return ( (1 << _numBits) & _buffer[0] ) != 0;
			*/
			
			bool val = (_buffer[0] & 1) == 1;

			_numBits--;
			_buffer[0] >>= 1;

			return val;

		}
		
	}
	
	void writeAbit(bool newBit){
		// if were writing a 1, add it to the appropriate place in the buffer
		if (newBit)
			_buffer[0] |= (1 << _numBits);
		
		// we either wrote a bit (either 1 or the inherent 0
		_numBits++;
		
		// filled the buffer, so write out and zero
		if (_numBits > 7) {
			_file.write(_buffer);
			_buffer[0] = 0;
			_numBits = 0;
		}
	}

	ulong filesize(){
		return _file.length();
	}
	
	void reset() {
		_file.seek(0);
	}
	
	void close() {
		_file.close();
	}
} // end classs
