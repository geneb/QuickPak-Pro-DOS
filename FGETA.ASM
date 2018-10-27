;----- FGetA.Asm - reads a dynamic array from a binary file

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - CALL FGetA(Handle%, SEG Array(Start), NumBytes&)
;
;  where Handle% is the number DOS originally assigned when the file was
;  opened, Array(Start) is the array that will receive the being read,
;  and NumBytes& is the number of bytes to be read.  Note that NumBytes
;  can be either integer(%) or long integer(&).  Byte counts greater than
;  32K should be passed in a long integer parameter.  Errors are returned
;  in DOS/WhichError.

.Model Medium, Basic
.Code
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far, DOS:Far

FGetA Proc Uses DS SI DI, Handle:Ptr, Array:DWord, NumBytes:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Push DS               ;save DS before we trash it below
    Mov  SI,Handle        ;get the address for Handle%
    Mov  BX,[SI]          ;and put it into BX
    Mov  SI,NumBytes      ;get the address for NumBytes&
    Mov  CX,[SI]          ;put it into CX
    Lds  DX,Array         ;load DS:DX with the address of Array(Start)

    Mov  AX,27            ;assume they asked for zero words
    Jcxz ErrExit          ;they DID - exit now with an error

    Mov  AH,3Fh           ;specify Read service
    Call DOS              ;call DOS
    Jc   ErrExit          ;oops, found an error

    Cmp  AX,CX            ;check for read past end
    Je   Exit             ;if AX = CX, then we got a full load
    Mov  AX,23            ;else, DOS says we passed the EOF

ErrExit:
    Call Load_DOSErr

Exit:
    Pop  DS               ;get DS back again
    Call Restore_CEH      ;restore the QuickBASIC critical error handler
    Ret                   ;return to BASIC

FGetA Endp
End
