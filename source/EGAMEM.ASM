;---------- EGAMem.Asm - report the number of 64K banks in an EGA
;
;Copyright (c) 1988 Ethan Winer
;
;Calling syntax -
;
;   Memory = EGAMem%
;
;where Memory is set to 0 if there's no EGA installed, or 1-4 to indicate
;the number of 64K banks installed


.Model Medium,BASIC
.Code

EGAMem Proc

    Mov  AH,12h               ;ask for EGA info
    Mov  BL,10h
    Push BP
    Int  10h
    Pop  BP
    Cmp  BL,10h               ;BL will still hold 10h if it's not an EGA
    Mov  AX,0                 ;assume it's not an EGA for the moment
    Jz   NotEGA               ;we were right, it's not
    Mov  AL,BL                ;it is an EGA, put the number of banks into AL
    Inc  AL                   ;adjust 0-3 to 1-4

NotEGA:
    Ret

EGAMem Endp
End
