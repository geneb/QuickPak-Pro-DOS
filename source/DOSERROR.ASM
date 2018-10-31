;--------- DOSError.Asm - DOS error handler routines for QuickPak Professional

;Copyright (C) 1989 J. R. Conrad All Rights Reserved


.MODEL MEDIUM
.DATA?                          ;allocate uninitialized data:
    Int24_IP      DW 1 DUP (?)  ;  storage for Int24 vector
    Int24_CS      DW 1 DUP (?)

.DATA                        ;allocate initialized data:
    CEH_Ret       Label DWord
    CEH_Ret_IP    DW 0       ;  return point if a critical error occurs
    CEH_Ret_CS    DW 0

    DOSErr_Code   DW 0       ;  BASIC equivalent error code
    CritErr_Flag  DB 0       ;  flag to indicate active critical errors
    DOS_Ver       DB 0       ;  the DOS version number

    Public        DOSErr_Code

.CODE
    Public Setup_CEH         ;installs the QuickPak critical error handler
    Public Restore_CEH       ;restores the BASIC critical error handler
    Public DOS               ;issues Int 21h and handles program redirection

    Public Load_DOSErr       ;translate the extended DOS error codes
    Public Load_CEHErr       ;tranlates critical error codes

    Public Create_Err        ;improves error discrimination
    Public Rename_Err        ;improves error discrimination
    Public Open_Err          ;improves error discrimination
    Public Lock_Err          ;improves error discrimination
    Public Ext_Err           ;retrieves DOS 3+ extended error codes

    Public DOSError          ;BASIC boolean function
    Public WhichError        ;BASIC error code retrieval function
    Public SetError          ;BASIC error setting subroutine

;   CEH    custom critical error handler, not public

;===========> Setup_CEH

;Function:    1) Saves the addresses needed by CEH
;             2) Redirects the Int24 vector to CEH
;             3) Requests and saves the DOS major version number
;             4) Clears the DOS error variable
;             5) Clears the critical error flag
;
;On entry:    DX:BX MUST point to the local return address setup for CEH
;             DS must point to DGROUP
;
;Note:   If you set DX and BX to zero, the alternate return address feature
;        is disabled.  This means that execution will always return to the
;        statement immediately following the statement that caused a critical
;        error.

Setup_CEH Proc Far

    Push AX                  ;preserve registers
    Push BX
    Push CX
    Push DX
    Push ES
    Push DS

    Mov  CEH_Ret_IP,BX       ;CEH needs alternate exit address, save locally
    Mov  CEH_Ret_CS,DX

    Mov  AX,3524h            ;get Int24 vector
    Int  21h                 ;  into ES:BX
    Mov  Int24_IP,BX         ;  and save.
    Mov  Int24_CS,ES

    Mov  AX,Seg CEH          ;get segment and offset of CEH
    Mov  DS,AX               ; in DS:DX
    Lea  DX,CEH
    Mov  AX,2524h            ;revector Int24h
    Int  21h

    Mov  AH,30h              ;ask DOS for the version number
    Int  21h

    Pop  DS                  ;restore DS
    Mov  DOS_Ver,AL          ;store the major version number
    Mov  DOSErr_Code,0       ;clear the DOS error variable
    Mov  CritErr_Flag,0      ;clear the critical error flag

    Pop  ES                  ;restore the other registers
    Pop  DX
    Pop  CX
    Pop  BX
    Pop  AX
    Ret                      ;return

Setup_CEH Endp



;===========> Restore_CEH

;Function:    Restores the original Int24 vector that was saved by Setup_CEH
;
;On entry:    Nothing
;
;On return:   All registers preserved

Restore_CEH Proc Far

    Push DS                  ;preserve registers
    Push DX
    Push AX

    Push SS                  ;set DS = DGROUP
    Pop  DS
    Mov  DX,Int24_IP         ;get the original Int24 vector
    Mov  DS,Int24_CS
    Mov  AX,2524h            ;restore the vector
    Int  21h

    Pop  AX                  ;restore registers
    Pop  DX
    Pop  DS
    Ret                      ;return

Restore_CEH Endp



;===========> CEH

