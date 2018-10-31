;********** CompLi.Asm - compares long integers (32-bit)
;
;  Copyright (c) 1988 Schaefer Software
;
;  On entry:
;       DS:SI   = pointer to first number
;       ES:DI   = pointer to second number
;
;  On exit:
;       FLAGS   = set for comparative jump
;       Destroyed: BP, AX, BX
;
;  Assumptions:
;       Neither element crosses a segment boundry


.Model Medium,BASIC
.Code

COMP_LI         PROC

                MOV     BP,CX                   ;save CX in BP
                PUSH    DX

                MOV     AX,DS:[SI+2]            ;Get arg1
                MOV     BX,ES:[DI+2]            ;Get arg2

                OR      AX,AX                   ;Test sgn of arg1
                JNS     CLI_0                   ; Jmp if +
                                                ;Arg1 is -
                OR      BX,BX                   ;Test sgn of arg2
                JS      CLI_1                   ; Jmp if - also
                                                ;Different signs
                CMP     AX,BX                   ; do signed compare
                JMP     SHORT   CLI_5           ; return with flags
CLI_0:
                OR      BX,BX                   ;Test sgn of arg2
                JNS     CLI_1                   ; jump if -
                                                ;Different signs
                CMP     AX,BX                   ; do signed compare
                JMP     SHORT   CLI_5           ; return with flags
CLI_1:
;----------------------------------------------------------------------
;  Both args are the same sign, positive or negative.
;----------------------------------------------------------------------
                CMP     AX,BX                   ;Compare hi order values
                JNE     CLI_3                   ; if not =, compare done

                MOV     CX,DS:[SI]              ;get next part of args
                MOV     DX,ES:[DI]

                CMP     CX,DX                   ;Compare 2nd word
                JE      CLI_5                   ; return with flags
CLI_3:
                MOV     AH,0                    ;Load dummy values
                MOV     AL,1                    ; used to set flags
                JA      CLI_4                   ;Jump if unsigned GT
                CMP     AH,AL                   ;Generate LT
                JMP     SHORT CLI_5
CLI_4:
                CMP     AL,AH                   ;Generate GT
CLI_5:
                POP     DX                      ;restore DX and CX
                MOV     CX,BP
                RET

COMP_LI         ENDP
END
