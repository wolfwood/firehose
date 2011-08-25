#!/usr/bin/perl -w



$str = " < data > data";

system("gzip $str\.gz");
system("bzip2 $str\.bz2");
system("lzma $str\.lzma");
system("lzop $str\.lzo");

system("cp data ./in3");


system("../testdynamicranger");

system("cp in3.dynr data.dynr");
system("cp in3.out dynr.out");

system("../testranger");

system("cp in3.range data.range");
system("cp in3.out range.out");


system("cp ../infile ./");

$str = " < infile > infile";

system("gzip $str\.gz");
system("bzip2 $str\.bz2");
system("lzma $str\.lzma");
system("lzop $str\.lzo");


system("cp ../infile ./in3");


system("../testdynamicranger");

system("cp in3.dynr infile.dynr");


system("../testranger");

system("cp in3.range infile.range");


#system("../testranger");

#system("cp in3.dynr infile.range");

system("ls -lS data* infile*");
