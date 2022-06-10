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


; The 'USER' timers
T0001 = $1704
T0008 = $1705
T0064 = $1706
T1024 = $1707
TSTATUS = $1707
TREAD_TIME = $1706

; The 'SYSTEM' timers
;T0001 = $1744
;T0008 = $1745
;T0064 = $1746
;T1024 = $1747

TI0001 = T0001 +8
TI0008 = T0008 +8
TI0064 = T0064 +8
TI1024 = T1024 +8


;TSTATUS = $1747
;TREAD_TIME = $1746

SAD = $1740 ; character to output
SBD = $1742 ; segment to output data
PADD = $1741 ; 6530 RIOT data direction


; ROM ROUTINES
OUTCH = $1EA0
PRTBYT = $1E3B ; byte in A register
CRLF = $1E2F
OUTSP = $1E9E
GETKEY = $1F6A
START  = $1C4F

.macro pushall
        ; non-destructive push-all to boot
        sta TMPA

        PHA
        TYA
        PHA
        TXA
        PHA

        lda TMPA
.endmacro

.macro pullall
        PLA
        TAX
        PLA
        TAY
        PLA
.endmacro

.macro end_test  arg1, arg2, arg3
.scope
        LDA TSTATUS
        LDY TREAD_TIME

        STA ASTAT
        STY ATIME

        LDA #arg2
        STA ESTAT
        LDA #arg3
        STA ETIME

        print_string arg1
        JSR run_end_test
.endscope
.endmacro

.macro print_string text
.endmacro

.macro print_string2 text
.scope
        jmp skip
l:
        .byte text
        .byte 0
skip:
        pushall
        LDA #<l
        STA POINTL;
        LDA #>l
        STA POINTH
        JSR OUT_STRING
        pullall
.endscope
.endmacro

;;;;;;;;;;;;;;;;;;; MAIN ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        JSR CRLF
        JSR CRLF

        JSR CRLF
        JSR CRLF
        JSR CRLF
        JSR CRLF

        LDA #$00
        STA TESTID
        STA FINAL_RESULT

;;;;;;;;;;;; TESTS START HERE


        JMP START
