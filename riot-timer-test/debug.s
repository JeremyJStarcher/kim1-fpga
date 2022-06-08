
PRINT_WORD_LIST:
        LDY     WORD_TAIL_IDX_ADDR
        LDX     WORD_TAIL_IDX_ADDR+1


PRINT_WORD_LIST2:
        STY     CURRENT_TAIL_IDX
        STX     CURRENT_TAIL_IDX+1

; -- start
        STY     WORD_IDX
        STX     WORD_IDX+1

        JSR     CALCULATE_WORD_PTR
        JSR     OUT_STRING
        JSR     CRLF
; -- end

        LDY     CURRENT_TAIL_IDX
        LDX     CURRENT_TAIL_IDX+1

        ; If the inner loop has not rolled past zero, repeat
        DEY
        CPY     #$FF
        BNE     PRINT_WORD_LIST2

        ; If the outer loop has not rolled past zero, repeat
        ; No need to reset 'Y', it will keep the value '$FF'
        DEX
        CPX     #$FF
        BNE     PRINT_WORD_LIST2
        RTS



OUT_STRING:
        LDY     #$00
OUT_STRING3:
        STY     TMP3
        LDA     (WORDLIST_PTR),Y        ; Load the character from the word list
        TAY
        LDA     CODE_TO_TTY,Y                 ; Look up the actual pattern
        JSR     OUTCH

        LDY     TMP3
        INY
        CPY     #COMPRESSED_WORD_SIZE
        BNE     OUT_STRING3
        RTS

CLK_PAUSE:
        PHA
        LDA #$20
        STA T0064
CLK_PAUSE_LOOP:
        LDA TSTATUS
        BPL CLK_PAUSE_LOOP
        PLA
        RTS

MEGAPAUSE:
        PHA
        LDA #$FF
        STA T1024
MEGAPAUSE_LOOP:
        LDA TSTATUS
        BPL MEGAPAUSE_LOOP
        PLA
        RTS

SAMPLEDELAY:
        LDY     #1              ;MULTIPLY FACTOR
DLY1:   LDX     #2              ;DELAY TIME
DLY2:   DEX
        BNE     DLY2
        DEY
        BNE     DLY1

        RTS



CODE_TO_TTY:
        .BYTE ' '
        .BYTE 'a'
        .BYTE 'b'
        .BYTE 'c'
        .BYTE 'd'
        .BYTE 'e'
        .BYTE 'f'
        .BYTE 'g'
        .BYTE 'h'
        .BYTE 'i'
        .BYTE 'j'
        .BYTE 'l'
        .BYTE 'o'
        .BYTE 'p'
        .BYTE 's'
        .BYTE 'u'
        .BYTE 'y'
        .BYTE 'n'
        .BYTE 'r'
        .BYTE 't'
        .BYTE '_'
