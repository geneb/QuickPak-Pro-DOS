;----- FCreate.Asm

;creates/truncates a file in preparation for binary file access from BASIC

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - CALL FCreate(FileName$)
;
;where FileName$ holds the file name to create.
;Errors are returned in DOS/WhichError.
;
;Important Note: FCreate only handles the creation or truncation of the
;                requested file.  Before FCreate returns, the file is closed.
;                If you wish to perform any I/O operations on the created file,
;                you must reopen with FOpen and close with FClose.

.Model Medium, Basic

.Data
    Extrn File_Name:Byte  ;this is in the file External.Asm

.Code
    Include Mixed.Inc
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    Extrn Create_Err:Far, DOS:Far, Load_File:Far

HProc FCreate, FName:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Mov  SI,FName         ;SI holds address of FileName$ descriptor
    Call Load_File        ;copy FName to the File_Name buffer
    Jc   ErrExit          ;carry means the name was null or too long

    Mov  AH,3Ch           ;specify Create File service
    Mov  CL,32            ;create a normal "archive" file
    Call DOS              ;call DOS
    Jnc  CloseFile        ;if not carry, then close the file and exit
    Call Create_Err       ;else, cook the error code
    Jmp  Short ErrExit    ;and exit with error

CloseFile:
    Mov  BX,AX            ;move the file handle into BX
    Mov  AH,3Eh           ;we must close the file
    Call DOS              ;let DOS do it
    Jmp  Short Exit       ;and skip over the error stuff

ErrExit:
    Call Load_DOSErr

Exit:
    Call Restore_CEH      ;restore QuickBASIC's critical error handler
    HRet                  ;return to BASIC

HEndp
End
