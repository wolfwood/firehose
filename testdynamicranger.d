module testdynamicranger;

import tango.io.FileConduit;
import tango.io.protocol.Reader;
import tango.io.Stdout;
import tango.core.BitArray;

import lib.Params;
import util.DynamicRangeEncoder;

int main(char[][] args) {
	Params params;
	params.groupSize = 8;
	params.filename = "in3";
	BitArray code;
	uint[] counts;
	uint len;
	
	counts.length = (1 << params.groupSize);
	for (int i = 0; i < (1 << params.groupSize); i++) {
		counts[i] = 1;
	}
	
	auto encoder = new dynamicranger(params, counts);
	params.isServer = false;
	auto decoder = new dynamicranger(params, counts);
	
	//for (int i = 0; i < 20; i++) {
	code = encoder.encode(len);
	//	Stdout.formatln("\nrun{}:  databits:  {}; bits:  {};\n", i, (len*8), code.length());  

	FileConduit codefile = new FileConduit(params.filename ~ ".dynr", 
																				 FileConduit.WriteCreate);

	codefile.write(cast(ubyte[])(code.opCast())[0..(code.dim*4)]);

	decoder.decode(code, len);
	//}
	
	return 0;
}
