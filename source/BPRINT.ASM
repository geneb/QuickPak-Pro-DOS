;----- BPrint.Asm - BASIC PRINT replacement prints though DOS

;Copyright (c) 1988 Ethan Winer

;Syntax - CALL BPrint(X$)
;
;Note: This routine will print only BASIC strings.  To print numbers, use:
;
;   CALL BPrint(STR$(Number))


.Model   Medium
.Code
    Include  Mixed.Inc

HProc BPrint, XString:Ptr

    Mov   SI,XString         ;get the address for X$ descriptor
    Mov   CX,[SI]            ;put LEN(X$) into CX
    Jcxz  Exit               ;can't print a null string!
    Mov   SI,[SI+02]         ;put address of X$ into SI
    Mov   AH,2               ;specify DOS print service

More:
    Lodsb                    ;get the character to print from X$
    Mov  DL,AL               ;put it into DL
    Int  21h                 ;call the DOS video routine
    Loop More                ;loop until done

Exit:
    HRet

HEndp
End
