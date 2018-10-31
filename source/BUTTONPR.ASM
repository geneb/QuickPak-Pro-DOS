;----- ButtonPR.Asm

;Copyright (c) 1988 Ethan Winer
; BC7 version

;Syntax - CALL ButtonPress(Button%, Status%, Count%, X%, Y%)
;       Button is the button of interest (1, 2, or 3)
;       Status returns bit-coded and is the same as for GetCursor
;       Count is how many times the specified button was pressed since
;         ButtonPress was last called
;       X and Y tell where the cursor was the last time the button was pressed


.Model Medium,BASIC
.Data

    Extrn MouseThere:Byte ;this byte is in InitMous.Asm

.Code

ButtonPress Proc Uses SI,  Button:Ptr, Status:Ptr, Count:Ptr, X:Ptr, Y:Ptr

    Xor  AX,AX            ;assume no mouse is installed
    Mov  BX,AX            ;clear all registers in case it's true
    Mov  CX,AX            ;this will assign all output variables to zero later
    Mov  DX,AX
                          ;now see if the mouse is really installed
    Cmp  Byte Ptr MouseThere,0
    Jz   NoMouse          ;no mouse interrupt installed, so assign all zeros

    Mov  AX,5             ;service 5
    Mov  SI,Button
    Mov  BX,[SI]          ;put the button number into BX
    Dec  BX               ;adjust 1-3 to 0-2
    Int  51

NoMouse:
    Mov  SI,Status        ;assign the output variables
    Mov  [SI],AX
    Mov  SI,Count
    Mov  [SI],BX
    Mov  SI,X
    Mov  [SI],CX
    Mov  SI,Y
    Mov  [SI],DX
    Ret                   ;return to BASIC

ButtonPress Endp
End
