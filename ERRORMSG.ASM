;********** ErrorMsg.Asm - returns text for a DOS error message

;Copyright (c) 1988 Ethan Winer


;syntax - ErrMsg$ = ErrorMsg$(ErrNum%)
;
;where ErrMsg$ will receive "File not found", or "Disk not ready", etc.

;This program stores the text of the messages in the code segment to avoid
;stealing string space from BASIC.  The incoming error number is first
;checked for an illegal value of greater than 127.  If so, it is converted
;to error 127, which is "Undefined error".  The incoming error number is
;then converted to its negative counterpart so it may be searched in the
;table of text messages.
;
;Once the correct message has been located, the length of the string in the
;following byte is put in CX, and the message is copied into near memory.
;A BASIC string function must leave both its descriptor and its output in
;DGROUP, and then exit with AX holding the address of the descriptor.
;Because all of the QuickPak Professional DOS routines already reserve a
;hundred and twenty or so bytes in near memory, no additional memory is
;taken from the BASIC program.
;
;You may freely add or modify the messages in this routine, or use it as
;the basis for similar string functions.  The limitations are as follows:
;
;    1) No message may have a number higher than 127
;    2) No message string may be longer than 127 bytes
;    3) No message may contain an extended character (ASCII > 127)
;
;If an incoming message number is not in the table of negative values, the
;routine will default to the last message in the list.


.Model Medium, Basic
.Data
    DescrLen   DW 0                ;this is the function's descriptor
    DescrAdr   DW Offset File_Name ;show BASIC where the string is
    Extrn      File_Name:Byte      ;where we'll leave function output

.Code
    Include Mixed.Inc

HProc ErrorMsg, <Uses DS>, ErrNum:Ptr

    Mov  SI,ErrNum           ;get the address for ErrNum
    Mov  AX,[SI]             ;put it into AX
    Cmp  AX,128              ;is it an illegal value?
    Jb   GoodError           ;no, continue
    Mov  AL,127              ;yes, so let it default to "Undefined error"

GoodError:
    Neg  AL                  ;make a negative version to search the table

    Mov  CX,Offset EndTable - Offset ErrName   ;how many bytes to search
    Push CS                  ;set ES=CS for searching
    Pop  ES
    Mov  DI,Offset ErrName   ;point DI to the start of the table
    Repne Scasb              ;search for the negative error number
    Mov  SI,DI               ;point SI to the length word in the table

    Push DS                  ;set ES=DS and DS=CS to copy string into DGroup
    Push CS
    Pop  DS
    Pop  ES

    Lodsb                    ;get the length of the message
    Cbw                      ;convert it to a word
    Mov  CX,AX               ;now CX holds the copy byte count
    Mov  DI,Offset DescrLen  ;get the address for DescrLen
    Stosw                    ;now DescrLen shows how long the function is

Default:
    Mov  DI,Offset File_Name ;and now DI points to the function output area
    Rep  Movsb               ;copy the string

Exit:
    Mov  AX,Offset DescrLen  ;show BASIC where the descriptor is located
    HRet                     ;return to BASIC

HEndp

    ErrName DB  -7, 13, "Out of memory"
            DB -14, 19, "Out of string space"
            DB -25, 12, "Device fault"
            DB -27, 12, "Out of paper"
            DB -52, 15, "Bad file number"
            DB -53, 14, "File not found"
            DB -57, 16, "Device I/O error"
            DB -58, 19, "File already exists"
            DB -61, 12, "Disk is full"
            DB -62, 14, "Input past end"
            DB -64, 12, "Bad filename"
            DB -67, 17, "Directory is full"
            DB -68, 18, "Device unavailable"
            DB -70, 23, "Write protect violation"
            DB -71, 15, "Drive not ready"
            DB -72, 16, "Disk media error"
            DB -73, 21, "Network not installed"
            DB -74, 19, "Rename across disks"
            DB -75, 13, "Access denied"
            DB -76, 14, "Path not found"
            DB -77, 18, "Invalid drive spec"
            DB -78, 16, "Too many handles"
            DB -79, 13, "Bad FAT image"
            DB -80, 17, "Invalid time data"
            DB -81, 17, "Invalid date data"
            DB -82, 17, "Invalid parameter"
            DB -83, 16, "Buffer too small"
            DB -84, 25, "Current directory renamed"
            DB -85, 16, "Locking conflict"
            DB -86, 16, "Sharing conflict"
            DB -87, 18, "Read-only conflict"
            DB -100,31, "Insufficient number of elements"
EndTable Label Byte
            DB      15, "Undefined error"

End
