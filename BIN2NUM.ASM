;********** Bin2Num.Asm - accepts a binary string and returns an integer value

;Copyright (c) 1988 Ethan Winer


;Syntax: Value = Bin2Num%(X$)
;
;where X$ is in the form "10011001" up to 16 digits
;
;NOTE: No error checking is performed on the incoming string.  Though
;we could require you to pass an extra variable just to return an error
;code, we'll give you the beneift of the doubt and assume you know what
;you're doing.  (Please don't let us down!)  However, this routine will
;bail out if the incoming string is null, or longer than sixteen digits.
;In those cases, the value returned will be zero.  Characters that are
;not "1" are considered by Bin2Num to be "0".  Thus, "10T1" is the same
;as "1001" to Bin2Num.


.Model Medium
.Code
Include Mixed.Inc

HProc Bin2Num, XString:Ptr

    Mov  SI,XString      ;get the address for X$ descriptor
    Mov  CX,[SI]         ;get its length
    Mov  SI,[SI+02]      ;and the address of the digits in X$

    Xor  AX,AX           ;clear AX, we'll accumulate the value as we go
    Jcxz Exit            ;oops, they slipped us a null string, exit with 0
    Cmp  CX,16           ;is it longer than 16 digits?
    Ja   Exit            ;yes, get out

    Mov  DL,"1"          ;save time as we compare each digit below
    Mov  BX,1            ;make a bit to use when ORing AX
    Add  SI,CX           ;point just past the end of the string

More:
    Dec  SI              ;point to the previous character in X$
    Cmp  [SI],DL         ;is the current digit a 1?
    Jne  NoMatch         ;no, continue
    Or   AX,BX           ;yes, set the appropriate bit in AX

NoMatch:
    Shl  BX,1            ;shift the single bit in BX to the next position
    Loop More            ;cycle through each digit until done

Exit:
    HRet                 ;return to BASIC leaving the function output in AX


HEndp
End
