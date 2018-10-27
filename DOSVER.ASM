;----- DosVer.Asm - retrieves the current DOS version number from within BASIC

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - Version = DosVer%
;
;  where Version receives the DOS version number * 100
;  Example: if DOS version = 3.10 then Version = 310


.Model Medium, Basic
.Code
    Extrn Load_DOSErr:Far

DosVer Proc

    Xor  AX,AX
    Call Load_DOSErr

    Mov  AH,30h       ;get DOS version service through DOS
    Int  21h          ;major version returns in AL, minor in AH
    Push AX           ;save minor version number for later
    Mov  CL,100       ;prepare to multiply AL * 100
    Mul  CL           ;AX = AL * CL

    Pop  BX           ;retrieve minor version
    Mov  BL,BH        ;get ready to add it to major version number
    Xor  BH,BH        ;zero out BH
    Add  AX,BX        ;add major and minor parts
    Ret

DosVer Endp
End
