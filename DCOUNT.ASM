 ;----- DCount.Asm - counts the number of directories that match a spec

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - Count = DCount%(DirSpec$)
;
;  where DirSpec$ holds the directory specification (ie: \Path\*.*),
;  and Count is assigned the number of directories that match.  Errors
;  are returned in DOS/WhichError.


.Model Medium, Basic
.Data

    Extrn QPDTA:Byte      ;these are in External.Asm
    Extrn File_Name:Byte

.Code
    Include Mixed.Inc
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    Extrn Load_File:Far, DOS:Far

HProc DCount, Spec:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:CEH_Ret
    Call Setup_CEH

    Lea  DX,QPDTA         ;put address of QPDTA into DS:DX for set DTA service
    Mov  AH,1Ah           ;set DTA service - creates space for the file names
    Call DOS

    Xor  BX,BX            ;assume no matching files for now
    Mov  SI,Spec          ;SI holds address of DirSpec$ descriptor
    Call Load_File        ;create an ASCIIZ string
    Jc   ErrExit          ;quit if an error was detected

    Mov  CX,00010011b     ;the attribute for directory (+ read-only/hidden)
    Mov  AH,4Eh           ;find first matching file name service
    Call DOS              ;call DOS
    Jnc  Count_File       ;no errors, skip ahead

    Cmp  AX,2             ;an error, but was it merely "file not found"?
    Je   CEH_Ret          ;yes, and that's no big deal
    Cmp  AX,12            ;was it "no more files"?
    Je   CEH_Ret          ;yes, and that's okay too
    Jmp  Short ErrExit    ;no, so translate the error code and set WhichError

Count_File:
    Test Byte Ptr [QPDTA+21],10000b ;did we in fact just read a directory?
    Jz   Next_File                  ;no, skip ahead
    Cmp  Byte Ptr [QPDTA+30],"."    ;is it a "." or ".." directory entry?
    Je   Next_File                  ;yes, don't count that either
    Inc  BX                         ;it's a match, increment the count in BX

Next_File:
    Mov  AH,4Fh           ;find next matching "file name" service
    Call DOS
    Jnc  Count_File       ;if not carry, then we got another file
    Jmp  Short Exit       ;else, that's all she wrote

ErrExit:
    Call Load_DOSErr      ;translate the error code

CEH_Ret:                  ;CEH returns here
    Xor  BX,BX            ;just to be sure, zero the return value

Exit:
    Call Restore_CEH      ;restore the QuickBASIC critical error handler
    Mov  AX,BX            ;BASIC assembler functions expect the result in AX
    HRet

HEndp
End
