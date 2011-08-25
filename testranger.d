module testranger;

import tango.io.FileConduit;
import tango.io.protocol.Reader;
import tango.io.Stdout;
import tango.core.BitArray;

import lib.Params;
import util.RangeEncoder;

int main(char[][] args) {
	Params params;
	params.groupSize = 8;
	params.filename = "in3";
	BitArray code;
	uint[] counts;
	uint len;
	auto encoder = new ranger(params);
	params.isServer = false;
	auto decoder = new ranger(params);
	
	code = encoder.encode(counts, len);

	//Stdout.formatln("\ncode: found, databits:  {}; bits:  {};\n", (len*8), code.length());  

	FileConduit codefile = new FileConduit(params.filename ~ ".range", 
																				 FileConduit.WriteCreate);

	codefile.write(cast(ubyte[])(code.opCast())[0..(code.dim*4)]);

	decoder.decode(code, counts, len);
	
	return 0;
}
