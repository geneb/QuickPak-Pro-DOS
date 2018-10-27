;********** CtrlKey.Asm - returns whether or not a Ctrl key is depressed

;Copyright (c) 1989 Ethan Winer

;Syntax - IF CtrlKey% THEN . . .   'the Ctrl key is pressed


.Model Medium,BASIC
.Code

CtrlKey Proc Uses ES

    Xor  AX,AX            ;look at the Shift Status byte in low memory
    Mov  ES,AX
    Test Byte Ptr ES:[417h],00000100b   ;test the Ctrl Key bit
    Jz   Exit             ;it's not active, exit with AX holding zero
    Dec  AX               ;set AX to -1

Exit:
    Ret                   ;return to BASIC

CtrlKey Endp
End
