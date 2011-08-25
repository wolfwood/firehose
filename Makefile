
.PHONEY: firehose


all: firehosefoo netfirehosefoo ranger dynamicranger


firehosefoo:
	rebuild -oqobj -dc=gdc-posix-tango firehose.d

networktest:
	rebuild -oqobj -g -dc=gdc-posix-tango NetworkManager.d
	
netfirehosefoo:
	rebuild -oqobj -dc=gdc-posix-tango netfirehose.d
	
ranger:
	rebuild -oqobj -g -dc=gdc-posix-tango testranger.d

dynamicranger:
	rebuild -oqobj -g -dc=gdc-posix-tango testdynamicranger.d
	
gaygeefoo:
	rebuild -oqobj -g -dc=gdc-posix-tango gaygee.d

clean:
	rm -r obj firehose netfirehose
