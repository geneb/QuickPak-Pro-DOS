;*********** COMPI.ASM

;Copyright 1990 Crescent Software
;Internal routine for SearchT, SearchT2
.Model Medium,BASIC

.Code
;======================================================================
;  COMP_I - Compare Integers (16-bit)
;  On entry:
;       DS:SI   = pointer to first number
;       ES:DI   = pointer to second number
;  On exit:
;       FLAGS   = set for comparative jump
;       All registers preserved except AX
;----------------------------------------------------------------------
COMP_I       PROC  Far

                Mov     AX,[SI]
                Cmp     AX,ES:[DI]
                RET

COMP_I       ENDP
End
