;----- DiskInfo.Asm - retrieves information about a disk

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - CALL DiskInfo(Drive$, BytesPerSector%, SectorsPerCluster%, _
;              AvailableClusters%, TotalClusters%)
;
;where Drive$ = "A" or "a" or "B", etc., if Drive$ = "", default is used

;Errors are returned in DOS/WhichError.

.Model Medium, Basic
.Code

    Include Mixed.Inc
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far, DOS:Far

HProc DiskInfo, Drive:Ptr, BPS:Ptr, SPC:Ptr, AC:Ptr, TC:Ptr

    Mov  DX,CS              ;install CEH
    Lea  BX,CS:CEH_Ret
    Call Setup_CEH

    Mov  SI,Drive           ;put Drive$ descriptor into SI
    Mov  DL,0               ;assume they want the default drive for now
    Mov  CX,[SI]            ;put LEN(Drive$) into DX
    Jcxz Do_It              ;it's null, leave DL holding 0 and call DOS

    Mov  SI,[SI+02]         ;put address of Drive$ in SI
    Mov  DL,[SI]            ;put ASC(Drive$) into DL

    Cmp  DL,'a'             ;is it below "a"?
    Jb   Continue           ;yes, skip
    Sub  DL,32              ;no, convert to upper case

Continue:
    Sub  DL,64              ;"A" now equals 1, "B" = 2, etc.

Do_It:
    Mov  AH,36h             ;get free space service
    Call DOS                ;call DOS
    Cmp  AX,0FFFFh          ;AX = FFFFh if invalid drive
    Jne  GoodData           ;If not, then outa here

    Mov  AX,15              ;else, put up an error
    Call Load_DOSErr

CEH_Ret:
    Xor  AX,AX              ;clear all the variables
    Xor  BX,BX
    Xor  CX,CX
    Xor  DX,DX

GoodData:
    Mov  DI,BPS             ;address of BytesPerSector%
    Mov  [DI],CX            ;assign it from CX

    Mov  DI,SPC             ;address of SectorsPerCluster%
    Mov  [DI],AX            ;and so forth

    Mov  DI,AC              ;address of AvailableClusters%
    Mov  [DI],BX

    Mov  DI,TC              ;address of TotalClusters%
    Mov  [DI],DX

    Call Restore_CEH        ;restore BASIC's critical error handling
    HRet                    ;return to BASIC

HEndp
End
