;----- DiskRmSz.Asm - this file is both DiskRoom and DiskSize

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - FreeSpace = DiskRoom&(Drive$)
;         TotalSpace = DiskSize&(Drive$)
;where Drive$ = "A" or "a" or "B", etc., if Drive$ = "", default is used

;Errors are returned in DOS/WhichError.

.Model Medium, Basic
.Data
    WhichSvc DB -1

.Code
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far, DOS:Far

DiskSize Proc
    Mov  WhichSvc,0         ;show that we're doing DiskSize, not DiskRoom
DiskSize Endp


DiskRoom Proc, Drive:Word

    Inc  WhichSvc           ;show that we're doing DiskRoom, not DiskSize

    Mov  DX,CS              ;install CEH
    Lea  BX,CS:CEH_Ret
    Call Setup_CEH

    Mov  BX,Drive           ;put Drive$ descriptor into BX
    Mov  CX,[BX]            ;put LEN(Drive$) into CX
    Mov  DL,0               ;assume they want the default drive for now
    Jcxz Do_It              ;it's null, leave DL holding 0 and call DOS

    Mov  BX,[BX+02]         ;put address of Drive$ in BX
    Mov  DL,[BX]            ;put ASC(Drive$) into DL

    Cmp  DL,'a'             ;is it below "a"?
    Jb   Continue           ;yes, skip
    Sub  DL,32              ;no, convert to upper case

Continue:
    Sub  DL,64              ;"A" now equals 1, "B" = 2, etc.

Do_It:
    Mov  AH,36h             ;get free space service
    Call DOS                ;call DOS
    Or   AX,AX              ;test AX for the error flag (0FFFFH)
    Js   ErrExit            ;if sign flag set, then we've got an error
                            ;the results are returned as follows:
                            ;    AX = sectors per cluster (2 for a floppy)
                            ;    BX = free clusters on the disk
                            ;    CX = bytes per sector (usually 512)
                            ;    DX = total available clusters
                            
    Cmp  WhichSvc,0         ;are they asking for DiskRoom?
    Je   DoRoom             ;yes, skip ahead leaving the free clusters in BX
    Mov  BX,DX              ;no, put the total clusters into BX

DoRoom:
    Mul  CX                 ;now AX holds the number of bytes per cluster
    Mul  BX                 ;and now it holds the total number of bytes
    Jmp  Short Done

ErrExit:
    Mov  AX,15              ;error must be invalid drive spec
    Call Load_DOSErr        ;call the error translator

CEH_Ret:
    Xor  AX,AX              ;return zero on error
    Cwd                     ;as a long integer

Done:
    Call Restore_CEH        ;restore the QuickBASIC critical error handler
    Mov  WhichSvc,-1        ;default to DiskRoom for next time
    Ret                     ;return to BASIC

DiskRoom Endp
End
