;------ FEof.Asm - pretest for End of File (EOF)

;Copyright (c) 1989 J. R. Conrad


;  Syntax: WHILE NOT FEof%(Handle%)         Better: WHILE NOT DOSError%
;             CALL FGet(Handle%, Dest$)                CALL anything(Handle%)
;          WEND                                     WEND
;
;  Where Handle% is the number DOS originally assigned when the file was
;  opened.  Errors are returned in DOS/WhichError.
;
;  FEof is not all that useful.  Since the file I/O procedures automatically
;  check for Eof, the DOSError method is more efficient and faster.

.Model Medium, Basic
.Data
    Extrn QPDTA:Byte         ;use the external DTA as a buffer

.Code
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far, DOS:Far

FEof Proc  Handle:Ptr

    Mov  DX,CS               ;install CEH
    Lea  BX,CS:CEH_Ret
    Call Setup_CEH

    Mov  BX,Handle           ;get the address of Handle%
    Mov  BX,[BX]             ;so we can put the handle in BX
    Lea  DX,QPDTA            ;point DX to the DTA
    Mov  AH,3FH              ;ask DOS to
    Mov  CX,1                ;read one byte
    Call DOS
    Jc   ErrExit             ;probably a bad file handle

    Mov  DX,-1               ;assume EOF (-1 = TRUE)
    Or   AX,AX               ;did we get a byte of data?
    Jz   Exit                ;if AX = 0, then we guessed right

    Mov  CX,DX               ;CX:DX = -1
    Mov  AX,4201h            ;ask DOS to move the pointer back one byte
    Call DOS
    Xor  DX,DX               ;put zero in DX (0 = FALSE)
    Jmp  Short Exit          ;and say goodbye

ErrExit:
    Call Load_DOSErr         ;translate the error code

CEH_Ret:
    Mov  DX,-1               ;on error, return FEOF = TRUE

Exit:
    Call Restore_CEH         ;restore BASIC's critical error handler
    Mov  AX,DX               ;put the return value in AX
    Ret                      ;return to BASIC

FEof Endp
End
