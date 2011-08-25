#!/usr/bin/perl -w

$outputdir = "goodput";

@files = ("medium.txt", "large.txt");
$repeats = 5;

foreach $file (@files) {
		open(RX, ">$outputdir/$file/rxbytes.dat");
		open(TX, ">$outputdir/$file/txbytes.dat");
		open(CYCLES, ">$outputdir/$file/cycles.dat");
		open(BATT, ">$outputdir/$file/battery.dat");
		open(LAT, ">$outputdir/$file/latency.dat");
		

		for($i = 0; $i < $repeats; $i++){
				$rxcounts = 0;
				$txcounts = 0;
				$cyclecounts = 0;
				$battcounts = 0;
				$latcounts = 0;

				$rxsum  = 0;
				$txsum  = 0;
				$cyclesum = 0;
				$battsum = 0;
				$latsum = 0;

				my(@rxQ, @txQ, @cycleQ, @battQ, @latQ);


				for($run = 0; $run < 5; $run++){
						$inputpath = "$outputdir/$file/run$run";

						open(IN, "<$inputpath/client.$i.out");

						while(<IN>){
								if(/cycles to encode: (\d+)/){
										$temp = $1;

										$cyclecounts++;

										$cyclesum += $temp;

										push @cycleQ, $temp; 
								}elsif(/Bytes Tx:(\d+)  Rx:(\d+)/){
										$temp = $1;
										$temp2 = $2;

										$txcounts++;
										$rxcounts++;

										$txsum += $temp;
										$rxsum += $temp2;

										push @txQ, $temp;
										push @rxQ, $temp2;
								}else{
										print $_;
								}
						}

						close IN;



						open(IN, "<$inputpath/batt.pre.$i.out");

						$premah = 0;

						while(<IN>){
								if(/(\d+) mAh/){
										$premah = $1;
								}
						}

						close IN;


						open(IN, "<$inputpath/batt.post.$i.out");

						$postmah = 0;

						while(<IN>){
								if(/(\d+) mAh/){
										$postmah = $1;
								}
						}

						close IN;
						
						$battcounts++;

						$temp = ($premah - $postmah);

						$battsum += $temp;

						push @battQ, $temp;


						open(IN, "tcpdump -r $inputpath/tcpdump.$i.out|");

						$end = -1; 
						$start = -1;

						while(<IN>){
								if(/\d+:\d+:([0123456789.]+)/){
										$temp = $1;

										if($start == -1){
												$start = $temp;
										}else{
												$end = $temp;
										}
								}
						}
						close IN;

						$latcounts++;

						if($end == -1 or $start == -1){
								die "failboat";
						}

						$latsum += ($end - $start);
				}


				# RX
				$avg = $rxsum / $rxcounts;

				$stddev = 0;

				foreach $item (@rxQ){
						$stddev += ($item - $avg)*($item - $avg);
				}
				
				$stddev = $stddev / $rxcounts;
				
				$stddev = sqrt($stddev);
				
				$stderr = $stddev / sqrt($rxcounts);
				
				$cilo = $avg - (1.645 * $stderr);
				$cihi = $avg + (1.645 * $stderr);

				print RX "$i $avg $cilo $cihi\n";


				# TX
				$avg = $txsum / $txcounts;

				$stddev = 0;

				foreach $item (@txQ){
						$stddev += ($item - $avg)*($item - $avg);
				}
				
				$stddev = $stddev / $txcounts;
				
				$stddev = sqrt($stddev);
				
				$stderr = $stddev / sqrt($txcounts);
				
				$cilo = $avg - (1.645 * $stderr);
				$cihi = $avg + (1.645 * $stderr);

				print TX "$i $avg $cilo $cihi\n";


				# CYCLES
				$avg = $cyclesum / $cyclecounts;

				$stddev = 0;

				foreach $item (@cycleQ){
						$stddev += ($item - $avg)*($item - $avg);
				}
				
				$stddev = $stddev / $cyclecounts;
				
				$stddev = sqrt($stddev);
				
				$stderr = $stddev / sqrt($cyclecounts);
				
				$cilo = $avg - (1.645 * $stderr);
				$cihi = $avg + (1.645 * $stderr);

				print CYCLES "$i $avg $cilo $cihi\n";


				# BATT
				$avg = $battsum / $battcounts;

				$stddev = 0;

				foreach $item (@battQ){
						$stddev += ($item - $avg)*($item - $avg);
				}
				
				$stddev = $stddev / $battcounts;
				
				$stddev = sqrt($stddev);
				
				$stderr = $stddev / sqrt($battcounts);
				
				$cilo = $avg - (1.645 * $stderr);
				$cihi = $avg + (1.645 * $stderr);

				print BATT "$i $avg $cilo $cihi\n";


				# LAT
				$avg = $latsum / $latcounts;

				$stddev = 0;

				foreach $item (@latQ){
						$stddev += ($item - $avg)*($item - $avg);
				}
				
				$stddev = $stddev / $latcounts;
				
				$stddev = sqrt($stddev);
				
				$stderr = $stddev / sqrt($latcounts);
				
				$cilo = $avg - (1.645 * $stderr);
				$cihi = $avg + (1.645 * $stderr);

				print LAT "$i $avg $cilo $cihi\n";

		}
		

		close RX;
		close TX;
		close CYCLES;
		close BATT;
		close LAT;
		
}



