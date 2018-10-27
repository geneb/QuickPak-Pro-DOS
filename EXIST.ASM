;----- Exist.Asm - determines if the named file or file spec is present

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - There = Exist%(FSpec$)
;
;  where FSpec$ holds the file specification, and There tells if it
;  was there or not.

;Further information is available in DOS/WhichError


.Model Medium, Basic
.Data

    Extrn QPDTA:Byte      ;these are in External.Asm
    Extrn File_Name:Byte

.Code
    Include Mixed.Inc
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    Extrn Load_File:Far, DOS:Far

HProc Exist, FSpec:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:CEH_Ret
    Call Setup_CEH

    Lea  DX,QPDTA         ;put address of QPDTA into DS:DX for set DTA service
    Mov  AH,1Ah           ;set DTA service - creates space for the file names
    Call DOS

    Xor  BX,BX            ;assume no matching files for now
    Mov  SI,FSpec         ;SI holds address of FSpec$ descriptor
    Call Load_File        ;create an ASCIIZ string
    Jc   ErrExit          ;quit if an error was detected

    Mov  CX,00100111b     ;and put the attribute for files into CX
    Mov  AH,4Eh           ;find first matching file name service
    Call DOS              ;call DOS
    Mov  BX,-1            ;assume TRUE is valid
    Jnc  Exit             ;we were right, it's there

ErrExit:
    Cmp  AX,2             ;was it file not found?
    Je   CEH_Ret          ;yes, don't set DOSError or WhichError
    Call Load_DOSErr      ;no, put up an error code

CEH_Ret:
    Xor  BX,BX            ;return FALSE

Exit:
    Call Restore_CEH      ;restore the QuickBASIC critical error handler
    Mov  AX,BX
    HRet

HEndp
End
