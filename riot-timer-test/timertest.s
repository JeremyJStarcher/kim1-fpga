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
RESULT = $19;

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

        print_string "6530/6532 TIMER TEST"
        JSR CRLF
        print_string "DEVELOPED AGAINT REAL HARDWARE USED TO TEST SIMULATIONS "
        print_string "AND EMULATIONS"
        JSR CRLF
        JSR CRLF
        JSR CRLF

        LDA #$00
        STA TESTID

;;;;;;;;;;;; TESTS START HERE

.scope
        JSR PRINT_TEST_ID
        LDA #$FF
        STA T0001
        NOP
        end_test "T0001 - BASIC COUNTDOWN", $00, $F5
.endscope

;;;;;;;;;;;; TESTS START HERE
.scope
        JSR PRINT_TEST_ID
        LDA #$01
        STA T0001
        NOP
        end_test "T0001 - BASIC COUNTDOWN (OVERFLOW)", $80, $F7
.endscope

.scope
        JSR PRINT_TEST_ID
        LDA #$FF
        STA TI0001
        NOP
        end_test "TI0001 - BASIC COUNTDOWN", $00, $F5
.endscope

.scope
        JSR PRINT_TEST_ID
        LDA #$01
        STA TI0001
        NOP
        end_test "TI0001 - BASIC COUNTDOWN (OVERFLOW)", $80, $F7
.endscope


.scope
        JSR PRINT_TEST_ID
        LDA #$FF
        STA T0008
        NOP
        end_test "T0008 - BASIC COUNTDOWN", $00, $FD
.endscope


.scope
        JSR PRINT_TEST_ID
        LDA #$FF
        STA TI0008
        NOP
        end_test "TI0008 - BASIC COUNTDOWN", $00, $FD
.endscope


 BRK

;;;;; ROUTINES

PRINT_TEST_ID:
        print_string "TEST #"
        LDA TESTID
        JSR PRTBYT
        JSR OUTSP
        INC TESTID
        RTS


OUT_STRING:
.proc outstring
        LDY #$00
l1:
        pushall
        LDA (POINTL),Y
        BEQ exit
        JSR OUTCH
        pullall

        INY

        JMP l1
exit:
        pullall
        RTS
.endproc


.proc run_end_test
        pushall
        jsr OUTSP

        lda ASTAT
        jsr PRTBYT
        jsr OUTSP

        lda ATIME
        jsr PRTBYT
        jsr OUTSP

        pullall

        ; Reset the test result
        lda #$00
        sta RESULT

        LDA ASTAT
        CMP ESTAT
        BEQ testtime
        print_string "(ESTAT "
        LDA ESTAT
        jsr PRTBYT
        print_string ") "
        inc RESULT

testtime:
        LDA ATIME
        CMP ETIME
        BEQ done
        print_string "(ETIME "
        LDA ETIME
        jsr PRTBYT
        print_string ") "

        inc RESULT

done:
        print_string "RESULT: "
        LDA RESULT
        jsr PRTBYT
        jsr CRLF
        RTS
.endproc

; If the Z flag is 0, then A <> NUM and BNE will branch
; If the Z flag is 1, then A = NUM and BEQ will branch
; If the C flag is 0, then A (unsigned) < NUM (unsigned) and BCC will branch
; If the C flag is 1, then A (unsigned) >= NUM (unsigned) and BCS will branch


; Write Timer  RS  R/W  A4   A3  A2  A1  A0
;    1T         1    0   1  (a)   1   0   0
;    8T         1    0   1  (a)   1   0   1
;   64T         1    0   1  (a)   1   1   0
; 1024T         1    0   1  (a)   1   1   1

; Read Timer
;               1    1   -  (a)   1   -   1

; Read Interrupt Flags
;               1    1   -    -   1   -   1
; Write Edge Detect Control
;               1    0   0    -   1  (b) (c)

 ; (a) A3=0 disable interrupt from timer to IRQB
 ;     A3=1 to enable interrupt timer to IRQB
 ; (b) A1=0 to disable interrupt from PA7 to IRCB
 ;     A1=1 to enable interrupt from PA7 to IRCB
 ; (c)
 ; A0=0 for negative edge-detect
 ; A0=1 for positive edge-detect
; $1744 = 1011101000100 (PIN A4 is inverted on the schematic)
