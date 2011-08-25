module demo.readBits;

import tango.io.FileConduit;
import tango.io.Stdout;

import util.BitStream;


int main(char[][] args){
	ubyte[1] buffer;

	FileConduit file = new FileConduit(args[1]);

	while(true){
		if(file.read(buffer) != 1){
			break;
		}

		Stdout.formatln("{}", buffer[0]);
	}	

	BitStream bs = new BitStream(args[1]);

	while(!bs.EOF()){
		Stdout.formatln("{}", bs.readAbit());
	}

	return 0;
}