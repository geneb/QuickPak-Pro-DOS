;********** COMPCY.ASM - compares two Currency variables

;Copyright (c) 1992 Ethan Winer


;On entry:
;     DS:SI   = pointer to first number
;     ES:DI   = pointer to second number
;
;On exit:
;     FLAGS   = set for comparative jump
;     Only CX and DX are preserved


.Model Medium, Basic
.Code

Comp_Cy Proc

    Mov  AX,[SI+06]     ;get the high word of the first value
    Cmp  AX,ES:[DI+06]  ;compare that to the high word of the second value
    Jne  Exit           ;they're different, and the flags are now correct

    Mov  AX,[SI+04]     ;get the next lower word of the first value
    Cmp  AX,ES:[DI+04]  ;compare that to the next lower word of second value
    Jne  Done           ;as above

    Mov  AX,[SI+02]
    Cmp  AX,ES:[DI+02]
    Jne  Done

    Mov  AX,[SI]
    Cmp  AX,ES:[DI]
    Je   Exit           ;they're equal, skip ahead and return with the flags
                        ;  set as they are
Done:
    Mov  AX,1           ;set AH = 0, AL = 1
    Ja   @F             ;Value1 is greater, generate a GT condition
    Xchg AH,AL          ;Value2 is greater, generate a LT condition
    
@@:
    Cmp  AL,AH          ;set the flags accordingly
    
Exit:
    Ret

Comp_Cy Endp
End
