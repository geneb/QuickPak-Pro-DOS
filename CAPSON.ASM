;----- CapsOn.Asm - turns on the CapsLock key

;Written by Jay Munro
;Copyright (c) 1988 Crescent Software
;BC7 version

.Model Medium,BASIC
.Code

CapsOn Proc Uses ES

    Xor  BX,BX                   ;get at the Shift status byte in low memory
    Mov  ES,BX                   ;through ES
    Or   Byte Ptr ES:[417h],40h  ;set the Caps Lock bit at address 0:0417h
    Ret                          ;return to calling program

CapsOn Endp
End
