;BlinkOn and Off
;Turn flashing colors off (and bright background on) on an 
;EGA and VGA
;By Jay Munro

.Model Medium, BASIC
.Code

BlinkOn Proc
    Mov BL,1
    Mov AX,1003h
    Int 10h
    Ret
BlinkOn Endp

BlinkOff Proc
    Xor BL,BL
    Mov AX,1003h
    Int 10h
    Ret
BlinkOff EndP

End
