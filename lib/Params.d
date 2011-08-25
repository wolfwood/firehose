// the parameters of a firehose

module lib.Params;

import lib.Statistics;

// write acks to file, run gzip, bzip2 and range on file -- are there better codings to have?

// rescale guess scores to [0,2^16)

// multi-expert -- approximates adaptive distobution discovery
// weight plot indicates good strategies
// show it adapt, cat 2 very dissimilar files

// formally explore the problem

// give him a asymmetry power equation/ diagram demonstrating where
// there is savings to be had .. some concrete statements supporting
// our aproaches as the most likely to be fruitful, and building a
// base for a good neg-result paper - we have to expose what the
// limiting factors are

// expectation analysis under uniform distro?


// is rand really random?

enum ModelStyle { DET, RAND, MFU, MRU, GANESH, MFC, LFN, LRN}



struct Params{
	bool isServer = true;

	char[] filename = "infile";

	uint ackStyle   = 1;

	ModelStyle guessStyle = ModelStyle.GANESH ;

	uint mdataStyle = 1;

	uint MTU = 1500;
	uint ipOverhead = 20;
	uint protocolOverhead = 0;

	Statistics stats;

	uint groupSize;
	uint numGroups;
}
