;********** CapsLock.Asm - returns the status of the Caps Lock key

;Copyright (c) 1988 Ethan Winer

;Syntax - IF CapsLock% THEN . . . 'Caps Lock key is active


.Model Medium,BASIC
.Code

CapsLock Proc Uses ES

    Xor  AX,AX            ;look at the Shift Status byte in low memory
    Mov  ES,AX
    Test Byte Ptr ES:[417h],01000000b     ;test the Caps Lock bit
    Jz   Exit             ;it's not active, exit with AX set to zero
    Dec  AX               ;set AX to -1

Exit:
    Ret                   ;return to BASIC

CapsLock Endp
End