;Function:    Replaces the QuickBASIC critical error handler
;
;On entry:    Error code in DI (provided by DOS)
;
; On exit:    DOSErr_Code = error code (BASIC equivalent)
;             Preserves all registers except AL
;             AL directs DOS to ignore the error
;
; WARNING:    CEH cannot and should not be called (Routine is PRIVATE)!!

CEH Proc Far                 ;replaces BASIC Crit Err Hndlr

    Sti                      ;restore interrupts
    Push BP                  ;preserve BP
    Mov  BP,SP               ;mark the stack
    Push DI                  ;preserve DI
    Push DX                  ;preserve DX
    Push DS                  ;preserve DS
    Push AX                  ;preserve AX

    Push SS                  ;make sure DS points to DGROUP
    Pop  DS
    
    Cmp  DOS_Ver,3           ;is DOS 3+ installed?
    Jb   Trans_CEHErr        ;is not, then translate the error as supplied

    Call Far Ptr Ext_Err     ;retrieve the extended error
    Je   Trans_DOSErr        ;if share/lock error, then use DOSErr translator
    Jmp  SHort Trans_CEHErr  ;else, use the CEH error translator

Trans_DOSErr:
    Call Far Ptr Load_DOSErr ;translate AX to DOSErr_Code
    Jmp  Short CEH_Exit

Trans_CEHErr:
    Call Far Ptr Load_CEHErr ;translate DI to DOSErr_Code

CEH_Exit:
    Mov  CritErr_Flag,1      ;verify that a critical error occurred
    Pop  AX                  ;restore AX (really just AH)
    Mov  AL,0                ;tell DOS to ignore the error
    Pop  DS                  ;restore DS
    Pop  DX                  ;restore DX
    Pop  DI                  ;restore DI
    Pop  BP                  ;restore BP
    Iret                     ;let DOS clean house

CEH Endp                     ;and that's it!



;===========> Load_CEHErr

;Function:    Translate DOS critical errors to BASIC equivalents
;
;On entry:    DI contains the critical error code as defined below
;
;On exit:     DOSErr_Code contains the BASIC equivalent error code
;
;DI    DOS Definition             BASIC Equivalents    Err
;---   -----------------------    ------------------   ---
;00h   Write protect violation    Permission denied    70
;01h   Unknown drive number       Device unavailable   68
;02h   Drive not ready            Disk not ready       71
;03h   Unknown command            Device I/O error     57
;04h   CRC data error             Device I/O error     57
;05h   Bad request structure      Device I/O error     57
;06h   Seek error                 Device I/O error     57
;07h   Bad disk format            Disk media error     72
;08h   Sector not found           Device I/O error     57
;09h   Printer out of paper       Out of paper         27
;0Ah   Write error                Device fault         25
;0Bh   Read error                 Device I/O error     57
;0Ch   General failure            Device I/O error     57

Load_CEHErr Proc Far

    Push AX                  ;preserve AX
    And  DI,00FFh            ;clear the top half of DI
    Cmp  DI,0Dh              ;test for invalid error code
    Jb   Load_Crit1          ;if below 15, then OK
    Mov  DI,000Dh            ;else, do the old undefined

Load_Crit1:
    Mov  AL,Byte Ptr CS:Crit_Table[DI] ;translate the error code
    Xor  AH,AH               ;clear the high byte of AX
    Mov  SS:DOSErr_Code,AX   ;store the error code in public memory
    Pop  AX                  ;restore AX
    Ret

CRIT_Table:
    DB 70, 68, 71, 57, 57, 57, 57, 72, 57, 27, 25, 57, 57, 127

Load_CEHErr Endp



;===========> DOS

;Function:    Executes the Int 21h required for the normal DOS functions
;             and controls where execution returns after the interrupt.
;
;On entry:    Registers must be set up for the desired DOS function
;
;On exit:     If a critical error is detected, execution will jump to the
;             alternate return created with Setup_CEH.  Otherwise, a normal
;             return will be made via the stack.  You can override this
;             feature by calling Setup_CEH with both DX and BX set to zero.
;             With override, the return is always made through the stack.
;
;             The registers and flags will contain the expected return values
;             from DOS.  If a critical error is detected, the carry flag is
;             forced to "set".
;
;Notes:      1) Setup_CEH MUST be called prior to using this procedure.  The
;            setup procedure places the proper return address in CEH_Ret and
;            does a bunch of other important stuff as well.
;
;            2) You don't have to use this procedure to execute the 21h
;            interrupt.  If you don't, you will have to do your own critical
;            error checking.

