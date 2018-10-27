;********** CompDp.Asm - compares double precision reals
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

COMP_DP         PROC

                MOV     BP,CX
                PUSH    SI
                PUSH    DI
                PUSH    DX
                PUSH    DS
                PUSH    ES

                MOV     AX,DS:[SI+6]            ;Get arg1
                MOV     BX,ES:[DI+6]            ;Get arg2

                OR      AX,AX                   ;Test sgn of arg1
                JNS     CDP_0                   ; Jmp if +
                                                ;Arg1 is -
                OR      BX,BX                   ;Test sgn of arg2
                JS      CDP_1                   ; Jmp if - also
                                                ;Different signs
                CMP     AX,BX                   ; do signed compare
                JMP     SHORT CDP_5             ; return with flags
CDP_0:
                OR      BX,BX                   ;Test sgn of arg2
                JNS     CDP_2                   ; jump if -

                                                ;Different signs
                CMP     AX,BX                   ; do signed compare
                JMP     SHORT CDP_5             ; return with flags

;----------------------------------------------------------------------
;  Both args are the same sign, positive or negative.
;----------------------------------------------------------------------
CDP_1:
                XCHG    SI,DI                   ;reverse the pointers
                MOV     CX,DS                   ; the segments
                MOV     DX,ES                   ; (moves = 8 clocks
                MOV     DS,DX                   ;  push/pop = 36)
                MOV     ES,CX
                XCHG    AX,BX                   ; and most signif part
CDP_2:
                CMP     AX,BX                   ;Compare hi order values
                JNE     CDP_3                   ; if not =, compare done

                MOV     CX,DS:[SI+4]            ;get next part of args
                MOV     DX,ES:[DI+4]

                CMP     CX,DX                   ;Compare 2nd word
                JNE     CDP_3                   ;If not eq, test is done

;  Continue compare with low halfs

                MOV     AX,DS:[SI+2]
                MOV     BX,ES:[DI+2]

                CMP     AX,BX                   ;Compare 3rd word
                JNE     CDP_3

                MOV     CX,DS:[SI]              ;Retrieve lo words
                MOV     DX,ES:[DI]
                CMP     CX,DX                   ;Compare lo word
                JE      CDP_5
CDP_3:
                MOV     AH,0                    ;Load dummy values
                MOV     AL,1                    ; used to set flags
                JA      CDP_4                   ;Jump if unsigned GT
                CMP     AH,AL                   ;Generate LT
                JMP     SHORT CDP_5
CDP_4:
                CMP     AL,AH                   ;Generate GT
CDP_5:
                POP     ES
                POP     DS
                POP     DX
                POP     DI
                POP     SI
                MOV     CX,BP
                RET

COMP_DP         ENDP
END
