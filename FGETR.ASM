;----- FGetR.Asm - reads bytes from a random binary file to a string variable

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - CALL FGetR(Handle%, Dest$, RecNo&)

;  Where Handle% is the number DOS originally assigned when the file was
;  opened, Dest$ is the destination string to receive the data record,
;  (its length determines the number of bytes to read), and RecNo& is the
;  record number.  Errors are returned in DOS/WhichError.

.Model Medium, Basic
.Code
    Include Mixed.Inc
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far, DOS:Far

HProc FGetR, Handle:Ptr, Dest:Ptr, RecNo:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Mov  SI,RecNo         ;get the address for RecNo&
    Mov  AX,[SI]          ;put the low word into AX

    Mov  DI,Dest          ;get the address for Dest$
    Mov  CX,[DI]          ;get LEN(Dest$)
    Or   CX,CX            ;is it a null string?
    Jnz  Okay             ;no, continue

    Mov  AX,27            ;else report "buffer too small"
    Jmp  Short ErrExit    ;and exit

Okay:
    Mul  CX               ;no error, so first multiply the low part of RecNo&
    Mov  BX,AX            ;save the low part of the result in BX
    Mov  CX,DX            ;and save the high part of the result in CX

    Mov  AX,[SI+02]       ;now get the high word of RecNo&
    Mul  Word Ptr [DI]    ;and multiply that times LEN(Dest$)
    Add  CX,AX            ;now CX:BX holds the result
    Mov  DX,BX            ;put the low part into DX for the DOS Seek below
    Sub  DX,[DI]          ;adjust so record 1/byte 1 is at offset 0 by
    Sbb  CX,0             ;  subtracting the length of a record from CX:DX

    Mov  BX,Handle        ;get the address for Handle%
    Mov  BX,[BX]          ;and put it into BX

    Mov  AX,4200h         ;ask to seek CX:DX bytes into the file
    Call DOS              ;call DOS to do it
    Jc   ErrExit          ;oops, caught an error

    Mov  DX,[DI+02]       ;no error, so get the address for Dest$'s data
    Mov  CX,[DI]          ;and put LEN(Dest$) into CX to tell how many bytes
    Mov  AH,3Fh           ;specify Read service
    Call DOS              ;call DOS
    Jc   ErrExit
    
    Cmp  AX,CX            ;check for EOF
    Je   Exit
    Mov  AX,23

ErrExit:
    Call Load_DOSErr      ;put up an error code

Exit:
    Call Restore_CEH      ;restore the QuickBASIC critical error handler
    HRet                  ;return to BASIC

HEndp
End
