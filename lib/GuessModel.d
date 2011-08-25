module lib.GuessModel;

import lib.Params;

import tango.core.BitArray;

import tango.io.Stdout;

import tango.math.random.Kiss;

import tango.io.FileConduit;

//import tango.util.Convert;

import tango.text.convert.Float;


class GuessTable{
	static const bool _realtime = false;

	Params _params;

	long[] freqs;

	GuessModel _model;

	GuessTable _parent;

	this(Params params, GuessTable model=null){
		_params = params;

		uint numGuesses = (1 << _params.groupSize);
	
		freqs = new long[](numGuesses);


		if( !(model is null) ){
			_parent = model;

			for(uint i = 0; i < freqs.length; i++){
				freqs[i] = model.freqs[i];
			}
		}else{

			switch(params.guessStyle){

			case ModelStyle.DET:
				_model = new DeterministicGuessModel(numGuesses);
				break;
				
			case ModelStyle.RAND:
				_model = new RandomGuessModel(numGuesses);
				break;
				
			case ModelStyle.MFU:
				_model = new MfuGuessModel(numGuesses);
				break;
				
			case ModelStyle.MRU:
				_model = new MruGuessModel(numGuesses);
				break;
				
			case ModelStyle.GANESH:
				_model = new GaneshGuessModel(_params);
				break;

			case ModelStyle.MFC:
				_model = new MfcGuessModel(numGuesses);
				break;

			case ModelStyle.LFN:
				_model = new LfnGuessModel(numGuesses);
				break;
				
			case ModelStyle.LRN:
				_model = new LrnGuessModel(numGuesses);
				break;
				
			}
			

			for(int i =  (freqs.length - 1); i >= 0; i--){
				freqs[i] = _model.init();
			}
		}

	}
	
	void update(BitArray ba, uint idx){

		long group = bitArray2long(ba, idx);
		
		_model.update(group);
	}

	void nack(BitArray ba, uint idx){
		long group = bitArray2long(ba, idx);
		_model.nack(group);
	}

	void learn(){
		_model.learn(freqs);
	}

	bool setNextGuess(BitArray ba, uint idx){
		if(_realtime){
			void syncWithParent();
		}

		uint i = findMax();
		
		if(freqs[i] == 0){
			return false;
		}
		
		long2bitArray(ba, idx, i);
		
		freqs[i] = 0;

		return true;
	}
	
	uint findMax(){
		uint idx = 0;
		long max = freqs[0];
		
		for(uint i = 1; i < freqs.length; i++){
			if(max < freqs[i]){
				max = freqs[i];
				
				idx = i;
			}
		}
		
		return idx;
	}

	void syncWithParent(){
		for(uint i = 0; i < freqs.length; i++){
			if(freqs[i] != 0){
				freqs[i] = _parent.freqs[i];
			}
		}
	}
	
	void long2bitArray(BitArray ba, uint idx, long group){
		
		uint offset = idx * _params.groupSize;
		
		for(uint i = 0; i < _params.groupSize; i++){
			
			ba[offset+i] = ((group & 1) != 0);
			
			group >>>= 1;
		}
	}

	long bitArray2long(BitArray ba, uint idx){
		
		long group = 0;

		uint offset = idx * _params.groupSize;
		
		for(uint i = 0; i < _params.groupSize; i++){
			//group <<= 1;
			
			if(ba[offset+i]){
				group |= (1 << i);
			}
		}
		
		return group;
	}
}

	
interface GuessModel{
	//this(uint numGuesses);
	long init();
	void update(uint idx);
	void nack(uint idx);
	void learn(long[] freqs);
}	



class DeterministicGuessModel : GuessModel {
	long count;
	long[] local;

	this(uint numGuesses){
		count = 1;
		local.length = numGuesses;

		for(uint i = 0; i < numGuesses; i++){
			local[i] = 1;
		}
	}

	long init(){
		long temp = count;
		
		//count++;
		
		return temp;
	}

	void update(uint idx){}	
	void nack(uint idx){}
	void learn(long[] freqs){
		/*for(uint i = 0; i < freqs.length; i++){
			freqs[i] = local[i];
			}*/
	}
}

class RandomGuessModel : GuessModel {
	long count;
	

	this(uint numGuesses){
		count = 1;
		//local.length = numGuessses;
	}

	long init(){
		long temp = Kiss.shared.toInt();
		
		return temp;
	}

	void update(uint idx){}	
	void nack(uint idx){}

	void learn(long[] freqs){
		for(uint i = 0; i < freqs.length; i++){
			freqs[i] =  Kiss.shared.toInt();
		}
	}
}



