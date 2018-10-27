;----- FileSize.Asm - retrieves the size of a file

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - FileName$ = "\Path\Filename.Ext"
;         Size = FileSize&(FileName$)
;         IF Size = -1 THEN PRINT "File doesn't exist."

;Errors are returned in DOS/WhichError.

.Model Medium, Basic
.Data

    Extrn QPDTA:Byte         ;these are in External.Asm
    Extrn File_Name:Byte

.Code
    Include Mixed.Inc
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    Extrn Load_File:Far, DOS:Far

HProc FileSize, FName:Ptr

    Mov  DX,CS               ;install CEH
    Lea  BX,CS:CEH_Ret
    Call Setup_CEH

    Lea  DX,QPDTA            ;put QPDTA address into DS:DX for set DTA service
    Mov  AH,1Ah              ;set DTA service - creates space for file info
    Call DOS                 ;call DOS

    Mov  SI,FName            ;SI holds address of FileName$ descriptor
    Call Load_File           ;create an ASCIIZ string
    Jc   ErrExit             ;quit if an error was detected

    Mov  CL,00100111b        ;have search include normal files, hidden files,
                             ;  system files, and archive files
    Mov  AH,4Eh              ;find first matching file service
    Call DOS                 ;call DOS
    Jc   ErrExit             ;if Carry is set it wasn't there

    Lea  DI,QPDTA            ;point DI to QPDTA for getting file size
    Mov  AX,[DI+26]          ;put low word of file size into AX
    Mov  DX,[DI+28]          ;put high word of file size into DX
    Jmp  Short Exit

ErrExit:
    Call Load_DOSErr         ;put up an error code

CEH_Ret:
    Mov  AX,-1               ;return -1
    Mov  DX,AX

Exit:
    Call Restore_CEH         ;restore the QuickBASIC critical error handler
    HRet

HEndp
End