DOS Proc Far

    Int  21h                 ;request DOS to service the function in AX

    Push DS                  ;preserve DS
    Push AX                  ;preserve AX
    Pushf                    ;preserve the flags

    ;Mov  AX,Seg DGROUP       ;make sure DS points to DGROUP
    ;Mov  DS,AX
    Push SS
    Pop  DS
    Test CritErr_Flag,1      ;test for a critical error
    Jnz  Crit_Err            ;if CritErr_Flag <> 0, then use the alt return
    Popf                     ;restore the flags

Norm_Ret:
    Pop  AX                  ;restore AX
    Pop  DS                  ;restore DS
    Ret                      ;and return via the stack

Crit_Err:
    Mov  CritErr_Flag,0      ;reset the critical error flag

    Cmp  CEH_Ret_CS,0        ;test for disabled alternate return feature
    Jne  Alt_Ret             ;if not zero, then use alternate return
    Cmp  CEH_Ret_IP,0        ;test for disabled alternate return feature
    Jne  Alt_Ret             ;if not zero, then use alternate return
    Popf                     ;restore the flags
    Stc                      ;make sure the carry flag is set
    Jmp  Norm_Ret            ;if both zero, then alternate return is disabled

Alt_Ret:
    Popf                     ;restore the flags
    Pop  AX                  ;restore AX
    Pop  DS                  ;restore DS
    Add  SP,4                ;dump the return address
    Push SS                  ;restore DS to original for jump
    Pop  DS                  ;  in case original program changed DS
    Jmp  CEH_Ret             ;and jump to the alternate return point

DOS Endp



;===========> Load_DOSErr

;Function:    Translates noncritical DOS errors to BASIC equivalents
;
;On entry:    AX contains the expanded set of DOS error codes
;
;On exit:     DOSErr_Code contains a BASIC equivalent error code
;             All registers preserved
;
;Note:   YOU DO NOT HAVE TO CHANGE THIS PROC TO USE SETERROR, ETC!!!!!!
;
;        If codes are to be added to this list, three things must be done.
;
;        First, fill in the table which follows to help you keep track of
;        the changes.  Be sure that the "AX" error code falls in sequence.
;        The BASIC equivalent can be any number below 127.
;
;        Second, change the Max_DOSErr Equ statement to one more than the
;        last defined error code.
;
;        Third, enter the BASIC equivalent error code into the data table
;        which follows the return.  If you are confused, look for the lines
;        marked with asterisks.  If you're still confused, don't mess with
;        this stuff.
;
;AX  DOS Error Definitions:                BASIC equivalent           Err
;--  ---------------------------           ----------------------     ---
; 1  Invalid function number               Undefined error            127
; 2  File not found                        File not found              53
; 3  Path not found                        Path not found              76
; 4  Too many handles                      Too many handles            78
; 5  Access denied                         Access denied               75
; 6  Invalid handle                        Bad file number             52
; 7  Memory control blocks destroyed       Undefined error            127
; 8  Insufficient memory                   Undefined error            127
; 9  Invalid memory block address          Undefined error            127
;10  Invalid environment                   Undefined error            127
;11  Invalid format                        Undefined error            127
;12  Invalid access code                   Undefined error            127
;13  Invalid data                          Undefined error            127
;14  Not used                              Undefined error            127
;15  Invalid drive specified               Invalid drive spec          77
;16  Attempt to remove current directory   Access denied               75
;17  Attempt to rename across drives       Rename across disks         74
;18  No more files found                   File not found              53
;
;QuickPak Extensions:
;19  Not defined                           Bad file name               64
;20  Not defined                           File already exists         58
;21  Not defined                           Disk is full                61
;22  Not defined                           Directory is full           67
;23  Not defined                           Input past end of file      62
;24  Not defined                           Invalid time data           80
;25  Not defined                           Invalid date data           81
;26  Not defined                           Invalid parameter           82
;27  Not defined                           Buffer too small            83
;28  Not defined                           Current directory renamed   84
;29  Not defined                           Share not installed         73
;30  Not defined                           Lock violation              85
;31  Not defined                           Sharing violation           86
;32  Not defined                           File is read-only           87

