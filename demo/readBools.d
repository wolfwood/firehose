
module demo.ReadBools;

import tango.io.FileConduit;

import tango.io.Stdout;

void main(char[][] args){
	assert(args.length >= 2);

	FileConduit infile;

	infile = new FileConduit(args[1]);

	bool[] dat;

	dat.length = 1;

	while(infile.read(dat) == 1){
		Stdout.formatln(":{}", dat);
	}
}