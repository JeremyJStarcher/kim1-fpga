TESTID = $01
POINTL = $10
POINTH = $11
TMPA = $12
TMPX = $13
TMPY = $14
ATIME = $15 ; Actual time
ASTAT = $16 ; Actual status
ETIME = $17 ; Expected time
ESTAT = $18 ; Expected status
TEST_RESULT = $19;
FINAL_RESULT = $20;


        .ORG $0200


; ROM ROUTINES
OUTCH = $1EA0
PRTBYT = $1E3B ; byte in A register
CRLF = $1E2F
OUTSP = $1E9E
GETKEY = $1F6A
START  = $1C4F

;;;;;;;;;;;;;;;;;;; MAIN ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        nop
	nop
	nop

	LDA #$FE
        STA $00

        LDA #$FA 
        STA $01

         JSR CRLF
         JSR CRLF

        JSR CRLF
        JSR CRLF
        JSR CRLF
        JSR CRLF

;        LDA #$00
;        STA TESTID
;        STA FINAL_RESULT

;;;;;;;;;;;; TESTS START HERE


        JMP START
