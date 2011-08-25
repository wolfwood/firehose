#!/usr/bin/perl -w

$datadir = "../data";

$outputdir = "output";

#@files = ("small.txt", "medium.txt", "large.txt");
@files = ("large.txt");
$repeats = 5;

$exe = "../gaygee client";

$battery = "BAT0";

#$user = "wolfwood";
$addy = "10.0.0.1";
#$remoteexe = "Dfirehose/gaygee";

foreach $file (@files) {
	 

		#system("cp $datadir/$file in3");


		
		#open(SERVER, "ssh $user\@$addy $remoteexe server");


		for($run = 0; $run < 5; $run++){
			print "Please start the server then press enter to continue\n";
	
			<STDIN>;
				for($i = 0; $i < $repeats; $i++){
						$outputpath = "$outputdir/$file/run$run";

						system("mkdir -p $outputpath");

						system("tcpdump -s 0 -i wlan0 -w $outputpath/tcpdump.$i.out ip proto 253 or ip proto 254 &");
						

						system("cat /proc/acpi/battery/$battery/state > $outputpath/batt.pre.$i.out");

						system("$exe $datadir/$file $addy  > $outputpath/client.$i.out");

						system("cat /proc/acpi/battery/$battery/state > $outputpath/batt.post.$i.out");

						system("killall tcpdump");
				}
		}
}
