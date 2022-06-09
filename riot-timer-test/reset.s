       .ORG $0200

    LDA #$00
    ; STA $00F1
    STA $17F9     
    STA $17FA
    STA $17FC
    STA $17FE

    LDA #$1C
    STA $17FB
    STA $17FD
    STA $17FF

    brk
