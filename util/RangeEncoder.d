module util.RangeEncoder;

import tango.io.FileConduit;
import tango.io.protocol.Reader;
import tango.io.Stdout;
import tango.core.BitArray;

import lib.Params;

uint uint_size = 32;

class ranger {
	protected:
	ubyte[1] mahbyte;
	int num_symbols;
	int groupsize;
	char[] filename;
	
	public:
	this(Params params) {
		params = params;
		groupsize = params.groupSize;
		num_symbols = 1 << groupsize;
		filename = params.filename.dup;
	}
	
	BitArray encode(out uint[] counts, out uint len) {
		bool found;
		double[] percents;
		double[] cdfs;
		ubyte[] curkeys;
		uint low = 0, high = (1 << (32-1));
		//XXX: new codes
		uint xor, cmp, shift, shared;
		BitArray code;
		uint   lo,    hi;
		double lorem, hirem;
		uint total;
		int bytesread;
		FileConduit filebuf = new FileConduit(filename, FileConduit.ReadExisting);
		
		len = filebuf.length;
		counts.length = num_symbols;
		percents.length = num_symbols;
		cdfs.length = num_symbols;
		
		total = 0;
		for( uint i = 0; i < len; i++) {
			bytesread = filebuf.read(mahbyte);
			counts[mahbyte[0]] += 1;
			total++;
		}
		
		double cdf = 0.0;
		for( uint i = 0; i < num_symbols; i++) {
			percents[i] = cast(double)counts[i]/cast(double)total;
			cdfs[i] = cdf;
			cdf += percents[i];
			/*if (percents[i] > 0){
				Stdout.formatln("cdf:  {}; percent:  {}", cdfs[i], percents[i]);
			}*/
		}
		
		// reread file
		filebuf.seek(0);
		uint oldsize;
		for( uint i = 0; i < len; i++) {
			bytesread = filebuf.read(mahbyte);
			if (bytesread == 1) {
				oldsize = high - low;
				lorem = cdfs[mahbyte[0]] * oldsize;
				hirem = percents[mahbyte[0]] * oldsize;
				lo = cast(uint)lorem;
				hi = cast(uint)hirem;
				lorem -= lo;
				hirem -= hi;
				low += lo;
				high = low + hi;
				
				//Stdout.formatln("j:  {}", mahbyte[0]);
				//Stdout.formatln("\ncdf:  {}; pec:  {}", cdfs[mahbyte[0]], percents[mahbyte[0]]);
				//Stdout.formatln("range:  {}; lo:  {}; hi:  {};", oldsize, lo, hi);
				
				//XXX: new codes!
				xor = ~(low ^ high);
				//Stdout.formatln("xor:  {}", xor);
				shift = (uint_size - 1);
				cmp = 1 << shift;
				shared = 0;
				while ((xor & cmp) > 0) {
					//Stdout.formatln("all look same! shifting!, cmp:  {}", cmp);
					code.opCatAssign((cmp & low) > 0);
					shift--;
					cmp = 1 << shift;
					shared++;
				}
				
				//Stdout.formatln("PRESHIFT j:  {}; low:  {}; high:  {}", mahbyte[0], low, high);
				
				if (shared > 0) {
					high = high << shared;
					low  = low  << shared;
					
					uint hiremi = cast(uint)(hirem * 10 * shared);
					uint loremi = cast(uint)(lorem * 10 * shared);
					
					// shift in remainders for hi
					int nushift = uint_size - 1;
					int nucmp = 1 << nushift;
					while (((nucmp & hiremi) == 0) && (nushift >= 0)) {
						nushift--;
						nucmp = 1 << nushift;
					}
					for (int k = (shared - 1); ((k >= 0) && (nushift >= 0)); k--) {
						if ((nucmp & hiremi) > 0)
							high |= (1 << k);
					}
					
					// shift in remainders for lo
					nushift = uint_size - 1;
					nucmp = 1 << nushift;
					while (((nucmp & loremi) == 0) && (nushift >= 0)) {
						nushift--;
						nucmp = 1 << nushift;
					}
					for (int k = (shared - 1); ((k >= 0) && (nushift >= 0)); k--) {
						if ((nucmp & loremi) > 0)
							low |= (1 << k);
					}
				}
				//Stdout.formatln("j:  {}; low:  {}; high:  {}", mahbyte[0], low, high);
			}
			else {
				Stdout.formatln("EOF, nigga");
			}
		}
		if (low >= high)
			Stdout.formatln("OH NOES~! low >= high");
			
		Stdout.formatln("almost out!");
		low += 1;
		for (int i = (uint_size - 1); i >= 0; i--) {
			//Stdout.formatln("filling buf, {}", i);			
			cmp = 1 << i;
			code.opCatAssign((low & cmp) > 0);
		}
		Stdout.formatln("enclen:  {}", len);
		
		filebuf.close();
		
		return code;
	}

