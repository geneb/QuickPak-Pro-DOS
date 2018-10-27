;----- FClose.Asm - closes a file that was previously opened for binary access

;Copyright (c) 1987 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - Call FClose(Handle%)
;
;  where Handle% is the number DOS originally assigned when the file was
;  opened.  Errors are returned in DOS/WhichError.
;
;  FClose does not permit file handles 0 thru 4 to be closed.  These handles
;  are preassigned by DOS for standard I/O.  Although these handles can be
;  closed, some pretty bizaare things may result such as a dead keyboard.
;  If this is what you want to do, just remove the marked lines and
;  reassemble this file.

.Model Medium, Basic
.Code
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far, DOS:Far

FClose Proc, Handle:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:Okay
    Call Setup_CEH

    Mov  BX,Handle        ;get the address for Handle%
    Mov  BX,[BX]          ;and put it into BX

    Cmp  BX,4             ;*** don't close the standard I/O
    Ja   Do_Close         ;*** remove these four lines if you
    Mov  AX,6             ;*** want to lock the keyboard, etc
    Jmp  Short Err_Exit   ;***

Do_Close:
    Mov  AH,3Eh           ;specify Close service
    Call DOS              ;call DOS
    Jnc  Okay             ;if NOT CF then file was successfully closed

Err_Exit:
    Call Load_DOSErr      ;else put up an error code

Okay:
    Call Restore_CEH      ;restore QuickBASIC's critical error handler
    Ret                   ;return to BASIC

FClose Endp
End
