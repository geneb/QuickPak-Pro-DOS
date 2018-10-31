;------- FCopy.ASM

;Copyright (C) 1988 J. R. Conrad All Rights Reserved
;Revised Jan 89 - J. R. Conrad

;Syntax: Call FCopy(InFile$, OutFile$, Buffer$, ErrCode%).
; Where: InFile$  = source path and filename,
;        OutFile$ = target path and filename,
;        Buffer$  = blank string (64 < Len < 32768, optimum = 4096)
;        ErrCode% = 1 if error was related to the source file
;                   2 if error was related to the target file
;                   0 in all other cases

;Errors are returned in DOS/WhichError.  Use ErrCode% to distinguish between
;source-related and target-related errors.

;Stack map:

    Delta          Equ 14                      ;Size of local data frame
    Err_Code       Equ Word Ptr [BP-14]
    Ctrl_Brk       Equ Word Ptr [BP-12]        ;State of Ctrl-Break
    File_Date      Equ Word Ptr [BP-10]        ;Date from source file
    File_Time      Equ Word Ptr [BP-8]         ;Time from source file
    Buffer_Size    Equ Word Ptr [BP-6]         ;Size of Buffer$
    Target_Handle  Equ Word Ptr [BP-4]         ;Target handle after open
    Source_Handle  Equ Word Ptr [BP-2]         ;Source handle after open
    Save_BP        Equ Word Ptr [BP]
    Save_SI        Equ Word Ptr [BP+2]         ;Save regs above BP to permit
    Save_DI        Equ Word Ptr [BP+4]         ;  recovery after CEH.
    Save_DS        Equ Word Ptr [BP+6]
    Ret_IP         Equ Word Ptr [BP+8]         ;Stack after entry
    Ret_CS         Equ Word Ptr [BP+10]
    ErrCode%       Equ Word Ptr [BP+12]        ;Address of ErrCode%
    Buffer$        Equ Word Ptr [BP+14]        ;Buffer$ descriptor address
    OutFile$       Equ Word Ptr [BP+16]        ;Outfile$ descriptor address
    InFile$        Equ Word Ptr [BP+18]        ;InFile$ descriptor address

    Public FCopy

.Model Medium, Basic

.Code
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    Extrn Create_Err:Far ,Open_Err:Far, DOS:Far

FCopy Proc Far

    Push DS                  ;save DS
    Push DI                  ;save indexes for mixed code
    Push SI
    Push BP                  ;save BP
    Mov  BP,SP               ;mark the stack
    Sub  SP,Delta            ;allocate local data frame

    Mov  DX,CS               ;install CEH
    Lea  BX,CS:Close_Files   ;make sure CEH closes any open files
    Call Setup_CEH

    Mov  AX,3300h            ;get break flag
    Call DOS                 ;save state of break setting
    Mov  Ctrl_Brk,DX

    Mov  AX,3301             ;turn off break 
    Xor  DL,DL
    Call DOS

    Cld                      ;strings forward
    Push DS                  ;insure ES points to DGROUP
    Pop  ES
    Mov  Err_Code,0          ;zero the error code
    Mov  Source_Handle,0     ;zero the file handle variables
    Mov  Target_Handle,0

Check_Buffer:
    Mov  SI,Buffer$          ;make sure buffer is big enough
    Cmp  Word Ptr [SI],64    ;is it longer than 64 char?
    Ja   Open_Source         ;  if so, then continue
    Mov  AX,27               ;  else, return with error
    Jmp  ErrExit

Open_Source:
    Mov  Err_Code,1          ;make error code reflect source errors
    Mov  AX,[SI]             ;retrieve and save buffer size
    Mov  Buffer_Size,AX

    Mov  DX,[SI+2]           ;DX = offset of Buffer$
    Mov  SI,InFile$          ;point SI to InFile$
    Call Make_ASCZ           ;convert to ASCIIZ
    Jnc  Open_Source1        ;if not carry, then continue
    Jmp  ErrExit             ;else, Make_ASCZ detected a string error

Open_Source1:
    Mov  AX,3D00h            ;request Open File
    Call DOS
    Jnc  Get_DateTime        ;if not carry, then continue
    Jmp  ErrExit             ;else, exit with error