class MruGuessModel : GuessModel {
	long count;
	long[] local;

	this(uint numGuesses){
		count = 2;
		local.length = numGuesses;

		for(uint i = 0; i < numGuesses; i++){
			local[i] = 1;
		}
	}

	long init(){
		return 1;
	}

	void update(uint idx){
		local[idx] = count;

		count++;
	}
	void nack(uint idx){}	

	void learn(long[] freqs){
		for(uint i = 0; i < freqs.length; i++){
			freqs[i] = local[i];
		}
	}
}

class MfuGuessModel : GuessModel {
	long[] local;

	this(uint numGuesses){
		local.length = numGuesses;

		for(uint i = 0; i < numGuesses; i++){
			local[i] = 1;
		}
	}

	long init(){
		
		return 1;
	}

	void update(uint idx){
		local[idx]++;
	}

	void nack(uint idx){}

	void learn(long[] freqs){
		for(uint i = 0; i < freqs.length; i++){
			freqs[i] = local[i];
		}
	}
}

class LrnGuessModel : GuessModel {
	long count;
	long[] local;

	this(uint numGuesses){
		count = 2;
		local.length = numGuesses;

		for(uint i = 0; i < numGuesses; i++){
			local[i] = 1;
		}
	}

	long init(){
		return 1;
	}

	void update(uint idx){
	}
	void nack(uint idx){
		local[idx] = count;

		count++;
	}	

	void learn(long[] freqs){
		for(uint i = 0; i < freqs.length; i++){
			freqs[i] = tools!(long).getInverseRankOf(local, i);
		}
	}
}

class LfnGuessModel : GuessModel {
	long[] local;

	this(uint numGuesses){
		local.length = numGuesses;

		for(uint i = 0; i < numGuesses; i++){
			local[i] = 1;
		}
	}

	long init(){
		return 1;
	}

	void update(uint idx){}

	void nack(uint idx){
		local[idx]++;
	}	

	void learn(long[] freqs){
		for(uint i = 0; i < freqs.length; i++){
			
			if(freqs[i] != 0){
				freqs[i] = tools!(long).getInverseRankOf(local, i);
			}
		}
	}
	
}


class MfcGuessModel : GuessModel {
	
	ulong[] local, total;
	real[] scores;

	this(uint numGuesses){
		total.length = numGuesses;
		local.length = numGuesses;
		scores.length = numGuesses;
		
		for(uint i = 0; i < total.length; i++){
			total[i] = 1;
			local[i] = 0;
			scores[i] = 0;
		}
	}

	long init(){
		return 1;
	}

	void update(uint idx){
		local[idx]++;

		total[idx]++;
	}

	void nack(uint idx){
		total[idx]++;
	}

	void learn(long[] freqs){
		for(uint i = 0; i < scores.length; i++){
			scores[i] = cast(real)local[i] / cast(real)total[i];
		}

		for(uint i = 0; i < scores.length; i++){
			if(freqs[i] != 0){
				freqs[i] = tools!(real).getRankOf(scores, i);
			}
		}

		//Stdout.formatln("{} {}", scores, freqs);
	}
}

class GaneshGuessModel : GuessModel {

	long[][] expertFreqs;
	GuessModel[] expertModels;


	long feedbackCount;

	real[][] expertScores;
	real[]   masterScores;

	real[] expertWeights;

	real   masterFeedback;
	real[] expertFeedback;


	long numGuesses, numExperts;
	Params _params;

	
	FileConduit _file;
	bool wrote;


	this(Params params){
		_params = params;

		numExperts = 4;

		numGuesses = (1 << _params.groupSize);


		expertModels = new GuessModel[](numExperts);

		expertFreqs = new long[][](numExperts, numGuesses); 


		for(uint i = 0; i < numExperts; i++){
			switch(i){
			case 0:
				expertModels[i] = new MfuGuessModel(numGuesses);
				break;
			
			case 1:
				expertModels[i] = new MruGuessModel(numGuesses);
				break;

			case 5:
				expertModels[i] = new MfcGuessModel(numGuesses);
				break;
			
			case 2:
				expertModels[i] = new DeterministicGuessModel(numGuesses);
				break;

			case 3:
				expertModels[i] = new LfnGuessModel(numGuesses);
				break;

			case 4:
				expertModels[i] = new LrnGuessModel(numGuesses);
				break;

			case 6:
				expertModels[i] = new RandomGuessModel(numGuesses);
				break;


			}


			for(uint k = 0; k < expertFreqs[i].length; k++){
				expertFreqs[i][k] = expertModels[i].init();
			}
		}


		expertScores = new real[][](numExperts, numGuesses);
		masterScores = new real[](numGuesses);
		
		expertWeights = new real[](numExperts);
		expertFeedback = new real[](numExperts);
		
		
		feedbackCount = 0;

		masterFeedback = 0.0;

		for(uint i = 0; i < numExperts; i++){
			expertWeights[i]  = (cast(real)1) / (cast(real)numExperts);


			expertFeedback[i] = 0.0;

			for(uint k = 0; k < numGuesses; k++){
				expertScores[i][k] = (cast(real)1) / (cast(real)numGuesses);
			}

			//Stdout.formatln("{} {} {} {} {}", (cast(real)1), cast(real)numExperts, expertWeights[i], expertFeedback[0], expertScores[0][0]);
		}


		for(uint k = 0; k < numGuesses; k++){
			masterScores[k] = (cast(real)1) / (cast(real)numGuesses);
		}


	}
		
