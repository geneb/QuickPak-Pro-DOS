;----- ArraySiz.Asm - calculates array size needed to save part of a screen

;Copyright (c) 1989 Ethan Winer
;BC7 version

;Syntax - DIM Array%(ArraySize%(ULRow%, ULCol%, LRRow%, LRCol%))
;
;formula: ArraySize% = (LRRow% - ULRow% + 1) * (LRCol% - ULCol% + 1)
;
;NOTE:  this includes an extra element in case OPTION BASE 1 is being used
;       if you use the zero element (and you actually care) subtract one

.Model Medium,BASIC
.Code

ArraySize Proc Uses SI,  ULRow:Ptr, ULCol:Ptr, LRRow:Ptr, LRCol:Ptr

    Mov  SI,LRRow         ;get the address for LRRow%
    Mov  AX,[SI]          ;put LRRow% into AX
    Mov  SI,ULRow         ;get the address for ULRow%
    Sub  AX,[SI]          ;subtract ULRow% from LRRow%
    Inc  AX               ;add one

    Mov  SI,LRCol         ;get the address for LRCol%
    Mov  BX,[SI]          ;put LRCol% into BX
    Mov  SI,ULCol         ;get the address for ULCol%
    Sub  BX,[SI]          ;subtract ULCol% from LRCol%
    Inc  BX               ;add one

    Mul  BL               ;do the multiplication (using BL is sufficient)
    Ret                   ;return to BASIC with the answer in AX

ArraySize Endp
End
