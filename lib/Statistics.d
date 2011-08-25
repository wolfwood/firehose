module lib.Statistics;

import tango.io.Stdout;

class Statistics{
	ulong pktsTx, pktsRx;
	ulong bytesTx, bytesRx;

	uint[7] ackStyle;

	ulong _ackBits;
	ulong _ackBitsRounded;

	bool _ack;

	void recvSize(uint size){
		pktsRx++;
		bytesRx += size;
	}

	void sendSize(uint size){
		pktsTx++;
		bytesTx += size;
	}

	void display(ulong filesize){
		Stdout.formatln("Packets Tx:{}  Rx:{}", pktsTx, pktsRx);


		ulong ipOverhead = 20;

		ipOverhead *= pktsTx;

		Stdout.formatln("\nBytes Tx:{}  Rx:{}  file: {}", ipOverhead + bytesTx, bytesRx, filesize);


		Stdout.formatln("\nOn Average {} bits Tx per bit", ratioOf(ipOverhead + bytesTx, filesize));
		Stdout.formatln("On Average {} bits Rx per bit", ratioOf(bytesRx, filesize));

		Stdout.formatln("\nn Average {} bits IP overhead Tx per bit", ratioOf(ipOverhead, bytesTx) );

		ipOverhead = 20;

		ipOverhead *= pktsRx;

		Stdout.formatln("On Average {} bits IP overhead Rx per bit", ratioOf(ipOverhead, bytesRx) );


		if(_ack){

			ipOverhead = pktsTx*(8*28);

			Stdout.formatln("\nOn Average {} recoded ACK bits Tx per bit\n", ratioOf((ipOverhead+_ackBits), (filesize*8)));

			Stdout.formatln("\nOn Average {} recoded ACK bits (packet word aligned) Tx per bit\n", ratioOf((ipOverhead+_ackBitsRounded), (filesize*8)));

			for(uint i = 0; i < ackStyle.length; i++){
				Stdout.formatln("Ack style {} wins {} times", i, ackStyle[i]);
			}
		}

	}

	void applyProps(ulong bits, uint who){
		_ack = true;

		
		_ackBits += bits;


		if((bits % 32) != 0){
			bits += (32 - (bits % 32));
		}

		_ackBitsRounded += bits;

		ackStyle[who]++;
	}

	static double ratioOf(ulong a, ulong b){
		return ( (cast(double)a) / (cast(double)b));
	}

		
}