romdest=./rom

PROGRAM=timertest
DEST=/tmp/guessword

all: $(PROGRAM).ptp ${PROGRAM}.ptp
	rm -rf ${DEST}
	mkdir ${DEST}
	cp *.ptp ${DEST}
	cp *.hex ${DEST}

$(PROGRAM).ptp: $(PROGRAM).bin Makefile
	ca65 -g -l $(PROGRAM).lst $(PROGRAM).s
	ld65 -t none -vm -m $(PROGRAM).map -o $(PROGRAM).bin $(PROGRAM).o
	srec_cat $(PROGRAM).bin -binary -offset 0x0200 -o $(PROGRAM).ptp -MOS_Technologies
	ptp2hex	${PROGRAM}.ptp > /dev/null


$(PROGRAM).bin: $(PROGRAM).o
	ld65 -t none -vm -m $(PROGRAM).map -o $(PROGRAM).bin $(PROGRAM).o

$(PROGRAM).o:	$(PROGRAM).s
	ca65 -g -l $(PROGRAM).lst $(PROGRAM).s

clean:
	$(RM) *.o *.lst *.map *.bin  js/PROGRAM.s PROGRAM.s

distclean: clean