Get_DateTime:
    Mov  Source_Handle,AX    ;save source file handle

    Mov  BX,AX               ;get the time and date
    Mov  AX,5700h
    Push DX                  ;save DX on stack
    Call DOS
    Mov  File_Time,CX        ;save time
    Mov  File_Date,DX        ;  and date
    Pop  DX                  ;restore DX

    Mov  Err_Code,2          ;make error code reflect target errors
    Mov  SI,OutFile$         ;point SI to OutFile$
    Call Make_ASCZ           ;convert to ASCIIZ
    Jc   ErrExit

    Mov  AH,3Ch              ;request Create/Clear File
    Mov  CX,0                ;target is normal file
    Call DOS
    Jnc  Prep_Copy           ;if not carry, then continue

    Call Create_Err          ;else, gin the error code
    Jmp  Short ErrExit       ;quit now

Prep_Copy:
    Mov  Target_Handle,AX    ;save the target file handle

Do_Copy:
    Mov  CX,Buffer_Size      ;put buffer size in CX
    Mov  AH,3Fh              ;request Read from File and
    Mov  BX,Source_Handle    ;  retrieve source handle
    Call DOS

    Mov  CX,AX               ;put actual bytes read into CX for write
    Jcxz Stamp_File          ;if zero bytes read, then copy is done

    Mov  AH,40h              ;request Write to File and
    Mov  BX,Target_Handle    ;  retrieve handle
    Call DOS

    Cmp  AX,CX               ;if bytes written = read,
    Je   Do_Copy             ;then all is well
    Jmp  Short Full_Disk     ;else, the target disk is full

Stamp_File:
    Mov  AX,5701h            ;set target file time/date
    Mov  BX,Target_Handle
    Mov  CX,File_Time
    Mov  DX,File_Date
    Call DOS
    Jmp  Short Close_Files   ;and close the files

Full_Disk:
    Mov  AX,21               ;setup the "full disk" error
    Mov  Err_Code,3          ;show that we've got to erase a widow

ErrExit:
    Call Load_DOSErr         ;translate the error code

Close_Files:
    Cmp  Source_Handle,0     ;is source open?
    Je   Basic_Return        ;  if no, then no files open

    Cmp  Target_Handle,0     ;is target open?
    Je   Source_Only         ;  if no, only source open

    Mov  AH,3Eh              ;request file closing service
    Mov  BX,Target_Handle    ;close target file.
    Mov  Target_Handle,0     ;zero the handle
    Call DOS

    Cmp  Err_Code,3          ;check for disk full case
    Jne  Source_Only         ;if Err_Code <> 3, then no widow
    Dec  Err_Code            ;else, set Err_Code for a target error
    Mov  SI,OutFile$         ;point SI to OutFile$
    Call Make_ASCZ           ;setup an ASCIIZ string
    Mov  AH,41h              ;tell DOS to erase the widow
    Call DOS

Source_Only:
    Mov  AH,3Eh              ;request file closing service
    Mov  BX,Source_Handle    ;close source file
    Mov  Source_Handle,0     ;zero the handle
    Call DOS

Basic_Return:
    Mov  DI,ErrCode%         ;set error flag
    Mov  BX,Err_Code
    Mov  [DI],BX

    Mov  AX,3301h            ;restore state of Ctrl-Brk
    Mov  DX,Ctrl_Brk
    Call DOS

    Call Restore_CEH         ;restore the QuickBASIC critical error handler
    Mov  SP,BP               ;restore registers
    Pop  BP
    Pop  SI
    Pop  DI
    Pop  DS
    Ret  8                   ;cleanup stack and return

FCopy Endp


;=============> Make_ASCZ    Converts string to ASCIIZ
                             ;Entry: SI points to string descriptor
Make_ASCZ Proc Near          ;       DX points to buffer
                             ; Exit: Jmps to exit on error!
    Mov  CX,[SI]             ;get length of string,
    Jcxz Load_Err            ;if length = 0, then return with error
    Cmp  CX,64               ;is the string too long?
    Ja   Load_Err            ;if so, then return with error

    Mov  SI,[SI+2]           ;point SI to filename
    Mov  DI,DX               ;point DI to buffer
    Rep  Movsb               ;transfer pathname
    Mov  [DI],CL             ;make ASCIIZ
    Clc                      ;clear carry so caller knows all is well
    Ret                      ;return

Load_Err:
    Mov  AX,19               ;setup for "bad filename" error
    Stc                      ;set carry so caller knows an error was found
    Ret                      ;return

Make_ASCZ Endp

End
