;********** ASCII.Asm

;Copyright (c) 1988 Ethan Winer

;Syntax: A = ASCII%(X$)

;This is a smart ASC() substitute that returns -1 for a null string instead
;of creating an Illegal Function Call Error and eliminates extra code like:
;
;    IF LEN(X$) THEN A = ASC(X$)

.Model Medium
.Code

Public ASCII

ASCII Proc Far             ;this is faster than using HProc

    Mov  SI,SP             ;put the stack pointer into SI
    Mov  BX,[SI+04]        ;get the address for X$ descriptor
    Mov  AX,[BX]           ;put LEN(X$) into AX
    Or   AX,AX             ;is it null?
    Jnz  Okay              ;no, continue
    Dec  AX                ;assign the function output in AX to -1
    Jmp  Short Exit        ;and exit

Okay:
    Mov  BX,[BX+02]        ;get the address for X$ data
    Mov  AX,[BX]           ;put its ASCII value into AX
    Xor  AH,AH             ;clear AH of any extraneous junk

Exit:
    Ret  2                 ;return to BASIC leaving the function output in AX

ASCII Endp
End
