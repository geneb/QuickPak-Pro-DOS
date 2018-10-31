;----- ENum2Dat.Asm - calls Num2Date, provides a front-end for European dates

;Copyright (c) 1988 Ethan Winer


;syntax - Dat$ = ENum2Date$(Number%)
;
;   where Number% is the number of days before/after 31-Dec-1979, and
;   Dat$ receives the date string in the form MM-DD-YYYY
;   if Number% is illegal, Dat$ instead receives a string of percent signs

.Model Medium
.Code
    Extrn Num2Date: Proc  ;we'll let Num2Date do the hard part
    Extrn EuroSwap:Proc   ;this is in EuroSwap.Asm

Include Mixed.Inc

HProc ENum2Date, Number:Ptr

    Mov  SI,Number        ;get the address for Number%
    Push SI               ;show Num2Date where it is
    Call Num2Date         ;Num2Date returns the string address in AX
    Mov  SI,AX            ;put the descriptor address in SI
    Cmp  Word Ptr [SI],0  ;did Num2Date return a null string as an error?
    Je   Exit             ;yes, exit with AX pointing to the null descriptor
    Mov  DI,[SI+02]       ;no, point DI to the string data
    Call EuroSwap         ;swap the month and day digits to European format

Exit:
    HRet                  ;return to BASIC

HEndp
End
