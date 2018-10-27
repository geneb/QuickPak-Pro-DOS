;----- FGetRT.Asm - reads bytes from a random binary file into a TYPE variable

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - CALL FGetRT(Handle%, Dest, RecNo&, RecSize%)
;
;Alternate syntax for fixed-length strings:
;
;         CALL FGetRT(Handle%, BYVAL VARSEG(Dest), BYVAL VARPTR(Dest), _
;              RecNo&, RecSize%)
;
;  Where Handle% is the number DOS originally assigned when the file was
;  opened, Dest is the destination variable that will receive the data,
;  RecNo% is the record number, and RecSize% is the number of bytes to
;  be read.  Errors are returned in DOS/WhichError.

.Model Medium, Basic
.Code
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far, DOS:Far

FGetRT Proc Uses SI DI, Handle:Ptr, Dest:Ptr, RecNo:Ptr, RecSize:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Mov  DI,RecSize       ;get the address for RecSize%
    Cmp  Word Ptr [DI],0  ;did they foolishly specify zero bytes?
    Mov  AX,27            ;assume they did for the moment
    Je   ErrExit          ;we were right, get out and show the error

    Mov  SI,RecNo         ;get the address for RecNo&
    Mov  AX,[SI]          ;put the low word into AX

    Mul  Word Ptr [DI]    ;first multiply the low part of RecNo& by RecSize%
    Mov  BX,AX            ;save the low part of the result in BX
    Mov  CX,DX            ;and save the high part of the result in CX

    Mov  AX,[SI+02]       ;now get the high word of RecNo&
    Mul  Word Ptr [DI]    ;and multiply that times RecSize%
    Add  CX,AX            ;now CX:BX holds the result
    Mov  DX,BX            ;put the low part into DX for the DOS Seek below
    Sub  DX,[DI]          ;adjust so record 1/byte 1 is at offset 0 by
    Sbb  CX,0             ;  subtracting the length of a record from CX:DX

    Mov  BX,Handle        ;get the address for Handle%
    Mov  BX,[BX]          ;and put it into BX

    Mov  AX,4200h         ;ask to seek CX:DX bytes into the file
    Call DOS              ;call DOS to do it
    Jc   ErrExit          ;woops, caught an error

    Mov  DX,Dest          ;no error, so get the address for Dest
    Mov  CX,[DI]          ;and put RecSize% into CX to tell how many bytes
    Mov  AH,3Fh           ;specify Read service
    Call DOS              ;call DOS
    Jc   ErrExit          ;yet another error

    Cmp  AX,CX            ;check for EOF
    Je   Exit             ;no EOF error, just exit
    Mov  AX,23            ;set "input past end" error

ErrExit:
    Call Load_DOSErr      ;put up an error code

Exit:
    Call Restore_CEH      ;restore the QuickBASIC critical error handler
    Ret                   ;return to BASIC

FGetRT Endp
End
