;----- Code2Num.Asm - converts negative element size code to number of bytes

;Copyright (c) 1989 Ethan Winer
;CY BC7 version J.Munro 5/90 (fixed by Ethan 5-10-92 <g>)
;
;This is an internal routine used by several of the QuickPak Professional
;array routines.  It is called with the number of bytes or a negative size
;code in CX, and returns with the correct number of bytes.  Valid size
;codes are -1 (2-byte integer), -2 (4-byte long integer), -3 (4-byte single
;precision), -4 (8-byte double precision) , and -5 (8-byte currency).
;Any other negative value will be set to 0 bytes.

.Model Medium, Basic
.Code

Code2Num Proc Uses DI

    Or   CX,CX            ;is it a negative size code?
    Jns  Exit             ;no, so don't do anything
    Neg  CX               ;yes, convert to positive value for table lookup
    Dec  CX               ;adjust 1-5 to 0-4 to search table below

    Cmp  CX,5             ;is it a legal code (0 through 5)?
    Jb   GoodCode         ;yes, continue
    Xor  CX,CX            ;no, zero out CX to show the error
    Jmp  Short Exit       ;and get out

GoodCode:
    Lea  DI,CodeTable     ;load DI with the starting address of the table
    Shl  CX,1             ;convert offset in CX from bytes to words
    Add  DI,CX            ;now DI points to the correct table entry
    Mov  CX,CS:[DI]       ;and now CX holds the appropriate number of bytes

Exit:
    Ret                   ;return to the caller

Code2Num Endp

CodeTable DW 2, 4, 4, 8, 8

End
