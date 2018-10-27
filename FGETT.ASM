;----- FGetT.Asm - gets bytes from a binary file into a TYPE variable

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - CALL FGetT(Handle%, Dest, NumBytes%)
;
;Alternate syntax for fixed-length strings:
;
;         CALL FGetT(Handle%, BYVAL VARPTR(Dest), NumBytes%)
;
;  Where Handle% is the number DOS originally assigned when the file was
;  opened, Dest is the destination variable that will receive the data,
;  and NumBytes% is the number of bytes to read.  Errors are returned in
;  DOS/WhichError.

.Model Medium, Basic
.Code
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far, DOS:Far

FGetT Proc Uses DI SI, Handle:Ptr, Dest:Ptr, NumBytes:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Mov  BX,Handle        ;get the address for Handle%
    Mov  BX,[BX]          ;and put it into BX
    Mov  DX,Dest          ;get the address for Dest
    Mov  SI,NumBytes      ;get the address for NumBytes%
    Mov  CX,[SI]          ;put it into CX

    Mov  AX,27            ;assume they asked for zero bytes
    Jcxz ErrExit          ;they DID - exit now with an error

    Mov  AH,3Fh           ;specify Read service
    Call DOS              ;call DOS
    Jc   ErrExit          ;oops, caught an error

    Cmp  AX,CX            ;check for EOF
    Je   Exit             ;no error, just exit
    Mov  AX,23            ;set the "input past end" error

ErrExit:
    Call Load_DOSErr      ;put up an error code

Exit:
    Call Restore_CEH      ;restore the QuickBASIC critical error handler
    Ret                   ;return to BASIC

FGetT Endp
End
