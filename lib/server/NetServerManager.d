// APPLYING MAGIC!

module lib.server.NetServerManager;

import lib.Params;
import lib.NetworkInterface;
import tango.net.Socket;
import tango.io.Stdout;
import tango.time.Time;

import lib.Statistics;

class NetServer : ServerNetworkInterface{
	protected Socket	sendr, recvr;
	protected Address	target;
	protected bool		targetted;
	
	public Statistics stat;

	public this(Statistics dastat) {
		stat = dastat;

		sendr = new Socket(AddressFamily.INET, SocketType.RAW, cast(ProtocolType)254);
		recvr = new Socket(AddressFamily.INET, SocketType.RAW, cast(ProtocolType)253);
		recvr.bind(new IPv4Address("192.168.0.109", IPv4Address.PORT_ANY));
		target = new IPv4Address(IPv4Address.ADDR_ANY, IPv4Address.PORT_ANY);
		targetted = false;
	}
	
	public this(Address _target, Statistics dastat) {
		stat = dastat;

		sendr = new Socket(AddressFamily.INET, SocketType.RAW, cast(ProtocolType)254);
		recvr = new Socket(AddressFamily.INET, SocketType.RAW, cast(ProtocolType)253);
		recvr.bind(new IPv4Address(IPv4Address.ADDR_ANY, IPv4Address.PORT_ANY));
		target = _target;
		targetted = true;
	}

	public void send_s(ubyte[] data) {
		int		sent;
		
		sent = sendr.sendTo(data, target);
		if (sent == -1)
			Stdout.formatln("SERVER:  SEND FAIL!");

		stat.sendSize(sent);
	}
	
	public ubyte[] recv_s() {
		int		recvd;
		ubyte[]	buf = new ubyte[1550];
		Address	from = new IPv4Address();
		
		recvd = recvr.receiveFrom(buf, from);
		if (recvd == -1) {
			Stdout.formatln("SERVER:  RECV FAIL!");
			return null;
		}

		stat.recvSize(recvd);

		if((recvd & 3) != 0){
			recvd += 4 - (recvd & 3);
		}


		if (targetted) {
			target = from;
			targetted = true;	
		}
		return buf[20 .. recvd];
	}
	
	public bool isEmpty() {
		int num;
		SocketSet	readlist = new SocketSet();
		readlist.add(recvr);

		TimeSpan span = TimeSpan.millis(200); //TimeSpan.zero
			
		num = Socket.select(readlist, cast(SocketSet)null, cast(SocketSet)null, span);
		if (num > 0) {
			return false;
		} else {
			return true;
		}
	}
}//NetServerManager