	void decode(BitArray bitcode, uint[] counts, uint len) {
		double[] percents;
		double[] cdfs;
		uint low = 0, high = (1 << (32-1));
		//XXX: new codes
		uint xor, cmp, shift, shared;
		uint bitIndex;
		uint   lo,    hi;
		double lorem, hirem;
		uint total;
		FileConduit filebuf = new FileConduit((filename ~ ".out"), FileConduit.WriteCreate);
		
		uint code = 0;
		bitIndex = 0;
		for (int i = (uint_size - 1); i >= 0; i--) {
			if (bitcode.opIndex(bitIndex))
				code |= (1 << i);
			bitIndex++;
		}
		
		Stdout.formatln("declen:  {}", len);
		
		counts.length = num_symbols;
		percents.length = num_symbols;
		cdfs.length = num_symbols;
		
		total = 0;
		for (uint i = 0; i < num_symbols; i++) {
			total += counts[i];
		}
		
		double cdf = 0.0;
		for( uint i = 0; i < num_symbols; i++) {
			percents[i] = cast(double)counts[i]/cast(double)total;
			cdfs[i] = cdf;
			cdf += percents[i];
			
			/*if (percents[i] > 0){
				Stdout.formatln("{}:  cdf:  {}; percent:  {}", i, cdfs[i], percents[i]);
			}*/
		}
		
		//Stdout.formatln("low:  {}; high:  {}", low, high);
		
		uint j, oldsize;
		for( uint i = 0; i < len; i++) {
			oldsize = high - low;
			j = 0;
			while((counts[j] == 0) || (code >= (low + (cast(uint)(cdfs[j] * oldsize) + cast(uint)(percents[j] * oldsize))))) {
				//Stdout.formatln("=============================================");
				//Stdout.formatln("low:  {}; high:  {}; oldsize:  {}", low, high, oldsize);
				//Stdout.formatln("code:  {}; cap:  {}", code, ((cdfs[j] * oldsize) + (percents[j] * oldsize)));
				j++;
			}
			//Stdout.formatln("==code:  {}; j:  {}; ub[j]:  {};", code, j, (low + ((cdfs[j] * oldsize) + (percents[j] * oldsize))));
			//Stdout.formatln("=============================================");
			//Stdout.formatln("low:  {}; high:  {}; oldsize:  {}", low, high, oldsize);
			//Stdout.formatln("code:  {}; cap:  {}", code, ((cdfs[j] * oldsize) + (percents[j] * oldsize)));
			
			lorem = cdfs[j] * oldsize;
			hirem = percents[j] * oldsize;
			lo = cast(uint)lorem;
			hi = cast(uint)hirem;
			lorem -= lo;
			hirem -= hi;
			low += lo;
			high = low + hi;

			//Stdout.formatln("j:  {}", j);			
			//Stdout.formatln("\ncdf:  {}; pec:  {}", cdfs[j], percents[j]);
			//Stdout.formatln("range:  {}; lo:  {}; hi:  {};", oldsize, lo, hi);
			//Stdout.formatln("PRESHIFT j:  {}; low:  {}; high:  {}; code:  {}", j, low, high, code);
			
			//XXX: new codes!
			xor = ~(low ^ high);
			shift = (uint_size - 1);
			cmp = 1 << shift;
			shared = 0;
			while (((xor & cmp) > 0) && (bitIndex < bitcode.length())) {
				shift--;
				cmp = 1 << shift;
				shared++;
				
				//XXX: brand neu!
				code = code << 1;
				//Stdout.format("accessing bit array, i:  {}; bitIndex:  {}; bitcode.length():  {};...", i, bitIndex, bitcode.length());
				//Stdout.flush();
				if (bitcode.opIndex(bitIndex))
					code |= 1;
				//Stdout.formatln("done!");
				bitIndex++;
			}
			
			if (shared > 0) {
				high = high << shared;
				low  = low  << shared;
				
				uint hiremi = cast(uint)(hirem * 10 * shared);
				uint loremi = cast(uint)(lorem * 10 * shared);
				
				// shift in remainders for hi
				int nushift = uint_size - 1;
				int nucmp = 1 << nushift;
				while (((nucmp & hiremi) == 0) && (nushift >= 0)) {
					nushift--;
					nucmp = 1 << nushift;
				}
				for (int k = (shared - 1); ((k >= 0) && (nushift >= 0)); k--) {
					if ((nucmp & hiremi) > 0)
						high |= (1 << k);
				}
				
				// shift in remainders for lo
				nushift = uint_size - 1;
				nucmp = 1 << nushift;
				while (((nucmp & loremi) == 0) && (nushift >= 0)) {
					nushift--;
					nucmp = 1 << nushift;
				}
				for (int k = (shared - 1); ((k >= 0) && (nushift >= 0)); k--) {
					if ((nucmp & loremi) > 0)
						low |= (1 << k);
				}
			}
			
			mahbyte[0] = j;
			filebuf.write(mahbyte);
			//Stdout.formatln("j:  {}; low:  {}; high:  {}", j, low, high);
		}
		
		filebuf.close();
	}
}
