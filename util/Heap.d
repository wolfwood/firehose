// i hate tango, so here's a picture of a hampster with a heap on its head

module util.Heap;

template MinHeap(T,U){
	
	class MinHeap{

	private:
		T[] _data;
		U[] _scores;

		uint _numItems;

		const uint _minSize = 4;

	public:

		this(){
			_numItems = 0;

			_data.length = _minSize;
			_scores.length = _minSize;
		}

		this(uint size){
			_data.length = size;

			this();
		}

		// this(T[], U[]){}

		// heapify

		void insert(T t, U u){

			if(_numItems >= _data.length){
				_data.length = _data.length * 2;
				_scores.length = _data.length;
			}

			_data[_numItems] = t;
			_scores[_numItems] = u;

			_numItems++;

			bubbleDown(_numItems-1);


		}
 
		U peek(){
			return _scores[0];
		}

		T pop(){
			T tmp = _data[0];
			
			uint entry = _numItems-1;

			_data[0]   = _data[entry];
			_scores[0] = _scores[entry];

			_numItems--;

			bubbleUp(0);

			return tmp;
		}
	

		/*
			void bubbleDown(T data, U scores){
			if(data.length == 1){return;}
			
			uint entry = data.length -1;
			uint parent = (entry -1)/2;
			
			if(scores[entry] < scores[parent]){
			T ttmp = data[parent];
			U utmp = scores[parent];
			
			data[parent] = data[entry];
			scores[parent] = scores[entry];
			
			data[entry] = ttmp;
			scores[entry] = utmp;
			
			bubbledown(data[0..parent+1], scores[0..parent+1]);
			}else{
			return;
			}
			}
		*/
		
		void bubbleDown(uint idx){
			if(idx == 0){return;}
			
			uint parent = (idx-1)/2;
			
			if(_scores[idx] < _scores[parent]){
				swap(idx, parent);
				
				bubbleDown(parent);
			}else{
				return;
			}
		}
		
		void bubbleUp(uint idx){
			uint l = (idx+1)*2 -1;
			uint r = (idx+1)*2;
			
			if(l >= _data.length){
				return;
			}

			if(r < _data.length && _scores[l] > _scores[r]){
				l = r;
			}
				 

			if(_scores[l] < _scores[idx]){
				swap(l, idx);

				bubbleUp(l);
			}
		}
		

		void swap(uint i1,uint i2){
			T ttmp = _data[i2];
			U utmp = _scores[i2];
			
			_data[i2] = _data[i1];
			_scores[i2] = _scores[i1];
			
			_data[i1] = ttmp;
			_scores[i1] = utmp;
			
		}

		uint getNumItems(){
			return _numItems;
		}

	}
}
