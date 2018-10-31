;********* CompareT.Asm - compares two TYPE variables

;Copyright (c) 1988 Ethan Winer
;BC7 conversion JM '89

;Syntax -
;
;   X = CompareT%(SEG Type1, SEG Type2, NumBytes%)
;
;where X receives -1 if the two type variables are the same or 0 if they
;are not, and NumBytes% indicates the length of the variables.


.Model Medium,BASIC
.Code

CompareT Proc  Uses DS ES DI SI, Type1:DWord, Type2:DWord, NumBytes:Ptr

    Cld                   ;compare in the forward direction

    Mov  SI,NumBytes      ;get the address for NumBytes%
    Mov  CX,[SI]          ;put it in CX for comparing below

    Les  DI,Type1         ;load ES:DI with the address of Type1
    Lds  SI,Type2         ;load DS:SI with the address of Type2

    Repe Cmpsb            ;do the compare
    Mov  AX,0             ;assume the bytes didn't match
    Jne  Exit             ;we were right, skip over
    Dec  AX               ;wrong RAM breath, decrement AX down to -1

Exit:
    Ret                   ;return to BASIC

CompareT Endp
End
