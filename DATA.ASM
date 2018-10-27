;Data.Asm - stores data in the Code Segment

;Copyright (c) 1988 Ethan Winer

.Model Medium
.Code

Public QPGetAdr1
Public QPGetAdr2
Public QPGetAdrI
Public QPGetLen1
Public QPGetLen2
Public QPGetLenI
Public QPGetCS

String1 DB "This is the first of two strings that are being"
        DB " stored within the Code Segment."
Length1 DW $ - Offset String1

String2 DB "This is the second string we have stored."
Length2 DW $ - Offset String2

IArray  DW 12, 103, 32445, -8, 17, 567, -900
LengthI DW ($ - Offset IArray) / 2

QPGetAdr1 Proc Far
    Lea AX,String1
    Ret
QPGetAdr1 Endp

QPGetLen1 Proc Far
    Mov AX, Length1
    Ret
QPGetLen1 Endp

QPGetAdr2 Proc Far
    Lea AX, String2
    Ret
QPGetAdr2 Endp

QPGetLen2 Proc Far
    Mov AX,Length2
    Ret
QPGetLen2 Endp

QPGetAdrI Proc Far
    Lea AX,IArray
    Ret
QPGetAdrI Endp

QPGetLenI Proc Far
    Mov AX,LengthI
    Ret
QPGetLenI Endp

QPGetCS   Proc Far
    Mov AX,CS
    Ret
QPGetCS   Endp

End
