;********* CsrSize.Asm - returns the top and bottom cursor scan lines

;Copyright (c) 1989 Ethan Winer
;BC7 version JM '89

;Syntax - CALL CsrSize(Top%, Bottom%)

.Model Medium,BASIC
.Code

CsrSize Proc Uses SI, Top:Ptr, Bottom:Ptr

    Mov  AH,3             ;video service 3 gets the cursor size and location
    Xor  BH,BH            ;for page zero
    Push BP               ;save BP from old bios trashing
    Int  10h              ;call the video BIOS
    Pop  BP
    Mov  SI,Top           ;get the address for Top%
    Mov  BL,CH            ;now BX = starting scan line
    Mov  [SI],BX          ;assign it to Top%
    Mov  SI,Bottom        ;get the address for Bottom%
    Mov  BL,CL            ;now BX = ending scan line
    Mov  [SI],BX          ;assign it to Bottom%
    Ret                   ;return to BASIC

CSRSize Endp
End
