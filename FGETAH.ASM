;----- FGetAH.Asm - reads an entire huge array from a binary file

;Copyright (c) 1988 Ethan Winer
;DOS Error portion by J. R. Conrad

;Syntax - CALL FGetAH(FileName$, SEG Array(Start), ElSize%, NumEls%)
;
;  where FileName$ is the name of the file to load, and Array(Start) is the
;  array where the file is to be loaded.  ElSize% is the length of each array
;  element, and NumEls% is the number of elements to be loaded.
;
;  Errors may be detected with the DOSError and WhichError functions.


.Model Medium, Basic
.Code
    Include Mixed.Inc
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    Extrn Load_File:Far, DOS:Far, Code2Num:Far

HProc FGetAH, File:Ptr, Array:DWord, ElSize:Ptr, NumEls:Ptr

    Push DS               ;save DS

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:CEH_Ret
    Call Setup_CEH

    Mov  SI,File          ;SI holds address of FileName$ descriptor
    Call Load_File        ;create an ASCIIZ string
    Jc   ErrExit          ;quit if an error was detected

    Mov  AX,3D00h         ;specify Open File service, read-only operation
    Call DOS              ;call DOS
    Jc   ErrExit          ;carry set means an error, otherwise handle is in AX
    Mov  BX,AX            ;put the handle into BX for subsequent reads

    Mov  AX,27            ;assume they used zero elements/bytes per element
                          ;  by setting up for QP Pro "Buffer too small" error
    Mov  SI,ElSize        ;get the address for ElSize%
    Mov  CX,[SI]          ;put ElSize% into CX for Code2Num
    Call Code2Num         ;convert possible size code to number of bytes
    Jcxz ErrExit          ;if the number of bytes is zero, that's an error
    Mov  SI,CX            ;no error, save the number of bytes in SI

    Mov  DI,NumEls        ;get the address for NumEls%
    Mov  CX,[DI]          ;and put the number of elements into CX
    Jcxz ErrExit          ;they specified zero elements, show the error
    Mov  AX,SI            ;put the number of bytes into AX to multiply

    Mul  CX               ;now DX:AX holds the total number of bytes to load
    Mov  DI,DX            ;copy DX to DI because DOS uses DX for load address
    Mov  SI,AX            ;copy AX to SI because DOS uses AH for function #

    Mov  CX,8000h         ;assume we'll be loading at least 32K
    Lds  DX,Array         ;load DS:DX with the address of Array(Start)
    Or   DX,DX            ;is the address beyond 32K?
    Jns  NotSigned        ;no, skip ahead
    And  DH,7Fh           ;adjust seg/adr
    Mov  AX,DS            ;for a full 32K load
    Add  AX,800h
    Mov  DS,AX

NotSigned:
    Shl  DI,1             ;convert number of 64K blocks to number of 32K
    Or   SI,SI            ;see if SI > 32K
    Jns  LoadLoop         ;no, skip ahead
    Inc  DI               ;load one additional 32K block
    And  SI,7FFFh         ;adjust SI accordingly

LoadLoop:
    Or   DI,DI            ;any more complete 32K blocks to load?
    Jnz  Do32K            ;yes, do a complete block
    Mov  CX,SI            ;no, load CX with the number of bytes that remain

Do32K:
    Mov  AH,3Fh           ;specify Read service
    Call DOS              ;call DOS
    Jc   ErrExit          ;oops, found an error

    Cmp  AX,CX            ;check for read past end
    Mov  AX,23            ;assume we did
    Jne  ErrExit          ;if AX <> CX, then we passed the file's end

    Dec  DI               ;show that we did another complete 32K block
    Js   Exit             ;if we passed zero then we're all done, bye
    Mov  AX,DS            ;bump DS to the next 32K block
    Add  AX,800h          ;through AX
    Mov  DS,AX
    Jmp  Short LoadLoop   ;still more to load, go do it

ErrExit:
    Call Load_DOSErr

CEH_Ret:
    Mov  AX,-1            ;clear the file handle variable

Exit:
    Pop  DS               ;get DS back again
    Mov  AH,3Eh           ;close file service
    Call DOS              ;call DOS
    Call Restore_CEH      ;restore the QuickBASIC critical error handler

ClExit:
    HRet                  ;return to BASIC

HEndp
End
