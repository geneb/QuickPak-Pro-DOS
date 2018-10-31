;----- FileInfo.Asm - retrieves full information on the named file

;Copyright (c) 1987 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;Syntax - DIM Array%(8)
;         FileName$ = "\Path\Filename.Ext"
;         CALL FileInfo(FileName$, SEG Array%(0))
;         IF Array%(0) = 0 THEN PRINT "File doesn't exist"
;
;         Errors are returned in DOS/WhichError.
;
;    Information is returned in Array%() as follows:        year  month day
;                                                          ______  ___  ____
;                                                         /      \/   \/    \
;    Array%(0) = Year    (80 - 99)        Date is packed: 1111 1111 1111 1111
;    Array%(1) = Month   (1 - 12)
;    Array%(2) = Day     (1 - 31)
;    Array%(3) = Hour    (0 - 23)         Time is packed: 1111 1111 1111 1111
;    Array%(4) = Minute  (0 - 59)                         \____/\_____/\____/
;    Array%(5) = Second  (0 - 59)                          hour   min   sec
;    Array%(6) = Size    (lo-word)
;    Array%(7) = Size    (hi-word)
;    Array%(8) = Attribute, bit coded as follows:
;
;                if bit 0 = 1 read-only
;                   bit 1 = 1 hidden
;                   bit 2 = 1 system
;                   bit 3 = 1 volume label (not used in this routine)
;                   bit 4 = 1 subdirectory
;                   bit 5 = 1 archive
;                   bit 6 & 7 unused
;
;if a wildcard (? or *) is used, the first matching file is reported


.Model Medium, Basic

.Data
    Extrn QPDTA:Byte      ;these are in External.Asm
    Extrn File_Name:Byte

.Code
    Include Mixed.Inc
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far
    Extrn Load_File:Far, DOS:Far

HProc FileInfo, FName:Ptr, ArrayAddr:DWord

    Mov  DX,CS               ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Lea  DX,QPDTA            ;put address of QPDTA in DX for set DTA service
    Mov  AH,1Ah              ;set DTA service - creates space for file names
    Call DOS                 ;call DOS to do it

    Mov  SI,FName            ;BX holds address of FileName$ descriptor
    Call Load_File           ;create an ASCIIZ string
    Jnc  Get_Array           ;if no error then continue
    Jmp  ErrExit             ;can't get there with a short jump

Get_Array:
    Les  SI,ArrayAddr        ;get segment and address of Array%(0)
    Mov  Word Ptr ES:[SI],0  ;set Array%(0) = 0 to show file not being there

    Mov  CL,00010110b        ;specify search to include all files
    Mov  AH,4Eh              ;find first matching file name service
    Call DOS                 ;call DOS to look for it
    Jc   ErrExit             ;if carry, the the file doesn't exist

Get_Data:
    Lea  DI,QPDTA            ;point DI to DTA for moving info into Array%()
    Mov  AX,[DI+24]          ;get date stamp
    And  AX,0FE00h           ;mask all but the year
    Mov  CL,9                ;prepare to shift bits 9 places
    Shr  AX,CL               ;align the bits
    Add  AX,1980             ;adjust to the correct year
    Mov  ES:[SI],AX          ;put the year into Array%(0)

    Mov  AX,[DI+24]          ;get the date again
    And  AX,1E0h             ;mask all but the month
    Mov  CL,5                ;prepare to shift bits 5 places
    Shr  AX,CL               ;shift 'em
    Mov  ES:[SI+02],AX       ;put the month into Array%(1)

    Mov  AX,[DI+24]          ;get the date again
    And  AX,1Fh              ;mask all but the day
    Mov  ES:[SI+04],AX       ;put the day into Array%(2)

    Mov  AX,[DI+22]          ;get time stamp
    And  AX,0F800h           ;mask all but the hours
    Mov  CL,11               ;prepare to shift bits 11 places
    Shr  AX,CL               ;do it
    Mov  ES:[SI+06],AX       ;put the hours into Array%(3)

    Mov  AX,[DI+22]          ;get the time again
    And  AX,7E0h             ;mask all but the minutes
    Mov  CL,5                ;5 places
    Shr  AX,CL
    Mov  ES:[SI+08],AX       ;put minutes into Array%(4)

    Mov  AX,[DI+22]          ;get the time again
    And  AX,1Fh              ;mask all but the seconds
    Shl  AX,1                ;seconds are stored on disk divided by two,
                             ;  so multiply to get actual seconds
    Mov  ES:[SI+10],AX       ;put seconds into Array%(5)

    Mov  AX,[DI+26]          ;get file size (lo-word)
    Mov  ES:[SI+12],AX       ;put it into Array%(6)

    Mov  AX,[DI+28]          ;get file size (hi-word)
    Mov  ES:[SI+14],AX       ;put it into Array%(7)

    Mov  AL,[DI+21]          ;get attribute
    Xor  AH,AH               ;convert byte to word in AX
    Mov  ES:[SI+16],AX       ;put attribute into Array%(8)
    Jmp  Short Exit

ErrExit:
    Call Load_DOSErr

Exit:
    Call Restore_CEH
    HRet

HEndp
End
