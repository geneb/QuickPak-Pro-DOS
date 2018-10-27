;----- ClipFile.Asm - truncates a file to a specified number of bytes

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - CALL ClipFile(FileName$, NewSize&)
;
;  Where FileName$ holds the file name to truncate, and NewSize& is the
;  new length it is to be.  Generally, this routine would be used with
;  random access data files, so it is up to you to calculate the new size
;  based on the length of each record, and how many records are to remain.
;  This is easily accomplished like this:
;
;      NewSize& = (NumberOfRecords - 1) * RecordLength
;
;  Errors are returned in DOS/WhichError.
;
;  ClipFile can also increase the size of a file up to 32 MB.  The upper
;  limit is set by the free capacity of the disk.  Based on the maximum
;  number in NewSize&, ClipFile could go to 4096 MB.  However, ClipFile
;  does not recognize the DOS 4.0 extension for huge volumes.  If you
;  ask for a size increase greater than the available disk capacity, DOS
;  will not change the file size.  ClipFile recognizes this error.  If the
;  specifed size does not equal the actual size after the file is closed,
;  ClipFile realizes it didn't work and returns with the "disk full" error.
;  In addition to setting DOSError and WhichError, ClipFile also replaces
;  NewSize& with the actual size of the file.

.Model Medium, Basic
.Data
    Extrn File_Name:Byte  ;these are in the file External.Asm
    Extrn QPDTA:Byte

.Code
    Include Mixed.Inc
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    Extrn DOS:Far, Load_File:Far

HProc ClipFile, FileName:Ptr, NewSize:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Xor  BX,BX            ;clear BX to check for open file later
    Mov  SI,FileName      ;point SI to the filename string
    Call Load_File        ;copy the string to the ASCIIZ buffer
    Jc   ErrExit          ;if carry, an error was detected

    Mov  AX,3D02h         ;specify Open File service, Read/Write operation
    Call DOS              ;call DOS
    Jc   ErrExit          ;if the carry flag is set, there was an error
    Mov  BX,AX            ;copy the handle into BX for the remaining services

    Mov  SI,NewSize       ;get the address for NewSize&
    Mov  DX,[SI]          ;assign the low portion of NewSize&
    Mov  CX,[SI+02]       ;ditto for the high portion

    Mov  AH,42h           ;specify the File Seek service
    Xor  AL,AL            ;set AL to 0 meaning seek from the start of the file
    Call DOS              ;call DOS
    Jc   ErrExit          ;an error, handle it

    Mov  AH,40h           ;specify Write File service
    Xor  CX,CX            ;if we write 0 bytes, the file is truncated
    Call DOS              ;call DOS to do the dirty work
    Jc   ErrExit          ;as above

    Mov  AH,3Eh           ;specify Close File service
    Call DOS
    Xor  BX,BX            ;clear BX so we don't get into trouble below
    Jc   ErrExit

    Lea  DX,QPDTA         ;now we gotta check for a full disk
    Mov  DI,DX            ;so setup the DTA
    Mov  AH,1Ah
    Call DOS
    Lea  DX,File_Name     ;and read the directory information
    Mov  CX,00010110b
    Mov  AH,4Eh
    Call DOS

    Xor  AX,AX            ;assume the file was modified as specified
    Mov  DX,[DI+26]       ;get the low word of the actual size
    Cmp  DX,[SI]          ;does actual size agree with specified size?
    Je   Cmp_Hi           ;if so, then examine the high word
    Mov  AX,21            ;else, set the error code to reflect "full disk"
    Mov  [SI],DX          ;  and replace the specified size with actual size

Cmp_Hi:
    Mov  DX,[DI+28]       ;get the high word of the actual size
    Cmp  DX,[SI+02]       ;does actual size agree with specified size?
    Je   ErrExit          ;if so, then exit through ErrExit
    Mov  AX,21            ;else, set the error code to reflect "full disk"
    Mov  [SI+02],DX       ;  and replace the specified size with actual size

ErrExit:
    Call Load_DOSErr      ;translate the error code

Exit:
    Or   BX,BX            ;do we have an open file?
    Jz   Exit2            ;if not, get out now (or all hell breaks loose)
    Mov  AH,3Eh           ;specify Close File service
    Call DOS

Exit2:
    Call Restore_CEH      ;restore the QuickBASIC critical error handler
    HRet                  ;return to BASIC

HEndp
End
