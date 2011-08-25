// 

module util.Converter;




ubyte[] bool2dArray2ubyteArray(bool[][] bits){
	ubyte[] data;

	//data.size = (bits.length*bits[0].length)/8;

	uint numBits;
	ubyte buffer[1];

	for(uint i = 0; i < bits.length; i++){
		for(uint k = 0; k < bits[i].length; k++){
			if(numBits == 8){
				data ~= buffer.dup;
				buffer[0] = 0;
				numBits = 0;
			}

			if(bits[i][k]){
				buffer[0] |= 1 << numBits;
			}
		}
	}

	if(numBits != 0){
		data ~= buffer;
	}

	return data;
}

void bool2dArray2ubyteArray(bool[][] bits, ubyte[] data){	

	//data.size = (bits.length*bits[0].length)/8;

	uint numBits;
	ubyte buffer;

	uint q = 0;

	for(uint i = 0; i < bits.length; i++){
		for(uint k = 0; k < bits[i].length; k++){
			if(numBits == 8){
				data[q] = buffer;
				q++;

				buffer = 0;
				numBits = 0;
			}

			if(bits[i][k]){
				buffer |= 1 << numBits;
			}
		}
	}

	if(numBits != 0){
		buffer <<= (8 - numBits);
		data[q] = buffer;
	}
}