;----- AddUSI.Asm - adds two unsigned integers - BASIC can't without overflow

;Copyright (c) 1989 Ethan Winer
;BC7 version
;Syntax - X = AddUSI%(Int1%, Int2%)

.Model Medium, BASIC
.Code


AddUSI Proc
    Mov  CX,SI             ;save and restore SI
    Mov  SI,SP             ;put the stack pointer into SI
    Mov  BX,[SI+06]        ;get the address for Int1%
    Mov  AX,[BX]           ;put Int1% into AX
    Mov  BX,[SI+04]        ;get the address for Int2%
    Add  AX,[BX]           ;add it to Int1% in AX
    Mov  SI,CX             ;swap it back
    Ret  4                 ;return to BASIC leaving the function output in AX

AddUSI Endp
End