Max_DOSErr Equ 33            ;**** Max_DOSErr = last code + 1 ****

Load_DOSErr Proc Far

    Push DI                  ;preserve DI
    Push DS                  ;preserve DS
    Push AX                  ;preserve AX
    Push SS
    Pop  DS
    
    Cmp  AX,Max_DOSErr    ;check for valid error code
    Jb   Load_Err            ;  if valid, use lookup table
    Mov  AX,Max_DOSErr       ;  else, make UNDEFINED.

Load_Err:
    Mov  DI,AX               ;let DI point to error code
    Mov  AL,Byte Ptr CS:NORM_Table[DI] ;get the error code
    Mov  DOSErr_Code,AX      ;load the error variable

    Pop  AX                  ;restore the stack
    Pop  DS
    Pop  DI
    Ret                      ;return

NORM_Table:
    DB   0, 127,  53,  76,  78,  75,  52, 127
    DB 127, 127, 127, 127, 127, 127, 127,  77
    DB  75,  74,  53,  64,  58,  61,  67,  62
    DB  80,  81,  82,  83,  84,  73,  85,  86

    DB  87         ;******** additional codes go here ********

    DB 127                   ;last code MUST equal 127

Load_DOSErr Endp



;===========> Create_Err

;Function:    Handles error discrimination for CREATE (3C/16h) and MKDIR(39h)
;
;On entry:    DS:DX = address of ASCIIZ filename (DS must point to DGROUP)
;             AX contains the error code returned by DOS
;
;On return:   AX contains the adjusted error code
;             All other registers are preserved
;
;Note:        Sharing errors always trigger the critical error interrupt.

Create_Err Proc Far

    Push BX                  ;use BX as temporary storage
    Cmp  AX,5                ;do we have "access denied"?
    Jne  Create_Err_End      ;if not, then error code is OK

    Mov  AX,4300h            ;ask DOS to give us the file attribute
    Int  21h
    Mov  AX,22               ;assume "directory is full"
    Jc   Create_Err_End      ;if carry, then directory is full

    Mov  AX,32               ;assume file is read-only
    Test CX,1                ;test if file is read-only
    Jnz  Create_Err_End      ;if (BX AND 1) <> 0, then read-only
    Mov  AX,5                ;else, "access denied" stands

Create_Err_End:
    Pop  BX                  ;restore BX
    Ret

Create_Err Endp



;===========> Rename_Err

;Function:    Handles error discrimination for Functions 17h and 56h
;
;On entry:    DS:DX = address of ASCIIZ filename (DS must point to DGROUP)
;             AX contains the error code returned by DOS
;
;On return:   AX contains the adjusted error code
;             All other registers preserved
;
;Note:        Sharing errors always trigger the critical error interrupt.

Rename_Err Proc Far
    
    Cmp  AX,5                ;do we have "Access denied"?
    Jne  Rename_Err_End      ;if not, then error code is OK
    Mov  AX,4300h            ;ask DOS to give us the file attribute
    Int  21h
    Mov  AX,20               ;assume filename already exists
    Jnc  Rename_Err_End      ;if not carry, then the filename already exists
    Mov  AX,5                ;if file not found, then "access denied" stands

Rename_Err_End:
    Ret

Rename_Err Endp



;===========> Open_Err

;Function:    Handles error discrimination for Function 3Dh
;
;On entry:    AX contains the error code returned by DOS
;
;On return:   AX contains the adjusted error code
;             All other registers preserved
;
;Note:        Sharing errors trigger the critical error interrupt if the
;             attempt is made in compatibility mode.  Otherwise, they come
;             here as "access denied."

