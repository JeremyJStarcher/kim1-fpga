romdest=./rom

PROGRAM=timertest
RESET=reset
DEST=/tmp/guessword

all: $(PROGRAM).ptp ${PROGRAM}.ptp ${RESET}.ptp
	rm -rf ${DEST}
	mkdir ${DEST}
	unix2dos *.ptp
	cp *.ptp ${DEST}
	cp *.hex ${DEST}
	(cd js; node makeram.js)
	
$(PROGRAM).ptp: $(PROGRAM).bin Makefile
	ca65 -g -l $(PROGRAM).lst $(PROGRAM).s
	ld65 -t none -vm -m $(PROGRAM).map -o $(PROGRAM).bin $(PROGRAM).o
	srec_cat $(PROGRAM).bin -binary -offset 0x0200 -o $(PROGRAM).ptp -MOS_Technologies
	ptp2hex	${PROGRAM}.ptp > /dev/null


$(PROGRAM).bin: $(PROGRAM).o
	ld65 -t none -vm -m $(PROGRAM).map -o $(PROGRAM).bin $(PROGRAM).o

$(PROGRAM).o:	$(PROGRAM).s
	ca65 -g -l $(PROGRAM).lst $(PROGRAM).s


$(RESET).ptp: $(RESET).bin Makefile
	ca65 -g -l $(RESET).lst $(RESET).s
	ld65 -t none -vm -m $(RESET).map -o $(RESET).bin $(RESET).o
	srec_cat $(RESET).bin -binary -offset 0x0200 -o $(RESET).ptp -MOS_Technologies
	ptp2hex	${RESET}.ptp > /dev/null


$(RESET).bin: $(RESET).o
	ld65 -t none -vm -m $(RESET).map -o $(RESET).bin $(RESET).o

$(RESET).o:	$(RESET).s
	ca65 -g -l $(RESET).lst $(RESET).s



clean:
	$(RM) *.o *.lst *.map *.bin  js/PROGRAM.s PROGRAM.s

distclean: clean
