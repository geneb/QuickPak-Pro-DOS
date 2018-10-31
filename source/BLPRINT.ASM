;----- BLPrint.Asm - BASIC LPrint replacement returns printer status

;Copyright (c) 1988 Ethan Winer

;Syntax - CALL BLPrint(LPTNo%, X$, ErrCount%)
;  Where X$ is sent to printer # LPTNo, and ErrCount% returns either -1
;  if everything went okay, or the number of bytes actually printed.
;
;Note: This routine will print only strings.  To print numbers, use:
;
;  CALL BLPrint(LPTNo%, STR$(Number), ErrCount%)


.Model   Medium
.Code
Include  Mixed.Inc

HProc BLPrint, LPTNo:Ptr, XString:Ptr, ErrCount:Ptr

    Mov  DI,ErrCount         ;put the address for ErrCount% into DI
    Mov  Word Ptr [DI], -1   ;set ErrCount% = -1 (assume no errors)
    Mov  SI,LPTNo            ;get the printer number to use
    Mov  DX,[SI]             ;put it into DX
    Dec  DX                  ;adjust 1 to 0, 2 to 1, etc. for the BIOS

    Mov  SI,XString          ;get the address for X$ descriptor
    Mov  CX,[SI]             ;put LEN(X$) into CX
    Jcxz Exit                ;can't print a null string!
    Mov  SI,[SI+02]          ;put address of X$ into SI
    Mov  BL,0                ;BL tracks how many characters were printed

More:
    Lodsb                    ;get the character to print from X$
    Mov  BH,2                ;we'll try it twice in case of a time-out

Retry:
    Or   BH,BH               ;did we already do it twice?
    Jz   Failed              ;yes and it failed, exit with ErrCount% = count

    Mov  AH,0                ;specify the BIOS Print Character service
    Int  17h                 ;call the BIOS to print it
    Dec  BH                  ;show that we did it once
    Or   AH,10000000b        ;who cares if it's busy?
    And  AH,10111111b        ;ditto for the printer acknowledgment flag
    Cmp  AH,144              ;see what happened
    Jnz  Retry               ;no good, try it again
    Inc  BL                  ;show that another character was printed
    Loop More                ;loop until done
    Jmp  Short Exit          ;okay, skip over Failed code

Failed:
    Mov  [DI],BX             ;assign ErrCount% = number of bytes printed

Exit:
    HRet

HEndp
End
