;******* Blanks.Asm - returns the number of leading blanks/CHR$(0) in a string

;Copyright (c) 1988 Ethan Winer

;Syntax: B = Blanks%(X$)


.Model Medium
.Code
    Include Mixed.Inc

HProc Blanks, XString:Ptr

    Mov  SI,XString        ;get the address for X$ descriptor
    Mov  CX,[SI]           ;put its length into CX as a loop counter
    Mov  SI,[SI+02]        ;now SI points to the first character in X$
    Xor  DX,DX             ;zero out the blanks counter
    Jcxz Exit              ;the string is null, exit with a result of zero

More:
    Lodsb                  ;get a character from X$
    Or   AL,AL             ;see if it's a CHR$(0)
    Jz   Next              ;yes, increment the counter and keep searching
    Cmp  AL,32             ;see if it's a blank space
    Jnz  Exit              ;no, so that's all we need to examine

Next:
    Inc  DX                ;show that we counted another blank
    Loop More              ;and keep searching

Exit:
    Mov  AX,DX             ;put the function output into AX
    HRet                   ;return to BASIC

HEndp
End
