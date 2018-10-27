;********* ClearBuf.Asm - clears the keyboard buffer

;Copyright (c) 1988 Ethan Winer


;calling syntax - CALL ClearBuf


.Model Medium,BASIC
.Code

ClearBuf Proc Uses ES DI

    Xor  BX,BX          ;address the keyboard buffer in low memory
    Mov  ES,BX          ;ES = 0
    Mov  DI,41Ah        ;set DI to address the buffer pointer
    Mov  AX,1Eh         ;establish the buffer head to be 41Eh
                        ;  ( + 400h is assumed meaning 1Eh = 41Eh)
    Cli                 ;disable interrupts until we're all done
    Stosw               ;set the head to 41Eh and point to buffer tail
    Stosw               ;now set the tail to the same address
    Sti                 ;re-enable interrupts

Exit:
    Ret                 ;back to BASIC

ClearBuf Endp
End
