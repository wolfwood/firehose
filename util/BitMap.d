// a standard bitmap impl.

module util.BitMap;

class BitMap{
	ubyte[] _map;
	//uint _num;
	
public:
	uint length;

	this(uint num){
		uint numBytes = num / (_map[0].sizeof);
		
		if(num != numBytes * _map[0].sizeof){
			numBytes++;
		}

		length = num;
		_map.length = numBytes; 
	}

	this(ubyte[] data){
		length = data.length;
		_map = data; 
	}


	bool test(uint idx){
		uint entry = idx / (_map[0].sizeof);
		uint offset = idx % (_map[0].sizeof);

		return ((_map[entry]) & (1 << offset)) != 0;
	}

	void set(uint idx, bool val){
		uint entry = idx / (_map[0].sizeof);
		uint offset = idx % (_map[0].sizeof);

		auto data = 0;
		data = ~data;

		if(!val){
			data -= 1;
		}

		_map[entry] &= (data << offset);
	}

	bool setData(ubyte[] data){
		if(data.length < _map.length){
			return false;
		}else{
			_map = data;
			length = _map.length;

			return true;
		}
	}

	ubyte[] getMap(){
		return _map;
	}
}