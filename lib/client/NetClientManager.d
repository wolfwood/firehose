// APPLYING MAGIC!

module lib.client.NetClientManager;

import lib.Params;
import lib.NetworkInterface;
import tango.net.Socket;
import tango.io.Stdout;

import lib.Statistics;

class NetClient : ClientNetworkInterface{
	protected Socket sendr, recvr;
	protected Address target;
	
	public Statistics stat;

	public this(Address _target, Statistics dastat) {
		stat = dastat;

		sendr = new Socket(AddressFamily.INET, SocketType.RAW, cast(ProtocolType)253);
		recvr = new Socket(AddressFamily.INET, SocketType.RAW, cast(ProtocolType)254);
		recvr.bind(new IPv4Address(IPv4Address.ADDR_ANY, IPv4Address.PORT_ANY));
		target = _target;
	}
	
	public void send_c(ubyte[] data) {
		int		sent;
		
		sent = sendr.sendTo(data, target);
		if (sent == -1)
			Stdout.formatln("CLIENT:  SEND FAIL!");

		stat.sendSize(sent);
	}
	
	public ubyte[] recv_c() {
		int		recvd;
		ubyte[]	buf  = new ubyte[1550];
		Address	from = new IPv4Address();
		
		recvd = recvr.receiveFrom(buf, from);
		if (recvd == -1) {
			Stdout.formatln("CLIENT:  RECV FAIL!");
			return null;
		} else {
			stat.recvSize(recvd);


			if((recvd & 3) != 0){
				recvd += 4 - (recvd & 3);
			}

			return buf[20 .. recvd];
		}
	}
}
