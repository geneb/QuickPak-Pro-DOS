;----- CDir.Asm - CHDIR substitute that traps errors

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - CALL CDir(NewDir$)

;Errors are returned in DOS/WhichError

.Model Medium, Basic
.Data

    Extrn File_Name:Byte  ;this is in External.Asm

.Code
    Include Mixed.Inc
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    Extrn Load_File:Far, DOS:Far
    
HProc CDir, NewDir:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Mov  SI,NewDir        ;SI holds address of NewDir$ descriptor
    Call Load_File        ;transfer the filename string
    Jc   ErrExit          ;if carry, then an error was detected

    Mov  AH,3Bh           ;DOS change directory service
    Call DOS              ;call DOS to do it
    Jnc  Exit             ;if not carry, no error

ErrExit:
    Call Load_DOSErr      ;translate the error code

Exit:
    Call Restore_CEH      ;restore the QuickBASIC critical error handler
    HRet                  ;return to BASIC

HEndp
End
