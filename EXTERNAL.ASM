;---------- External.Asm

;Copyright (c) 1988 Ethan Winer
;Revision and additional comments by J. R. Conrad


;  This file holds several important pieces of data used by many of the
;  QuickPak Professional DOS routines - a place to create an ASCIIZ filename,
;  a DTA buffer, and an extended file control block .  In earlier versions,
;  this data was kept within each of the routines.  Since so many routines
;  need space in DGROUP, a large quantity of data space would be permanently
;  tied up.  By placing these data areas in one common .OBJ file, the bytes 
;  are taken from BASIC's string space only once, regardless of how many 
;  routines are being used.  In technical parlance, we have created a common
;  data area.

;  This file also contains Reset_FCB, a procedure that resets the FCB.  Since 
;  several QuickPak DOS routines use a common FCB, it is safer to start fresh 
;  each time instead of hoping that the contents of the FCB have not been 
;  changed.  Call Reset_FCB with CL set to the desired attribute.  Everything
;  else is automatic.

;  The last procedure is Load_Name which can cut a lot of bytes out of DOS
;  subroutines.  This baby will transfer a BASIC string to File_Name, add the
;  null terminator needed by DOS to identify the end of the string, and return
;  with DX pointing to File_Name.  If string length errors are detected, the
;  carry flag is set and the correct error code is returned in AX.  All this
;  bad boy needs is a pointer to the string descriptor in SI.  DS must also
;  point to DGROUP.


Public FN_Len, FN_Addr, File_Name
Public FCB, Attr, Drive, Old_Name, Reserved, New_Name, Reserved2
Public QPDTA

.Model Medium

.Data

    FN_Len      DW   ?                 ;length of FileName
    FN_Addr     DW   ?                 ;address of FileName
    File_Name   DB   80 Dup (?)        ;space to create an ASCIIZ file name

    FCB         DB   0FFh,0,0,0,0,0    ;File Control Block
    Attr        DB   8                 ;attribute to search for - label
    Drive       DB   0                 ;drive identifier
    Old_Name    DB   '???????????'     ;search criteria
    Reserved    DB   5 Dup (0)         ;this is a reserved area - don't mess
    New_Name    DB   '???????????'     ;where the new name is placed
    Reserved2   DB   9 Dup (?)         ;more reserved stuff

    QPDTA       DB   44 Dup (?)        ;holds a DOS Disk Transfer Area

.Code

    Public Reset_FCB, Load_File

Reset_FCB Proc Far

;Function:    Clears the FCB for reuse
;
;On entry:    CL must contain the desired file attribute, DS must be DGROUP
;
;On exit:     Returns nothing.  All registers preserved

    Push ES                  ;preserve registers
    Push DI
    Push AX
    Push CX

    Lea  DI,FCB              ;point DI to the FCB
    Push DS                  ;ensure that ES points to DGROUP
    Pop  ES
    Cld                      ;ensure that bytes are filled forward
    Mov  CX,44               ;FCB is 44 bytes long
    Xor  AL,AL               ;we want to fill it with nulls
    Rep  Stosb               ;so, do it

    Lea  DI,Old_Name         ;point DI to the Old_Name field
    Mov  CX,11               ;Old_Name is 11 bytes long
    Mov  AL,'?'              ;we want to fill Old_Name with "?"
    Rep  Stosb               ;so, gedafter bidness

    Mov  FCB,0FFH            ;tell DOS that this is an extended FCB
    Pop  CX                  ;restore CX so we can get the attribute
    Mov  Attr,CL             ;put the attribute into the attribute field

    Pop  AX                  ;restore registers
    Pop  DI
    Pop  ES
    Ret

Reset_FCB Endp


Load_File Proc Far

;Function:    Transfers a BASIC filename string to File_Name
;             Checks for bad string length: 0 < LEN(String) <= 64
;
;On entry:    SI points to the BASIC string descriptor
;             DS must point to DGROUP
;
;On exit:     If a length error is detected, the carry flag is set:
;                AX contains the QuickPak internal error code.
;
;             If the carry flag is not set:
;                DX points to File_Name for subsequent DOS calls
;                SI points one byte past the end of the BASIC string
;                DI points to the null terminator stored in File_Name
;                CX = zero

    Push DS                  ;insure ES=DS for string move below
    Pop  ES

    Mov  AX,19               ;assume the user passed a bad filename
    Mov  CX,[SI]             ;put the string length in CX
    Jcxz Bad_Load            ;if length = 0, then exit with error
    Cmp  CX,78               ;is length > 78?
    Ja   Bad_Load            ;if so, then exit with error

    Mov  SI,[SI+02]          ;put the string address in SI
    Lea  DI,File_Name        ;put the buffer address in DI
    Mov  DX,DI               ;save the buffer address in DX

    Cld                      ;tell the CPU to increment string primitives
    Rep  Movsb               ;copy the string to File_Name
    Mov  Byte Ptr [DI],CL    ;make File_Name ASCIIZ (CL = 0)

    Clc                      ;clear the carry flag
    Ret                      ;return to the calling procedure

Bad_Load:
    Stc                      ;set the carry flag
    Ret                      ;return to the calling procedure

Load_File Endp

End