Open_Err Proc Far

    Push BX                  ;use BX as temporary storage
    Cmp  AX,5                ;do we have "access denied"?
    Jne  Open_Err_End        ;if not, then error code is OK

    Cmp  SS:DOS_Ver,3        ;is DOS 3+ installed?
    Jb   Open_Err_End        ;if not, then sharing errors are impossible

    Call Far Ptr Ext_Err     ;ask DOS for the extended error code
    Je   Open_Err_End        ;if zero flag, then share of locking conflict
    Mov  AX,5                ;if not, "access denied" stands

Open_Err_End:
    Pop  BX                  ;restore BX
    Ret

Open_Err Endp



;===========> Lock_Err

;Function:    Handles error discrimination for Function 5Ch
;
;On entry:    AX contains the error code returned by DOS
;
;On return:   AX contains the adjusted error code
;             All other registers preserved

Lock_Err Proc Far

    Push BX                  ;use BX as temporary storage
    Mov  BX,AX               ;copy AX into BX
    Mov  AX,29               ;assume SHARE is not installed
    Cmp  BX,1                ;test for the "invalid function number"
    Je   Lock_Err_End        ;if yes, then we were right

    Call Far Ptr Ext_Err     ;call the extended error analyzer
    Je   Lock_Err_End        ;if zero flag, then share of locking conflict
    Mov  AX,5                ;if not, return with "access denied"

Lock_Err_End:
    Pop  BX                  ;restore BX
    Ret

Lock_Err Endp



;===========> Ext_Err

;Function:    Returns the extended error code provided by DOS 3+
;
;On entry:    Insure that a DOS version greater than 3.00 is loaded
;
;On exit:     Returns the extended error code in AX
;
;Note:        Ext_Err helps with recognition of sharing and locking conflicts.
;             If the zero flag is set, then either a sharing or locking
;             conflict was found and AX contains the correct internal error
;             code.  If not zero, then another error occurred which must be
;             handled by the calling procedure.

Ext_Err Proc Far

    Push DS                  ;save regs before DOS cleans our clock
    Push ES                  ;come on Bill Gates, what is this garbage?
    Push BP                  ;somebody was on drugs
    Push BX
    Push CX
    Push DX
    Push SI
    Push DI

    Xor  BX,BX               ;put a zero in BX
    Mov  AH,59h              ;request the extended error function
    Int  21h

    Mov  BX,AX               ;put the error code into BX
    Mov  AX,31               ;assume "sharing violation"
    Cmp  BX,20h              ;is the error code = 32? (sharing violation)
    Je   Ext_Err_Ret         ;if yes, then we're done
    Mov  AX,30               ;assume "locking violation"
    Cmp  BX,21h              ;is the error code = 33? (locking violation)
    Je   Ext_Err_Ret         ;if yes, then we're done
    Mov  AX,BX               ;if not, restore the DOS error code

Ext_Err_Ret:
    Pop  DI                  ;get the good stuff back
    Pop  SI
    Pop  DX
    Pop  CX
    Pop  BX
    Pop  BP
    Pop  ES
    Pop  DS

    Ret

Ext_Err Endp


;===========> DOSError

;Function:    BASIC function which tests for DOS errors
;
;Syntax:      If DOSError% Then Print "An error occurred!"

DOSError Proc Far

    Xor  AX,AX               ;assume no error
    Cmp  DOSErr_Code,0       ;retrieve the error code
    Je   End_DOSErr          ;if not, then done
    Dec  AX                  ;else, set TRUE (-1)

End_DOSErr:
    Ret                      ;return to BASIC

DOSError Endp



;===========> WhichError

;Function:    BASIC function which retrieves the DOS error code
;
;Syntax:      Print "Error "; WhichError%; " occurred"

WhichError Proc Far

    Mov  AX,DOSErr_Code      ;put the error code in AX
    Ret                      ;return to BASIC

WhichError Endp



;===========> SetError

;Function:    Gives the BASIC user access to DOSErr_Code
;
;Syntax:      Call SetError(ErrNum%)

SetError Proc Far

    Push BP                  ;mark the stack
    Mov  BP,SP

    Mov  DI,[BP+6]           ;grab the error code
    Mov  DI,[DI]
    Mov  DOSErr_Code,DI      ;put it where it belongs

    Pop  BP
    Ret  2                   ;outta here

SetError Endp

End
