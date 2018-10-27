;----- CapsOff.Asm - turns off the CapsLock key

;Written by Jay Munro
;Copyright (c) 1989 Crescent Software
;BC7 version

.Model Medium,BASIC
.Code

CapsOff Proc Uses ES

    Xor  BX,BX                   ;get at the Shift status byte in low memory
    Mov  ES,BX                   ;through ES
    And  Byte Ptr ES:[417h],0BFh ;set the Caps Lock bit at address 0:0417h
    Ret                          ;return to calling program

CapsOff Endp
End