	long init(){
		return 1;
	}


	void nack(uint idx){
		// update everyone
		for(uint i = 0; i < numExperts; i++){
			expertModels[i].nack(idx);
		}
	}

	void update(uint idx){
		feedbackCount++;
		
		masterFeedback += masterScores[idx];

		// update everyone
		for(uint i = 0; i < numExperts; i++){
			expertModels[i].update(idx);

			expertFeedback[i] += expertScores[i][idx];
		}
	}






	void learn(long[] freqs){
		if(!wrote){
			_file = new FileConduit("stats/weights", FileConduit.WriteCreate);
			wrote = true;
		}
		
		char[256] buffer;
		
		real masterPerf = masterFeedback / (cast(real)feedbackCount);
		
		real epsilonWeight = 0.0001;
		

		//Stdout.formatln("{} {} {}", masterFeedback, expertFeedback[0], feedbackCount);

		for(uint i = 0; i < numExperts; i++){
			real expertPerf = expertFeedback[i] / (cast(real)feedbackCount);
			

			//Stdout.formatln("{} {}", masterPerf, expertPerf);

			expertWeights[i] += ((expertPerf - masterPerf) * expertWeights[i] );
			
			if(epsilonWeight > expertWeights[i]){
				expertWeights[i] = epsilonWeight;
			}
		}

		//Stdout.formatln("{.5}", expertWeights);		

		for(uint i = 0; i < expertWeights.length; i++){

			//			_file.write( Integer.toString(credits[i]) );
			_file.write( format!(char, real)(buffer, expertWeights[i], 5) );
			_file.write(" ");
		}
		_file.write("\n");


		masterFeedback = 0;
		feedbackCount = 0;

		for(uint i = 0; i < numExperts; i++){
			expertFeedback[i] = 0;
		}

				
		for(uint i = 0; i < numExperts; i++){
			expertModels[i].learn(expertFreqs[i]);
		}
		

		for(uint i = 0; i < numExperts; i++){
			long amountAllocated = 0;
			
			for(uint k = 0; k < numGuesses; k++){
				amountAllocated += expertFreqs[i][k]; 
			}

			real amount = cast(real)amountAllocated;

			for(uint k = 0; k < numGuesses; k++){
				expertScores[i][k] = (cast(real)expertFreqs[i][k]) / amount;

				if(expertScores[i][k] < epsilonWeight){
					expertScores[i][k] = epsilonWeight;
				}
			}
		}


		for(uint i = 0; i < numGuesses; i++){
			masterScores[i] = 0.0;

			for(uint k = 0; k < numExperts; k++){
				masterScores[i] += expertWeights[k] * expertScores[k][i];
			}
		}


		// recalculate owner 'freqs' to reflect weighted expert votes
		for(uint i = 0; i < freqs.length; i++){	
			if(freqs[i] != 0){
				//freqs[i] = cast(long)(masterFreqs[i] / epsilonWeight);

				freqs[i] = tools!(real).getRankOf(masterScores, i);
			}
		}

	}	
}

template tools(T){

	int getRankOf(T[] freq, uint idx){
	
		// we will at least match ourselves
		int rank = 1;
		
		for(uint i = 0; i < freq.length; i++){
			if(freq[i] < freq[idx]){// && i != idx){
				rank++;
			}
		}
		
		return rank;
	}

	int getInverseRankOf(T[] freq, uint idx){
		
		// we will at least match ourselves
		int rank = 1;
		
		for(uint i = 0; i < freq.length; i++){
			if(freq[i] > freq[idx]){
				rank++;
			}
		}
		
		return rank;
	}
}
