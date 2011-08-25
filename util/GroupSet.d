// a collection of groups

module util.GroupSet;

import util.BitMap;

typedef ulong group_t;

class GroupSize{
	uint _num;
	uint _grpSize;

	group_t[] _data;
	BitMap _bitMap;

	this(uint num, uint grpSize){
		_num = num;
		_grpSize = grpSize;
		_data.length = num;

		_bitMap = new BitMap(num);
	}


	group_t read(uint idx){
		return _data[idx];
	}

	void write(uint idx, group_t grp){
		_data[idx] = grp;
	}
}