;----- FCount.Asm - counts the number of files that match a specification

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - Count = FCount%(FSpec$)
;
;  where FSpec$ holds the file specification, and Count is assigned the
;  number of files that match.  Errors are returned in DOS/WhichError.


.Model Medium, Basic
.Data

    Extrn QPDTA:Byte      ;these are in External.Asm
    Extrn File_Name:Byte

.Code
    Include Mixed.Inc
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    Extrn Load_File:Far, DOS:Far

HProc FCount, Spec:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:CEH_Ret
    Call Setup_CEH

    Lea  DX,QPDTA         ;put address of QPDTA into DS:DX for set DTA service
    Mov  AH,1Ah           ;set DTA service - creates space for the file names
    Call DOS

    Xor  BX,BX            ;zero the count accumulator
    Mov  SI,Spec          ;SI holds address of FSpec$ descriptor
    Call Load_File        ;create an ASCIIZ string
    Jc   ErrExit          ;quit if an error was detected

    Mov  CX,00100111b     ;put the attribute for files into CX
    Mov  AH,4Eh           ;find first matching file name service
    Call DOS              ;call DOS
    Jnc  Next_File        ;if not carry, then DOS found a file
    Cmp  AX,2             ;else, was the directory empty?
    Je   Exit             ;if so, then the directory was empty
    Cmp  AX,18            ;error 18 also means the directory was empty
    Je   Exit             ;
    Jmp  Short ErrExit    ;else, DOS found an error

Next_File:
    Inc  BX
    Mov  AH,4Fh           ;find next matching file name service
    Call DOS
    Jnc  Next_File        ;if not carry, keep looking
    Jmp  Short Exit       ;else, we're done

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
