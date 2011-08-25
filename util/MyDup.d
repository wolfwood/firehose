//

module util.MyDup;

import tango.core.BitArray;

import tango.io.Stdout;

BitArray myDupBitArray(BitArray ba){

	Stdout.formatln("fail");
	//uint[] data = cast(uint[])(ba.opCast()[0..ba.dim]);
	ubyte[] data = cast(ubyte[])ba.opCast()[0..(ba.dim * uint.sizeof)];
	Stdout.formatln("win");

	ubyte[] data2 = data.dup;

	assert(data.ptr != data2.ptr);

	BitArray ba2;

	ba2.init(data2, ba.length);

	Stdout.formatln("win");

	return ba2;
}