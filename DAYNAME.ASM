;********** DayName.Asm - converts an integer Day into a string day name

;Copyright (c) 1988 Ethan Winer


;syntax - Day$ = DayName$(Day%)
;
;where Day$ will receive "Sun", "Mon", "Tue", and so forth


.Model Medium
.Data
    Descriptor DW 0, 0                     ;this is the function's descriptor
    DayNames   DB "SunMonTueWedThuFriSat"  ;the table of day names

.Code
Include Mixed.Inc
HProc DayName, Day:Ptr

    Mov  SI,Day           ;get the address for Day%
    Mov  AL,[SI]          ;put it into AL
    Dec  AL               ;adjust 1-7 to 0-6
    Xor  CX,CX            ;assume a length of zero in case of an illegal day

    Lea  SI,Descriptor    ;put the descriptor address into SI
    Mov  DI,SI            ;and into DI too
    Add  DI,4             ;adjust DI to point to the day names table

    Cmp  AL,6             ;is the day number greater than 7 or less than 1?
    Ja   Exit             ;yes (boy, some people aren't very smart are they?)

    Mov  CL,3             ;prepare to calculate the offset into the name table
    Mul  CL               ;now AX holds the starting offset into DayNames
    Add  DI,AX            ;and now DI holds the complete address

Exit:
    Mov  [SI],CX          ;assign the string length into the descriptor
    Mov  [SI+02],DI       ;and the address part
    Mov  AX,SI            ;show BASIC where the descriptor is located
    HRet                  ;return to BASIC

HEndp
End
