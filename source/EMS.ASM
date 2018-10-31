;=============================================================================
; EMS.ASM - Expanded memory (LIM 3.x/4.x) routines for BASIC
;
; Copyright (c) 1988 Crescent Software
;
; Author: Jeff Prosise
; Enhancements: Ethan Winer
; Date:   December 1988
;=============================================================================
;
; All functions and subroutines with the exception of EmsLoaded return zero
; in the EmsError function if successful.  If a call fails, the error code
; passed back by the EMS driver is returned in EmsError.
;
; EMS Error Codes -- codes below 80H (128) are not "official" EMS codes
;
;       Hex   Dec
;       ---   ---
;       00H     0  No error
;       01H     1  EmsLoaded hasn't been used yet to initialize these routines
;       02H     2  The length of each element was given as zero
;       03H     3  The number of elements to copy was given as zero
;       80H   128  Internal error in EMS device driver
;       81H   129  Hardware malfunction
;       83H   131  Invalid EMS handle
;       84H   132  Function requested is undefined
;       85H   133  No more handles are available
;       86H   134  Memory deallocation error
;       87H   135  Too many logical pages requested
;       88H   136  Too many logical pages requested
;       89H   137  Zero logical pages requested
;       8AH   138  Logical page number requested is out-of-range for handle
;       8BH   139  Physical page requested is out-of-range


.Model Medium
.Data

        EmsErr   DB ?                   ;EMS error code
        EmsName  DB "EMMXXXX0"          ;EMS device driver name
        EmsPFSeg DW 0                   ;EMS page frame segment

.Code

        Extrn Code2Num:Far
        Include Mixed.Inc


;-----------------------------------------------------------------------------
; Function EmsError - Returns the status (0 or error number) of EMS calls.
;
; Syntax: IF EmsError THEN PRINT "EMS Error number"; EmsError; "occurred."
;
; EmsError simply returns the EmsErr public variable used by all of the
; various EMS routines, so the programmer can determine whether the most
; recent EMS operation succeeded or failed.
;-----------------------------------------------------------------------------
HProc   EmsError
        Mov     AL,EmsErr               ;load the EmsErr variable into AL
        Xor     AH,AH                   ;clear AH so we can use all of AX
        HRet                            ;return to BASIC
HEndp



;-----------------------------------------------------------------------------
; Subroutine EmsSetError - Sets the status (0 or error number) of EmsError.
;
; Syntax: CALL EmsSetError(ErrValue%)
;
; EmsSetError allows a BASIC routine to set or clear the public error
; function EmsError for later access by other BASIC programs.
;
;-----------------------------------------------------------------------------
HProc   EmsSetError, ErrCode:Ptr
        Mov     SI,ErrCode              ;get the address for ErrCode%
        Mov     AL,[SI]                 ;put the value into AL
        Mov     EmsErr,AL               ;and then into EmsErr
        HRet                            ;return to BASIC
HEndp



;-----------------------------------------------------------------------------
; Function EmsLoaded - Checks for the presence of an EMS driver.
;
; Syntax: IF EmsLoaded THEN . . .
;
; EmsLoaded checks for the presence of an EMS device driver
; and returns -1 if one is found, 0 if not.  To save time and to let the
; other EMS routines also know if EMS is available, the Page Frame segment
; is used to see if this function has already been invoked.
;-----------------------------------------------------------------------------
HProc   EmsLoaded
        Mov     AX,-1                   ;assume the driver is loaded
        Cmp     EmsPFSeg,0              ;is the page frame segment known?
        Jne     LoadedExit              ;yes, so it must be installed

        Mov     AX,3567H                ;get interrupt 67H vector
        Int     21H
        Mov     DI,0AH                  ;ES:DI => device name
        Mov     SI,Offset EmsName       ;DS:SI => "EMMXXXX0"
        Mov     CX,4                    ;EMS driver found if logical
        Cld                             ;  name of the driver that
        Repe    Cmpsw                   ;  handles interrupt 67H is
        Je      GetEmsPFSeg             ;  "EMMXXXX0"

        Xor     AX,AX                   ;driver not found -- return 0
        Jmp     Short LoadedExit        ;and exit

GetEmsPFSeg:
        Mov     AH,41H                  ;get the Page Frame segment from the
        Int     67H                     ;  EMS driver and store it
        Mov     EmsErr,AH               ;  for future use
        Or      AH,AH                   ;was there an error?
        Jnz     LoadedExit              ;yes, exit
        Mov     EmsPFSeg,BX             ;save the Page Frame segment
        Mov     AX,-1                   ;and show that the driver is loaded

LoadedExit:
        HRet
HEndp



;-----------------------------------------------------------------------------
; Function EmsVersion - Returns the EMM version number.
;
; Syntax: PRINT "EMS version number"; EmsVersion; "is installed."
;
; EmsVersion returns a value that represents the version number of
; the expanded memory driver multipled by 100, i.e., 4.0 returns 400,
; 3.2 returns 320.
;-----------------------------------------------------------------------------
HProc   EmsVersion
        Xor     AX,AX                   ;assume an error
        Mov     EmsErr,1
        Cmp     EmsPFSeg,AX             ;is the page frame segment known?
        Je      EmsVerExit              ;no, so they haven't use EmsLoaded

        Mov     AH,46H                  ;call EMS function
        Int     67H
        Mov     EmsErr,AH               ;set error code
        Or      AH,AH                   ;exit on error
        Jnz     EmsVerExit

        Mov     DL,AL                   ;save value returned in AL
        And     DL,0FH                  ;mask off upper 4 bits
        Mov     BL,10                   ;initialize BL with multiplier
        Mov     CL,4                    ;multiply the BCD number in the
        Shr     AL,CL                   ;  upper 4 bits of AL (major
        Mul     BL                      ;  version number) by 10

        Add     AL,DL                   ;add minor version number and
        Mul     BL                      ;  multiply by 10 again

EmsVerExit:
        HRet
HEndp



;-----------------------------------------------------------------------------
; Function EmsGetPFSeg - Gets the current EMS page frame segment
;
; Syntax: PRINT "The current page frame segment is"; EmsGetPFSeg%
;
;-----------------------------------------------------------------------------
HProc   EmsGetPFSeg
        Mov     EmsErr,0                ;assume no error
        Mov     AX,EmsPFSeg             ;get the page frame segment
        Or      AX,AX                   ;did they use EmsLoaded yet?
        Jnz     GPFSExit                ;yes, skip ahead
        Mov     EmsErr,1                ;no, set the error variable

GPFSExit:
        HRet                            ;return to BASIC
HEndp



;-----------------------------------------------------------------------------
; Function EmsPageCount - Returns the total number of EMS pages present.
;
; Syntax: PRINT "This system has a total of"; EmsPageCount; "16K pages."
;
; EmsPageCount allows the programmer to determine how many 16K expanded
; memory pages are present (allocated and unallocated) in the system.
;-----------------------------------------------------------------------------
HProc   EmsPageCount
        Xor     AX,AX                   ;assume an error
        Mov     EmsErr,1
        Cmp     EmsPFSeg,AX             ;is the page frame segment known?
        Je      EmsPCExit               ;no, EMSInstalled hasn't been used yet

        Mov     AH,42H                  ;call EMS function
        Int     67H
        Mov     EmsErr,AH               ;set error code
        Or      AH,AH                   ;exit on error
        Jnz     EmsPCExit

        Mov     AX,DX                   ;get page count in AX for return

EmsPCExit:
        HRet
HEndp



;-----------------------------------------------------------------------------
; Function EmsPagesFree - Returns the number of unallocated EMS pages.
;
; Syntax: PRINT "There are currently"; EmsPagesFree; "free 16K pages in EMS."
;
; EmsPagesFree allows the programmer to determine how many 16K expanded
; memory pages are currently unallocated and available for use.
;-----------------------------------------------------------------------------
HProc   EmsPagesFree
        Xor     AX,AX                   ;assume an error
        Mov     EmsErr,1
        Cmp     EmsPFSeg,AX             ;is the page frame segment known?
        Je      EmsPFExit               ;no, EMSInstalled hasn't been used yet

        Mov     AH,42H                  ;call EMS function
        Int     67H
        Mov     EmsErr,AH               ;set error code
        Or      AH,AH                   ;exit on error
        Jnz     EmsPFExit

        Mov     AX,BX                   ;move count into AX for return

EmsPFExit:
        HRet
HEndp



;-----------------------------------------------------------------------------
; Subroutine EmsAllocMem - Requests memory and handle.
;
; Syntax: CALL EmsAllocMem(NumPages%, Handle%)
;         NumPages% = Number of 16K pages requested
;         Handle%   = Variable handle is returned in
;
; EmsAllocMem requests the allocation of the specified number of 16K
; expanded memory pages.  If the call succeeds, the handle assigned by
; the EMS driver is deposited in Handle%.  EmsAllocMem will fail if
; the number of pages requested is greater than the number available.
;-----------------------------------------------------------------------------
HProc   EmsAllocMem, NumPages:Ptr, Handle:Ptr
        Xor     DX,DX                   ;assume an error
        Mov     EmsErr,1
        Cmp     EmsPFSeg,DX             ;is the page frame segment known?
        Je      EmsAMError              ;no, EMSInstalled hasn't been used yet

        Mov     AH,43H                  ;call EMS function with number of
        Mov     SI,NumPages             ;  pages requested in BX
        Mov     BX,[SI]
        Int     67H
        Mov     EmsErr,AH               ;set error code

EmsAMError:
        Mov     SI,Handle               ;deposit handle in Handle%
        Mov     [SI],DX

EmsAMExit:
        HRet
HEndp



;-----------------------------------------------------------------------------
; Subroutine EmsRelMem - Releases the memory associated with a handle.
;
; Syntax: CALL EmsRelMem(Handle%)
;         Handle% = Handle number
;
; EmsRelMem permits memory allocated with EmsAllocMem to be released.
; All pages associated with the specified handle are freed.
;-----------------------------------------------------------------------------
HProc   EmsRelMem, Handle:Ptr
        Mov     AH,1                    ;assume an error
        Cmp     EmsPFSeg,0              ;is the page frame segment known?
        Je      EmsRMExit               ;no, EMSInstalled hasn't been used yet

        Mov     AH,45H                  ;call EMS function with handle
        Mov     SI,Handle               ;  in DX
        Mov     DX,[SI]
        Int     67H

EmsRMExit:
        Mov     EmsErr,AH               ;set error code
        HRet
HEndp



;-----------------------------------------------------------------------------
; Function EmsNumPages - Returns the number of pages assigned to a handle.
;
; Syntax: PRINT "There are"; EmsNumPages(Handle%); "16K pages assigned."
;         Handle% = Handle number
;
; EmsNumPages allows the programmer to determine how many 16K pages are
; associated with the specified handle.
;-----------------------------------------------------------------------------
HProc   EmsNumPages, Handle:Ptr
        Xor     AX,AX                   ;assume an error
        Mov     EmsErr,1
        Cmp     EmsPFSeg,AX             ;is the page frame segment known?
        Je      EmsNPExit               ;no, EMSInstalled hasn't been used yet

        Mov     AH,4CH                  ;call EMS function with handle
        Mov     SI,Handle               ;  in DX
        Mov     DX,[SI]
        Int     67H
        Mov     EmsErr,AH               ;set error code
        Or      AH,AH                   ;exit on error
        Jnz     EmsNPExit

        Mov     AX,BX                   ;Page count in AX for return

EmsNPExit:
        HRet
HEndp



;-----------------------------------------------------------------------------
; Function EmsSetPage - sets the logical EMS page to map into physical memory
;
; Syntax: CALL EmsSetPage(Page%, Handle%)
;
; Only one page of EMS memory is active in "near" memory at a time.  This
; routine allows setting which EMS logical page is mapped into physical page
; zero.  Once this is done, any portion of expanded memory may be PEEKed and
; POKED as if it were regular memory.  The EMS software considers the first
; page to be number 0, but this routine accepts page numbers starting at 1.
;-----------------------------------------------------------------------------
HProc EmsSetPage, PageNum:Ptr, Handle:Ptr
        Mov     EmsErr,1                ;assume an error
        Cmp     EmsPFSeg,0              ;is the page frame segment known?
        Je      SPExit                  ;no, they never used EmsLoaded

        Mov     SI,PageNum              ;get the address for Page%
        Mov     BX,[SI]                 ;put it into BX
        Dec     BX                      ;adjust 1 to n down to 0 to n-1
        Mov     SI,Handle               ;put the handle into DX
        Mov     DX,[SI]

        Mov     AX,4400h                ;service 44h, physical page 0
        Int     67H                     ;call EMS
        Mov     EmsErr,AH               ;set the error status

SPExit:
        HRet                            ;return to BASIC
HEndp



;-----------------------------------------------------------------------------
; Subroutine Array2Ems - Copies an entire array into expanded memory.
;
; Syntax: DECLARE SUB Array2Ems(SEG Element AS ANY, ElSize%, NumEls%, Handle%)
;         CALL Array2Ems(SEG Array(Start), ElSize%, NumEls%, Handle%)
;         Array(Start) = the first element in the array to copy to EMS memory
;         ElSize%      = the length of an element (ie: 2 or -1 for integer)
;         NumEls%      = the number of elements to copy
;         Handle%      = the handle number returned to you for later access
;
; Array2Ems copies the specified array into Ems memory, and returns a handle
; which is used later to retrieve the array again later.  Non-array memory
; such as a display screen may also be copied into EMS by replacing the SEG
; Array(Start) with the sequence BYVAL Segment, BYVAL Address.
;-----------------------------------------------------------------------------
HProc   Array2Ems, <Uses DS>, Array:DWord, ElSize:Ptr, NumEls:Ptr, Handle:Ptr
        Mov     EmsErr,1                ;assume an error
        Cmp     EmsPFSeg,0              ;is the page frame segment known?
        Je      A2EExit                 ;no, EMSInstalled hasn't been used yet

        Mov     SI,ElSize               ;see how long each element is
        Mov     CX,[SI]                 ;put it in CX
        Mov     SI,NumEls               ;how many elements are there?
        Mov     AX,[SI]                 ;put NumEls% into AX
        Call    CalcEls                 ;calculate number of bytes and pages
        Cmp     EmsErr,0                ;did CalcEls encounter an error?
        Jnz     A2EExit                 ;yes, get out

        Mov     BX,AX                   ;put the number of pages into BX
        Mov     AH,43H                  ;allocate EMS memory service
        Int     67H                     ;call EMS to do it
        Mov     EmsErr,AH               ;set EmsError to reflect what happened
        Mov     SI,Handle               ;assign Handle% to the handle we got
        Mov     [SI],DX
        Or      AH,AH                   ;was there an error?
        Jnz     A2EExit                 ;yes, get out now

        Mov     ES,EmsPFSeg             ;set ES to the EMS Page Frame segment
        Lds     SI,Array                ;point DS:SI to the array
        Cld                             ;all moves are forward

A2EMoveLoop:
        Mov     CX,16 * 1024            ;assume we're copying a complete page
        Mov     BX,CS:CurPage           ;get the current logical page
        Cmp     BX,CS:TotPages          ;any more complete pages to do?
        Ja      A2EExit                 ;no, and we did already the remainder
        Jb      A2EDoFull               ;yes, and CX already holds 16384
        Mov     CX,CS:Remainder         ;no, but copy what remains
        Jcxz    A2EExit                 ;there is no remainder, we're all done

A2EDoFull:
        Dec     BX                      ;adjust page number to be zero based
        Mov     AX,4400H                ;map the current logical page held
        Int     67H                     ;  in BX to physical page zero

        Or      SI,SI                   ;is the array near a segment boundary?
        Jns     A2ENoSpan               ;no, skip ahead
        And     SI,7FFFh                ;yes, subtract 32K from the address
        Mov     BX,DS                   ;and add 800h to segment to compensate
        Add     BX,800h
        Mov     DS,BX

A2ENoSpan:
        Xor     DI,DI                   ;start copying to the page start
        Rep     Movsb                   ;copy the data
        Inc     CS:CurPage              ;show that we did another page
        Jmp     Short A2EMoveLoop       ;and go do some more

A2EExit:
        HRet
HEndp



;-----------------------------------------------------------------------------
; Subroutine Ems2Array - Copies an entire array from expanded memory.
;
; Syntax: DECLARE SUB Ems2Array(SEG Element AS ANY, ElSize%, NumEls%, Handle%)
;         CALL Ems2Array(SEG Array(Start), ElSize%, NumEls%, Handle%)
;         Array(Start) = the first array element to copy from EMS memory
;         ElSize%      = the length in an element (ie: 2 or -1 for integer)
;         NumEls%      = the number of elements to copy
;         Handle%      = the handle number returned to you for later access
;
; Ems2Array copies the specified array from Ems memory, based on the handle
; that was returned when Array2Ems was used perviously.  Non-array memory
; such as a display screen may also be copied from EMS by replacing the SEG
; Array(Start) with the sequence BYVAL Segment, BYVAL Address.
;-----------------------------------------------------------------------------
HProc   Ems2Array, Array:DWord, ElSize:Ptr, NumEls:Ptr, Handle:Ptr
        Mov     EmsErr,1                ;assume an error
        Cmp     EmsPFSeg,0              ;is the page frame segment known?
        Je      E2AExit                 ;no, EMSInstalled hasn't been used yet

        Mov     SI,ElSize               ;see how long each element is
        Mov     CX,[SI]                 ;put it in CX
        Mov     SI,NumEls               ;how many elements are there?
        Mov     AX,[SI]                 ;put NumEls% into AX
        Call    CalcEls                 ;calculate number of bytes and pages
        Cmp     EmsErr,0                ;did CalcEls encounter an error?
        Jnz     E2AExit                 ;yes, go away

        Mov     SI,Handle               ;get the EMS handle from the caller
        Mov     DX,[SI]                 ;EMS routines need this in DX
        Les     DI,Array                ;point ES:DI to the array
        Push    DS                      ;save DS before we destroy it below
        Mov     DS,EmsPFSeg             ;set DS to the EMS Page Frame segment
        Cld                             ;all moves are forward

E2AMoveLoop:
        Mov     CX,16 * 1024            ;assume we're copying a complete page
        Mov     BX,CS:CurPage           ;get the current logical page
        Cmp     BX,CS:TotPages          ;any more complete pages to do?
        Ja      ReleaseMem              ;no, and we already did the remainder
        Jb      E2ADoFull               ;yes, and CX already holds 16384
        Mov     CX,CS:Remainder         ;no, but copy what remains
        Jcxz    ReleaseMem              ;there is no remainder, we're all done

E2ADoFull:
        Dec     BX                      ;adjust page number to be zero based
        Mov     AX,4400H                ;map the current logical page held
        Int     67H                     ;  in BX to physical page zero
        Or      AH,AH                   ;did they give us an invalid handle?
        Jnz     E2AError                ;yes, go away

        Or      DI,DI                   ;is the array near a segment boundary?
        Jns     E2ANoSpan               ;no, skip ahead
        And     DI,7FFFh                ;yes, subtract 32K from the address
        Mov     BX,ES                   ;and add 800h to segment to compensate
        Add     BX,800h
        Mov     ES,BX

E2ANoSpan:
        Xor     SI,SI                   ;start copying from the page start
        Rep     Movsb                   ;copy the data
        Inc     CS:CurPage              ;show that we did another page
        Jmp     Short E2AMoveLoop       ;and go do some more

ReleaseMem:
;       Mov     AH,45H                  ;release memory that held the array
;       Int     67H                     ;Don didn't want this feature, so
                                        ;release the damn memory yourself
E2AError:
        Pop     DS                      ;to access EmsErr
        Mov     EmsErr,AH               ;set it to zero, unless an error

E2AExit:
        HRet
HEndp



;-----------------------------------------------------------------------------
; Subroutine EmsSet1El - Assigns a single element into expanded memory.
;
; Syntax: DECLARE SUB EmsSet1El(SEG Element AS ANY, ElSize%, ElNum%, Handle%)
;         CALL EmsSet1El(SEG Array(Element), ElSize%, ElNum%, Handle%)
;         Array(Element) = the element in the array to assign to EMS memory
;         ElSize%        = the length of an element (ie: 2 or -1 for integer)
;         ElNum%         = the element number to copy
;         Handle%        = the handle number that was assigned earlier
;
;patched 10-20-89:  Memory was not being assigned correcly when an element
;straddled a 16K segment boundary.  The code here (and in EmsGet1El) was
;fixed to simply allocate an extra page beyond the first one.  Even though it
;is likely that a subsequent page is invalid, who cares?  If it's not there,
;then it wasn't needed anyway and the EMS error can be (and is) ignored.  The
;corrections are identified below with asterisks (*****).
;-----------------------------------------------------------------------------
HProc   EmsSet1El, <Uses DS>, Array:DWord, ElSize:Ptr, ElNum:Ptr, Handle:Ptr
        Mov     EmsErr,1                ;assume an error
        Cmp     EmsPFSeg,0              ;is the page frame segment known?
        Je      ESEExit                 ;no, EMSLoaded hasn't been used yet

        Mov     SI,ElSize               ;see how long each element is
        Mov     CX,[SI]                 ;put it in CX
        Call    Code2Num                ;we need the actual element length
        Inc     EmsErr                  ;assume they slipped us a zero length
        Jcxz    ESEExit                 ;they did, get out with an error

        Mov     SI,ElNum                ;see which element they are assigning
        Mov     AX,[SI]                 ;put ElNum% into AX
        Inc     EmsErr                  ;assume they asked for element zero
        Or      AX,AX                   ;did they?
        Jz      ESEExit                 ;yes, go away

        Dec     AX                      ;adjust element number to base zero
        Mov     EmsErr,0                ;and clear the error code

        Mul     CX                      ;now DX:AX holds "absolute address"
        Push    CX                      ;save the number of bytes to copy
        Mov     CX,16 * 1024            ;divide DX:AX to get the page number
        Div     CX                      ;now AX holds page, DX holds offset
        Pop     CX                      ;retrieve the number of bytes to copy
        Mov     BX,AX                   ;copy the page number into BX
        Mov     DI,DX                   ;save the offset in DI for later

        Mov     SI,Handle               ;get the address for Handle%
        Mov     DX,[SI]                 ;put it into DX
        Mov     AX,4400h                ;service 44h, access EMS page zero
        Int     67h                     ;call the EMS driver
        Mov     EmsErr,AH               ;set EmsErr to reflect what happened
        Or      AH,AH                   ;was there an error?
        Jnz     ESEExit                 ;yes, get out now

        Inc     BX             ;line up 2nd page in case we span 16K ****
        Mov     AX,4401h       ;map this to physical page 1 *************
        Int     67h            ;call the EMS driver, ignore errors ******

        Mov     ES,EmsPFSeg             ;set ES to the EMS Page Frame segment
        Lds     SI,Array                ;point DS:SI to the array element
        Cld                             ;ensure forward string move
        Rep     Movsb                   ;do the move DS:SI ==> ES:DI

ESEExit:
        HRet
HEndp



;-----------------------------------------------------------------------------
; Subroutine EmsGet1El - Retrieves a single element from expanded memory.
;
; Syntax: DECLARE SUB EmsGet1El(SEG Element AS ANY, ElSize%, ElNum%, Handle%)
;         CALL EmsGet1El(SEG Array(Element), ElSize%, ElNum%, Handle%)
;         Array(Element) = the array element to retrieve from EMS memory
;         ElSize%        = the length of an element (ie: 2 or -1 for integer)
;         ElNum%         = the element number to copy
;         Handle%        = the handle number that was assigned earlier
;
;pathed 10-20-89: see the comments in EmsSet1El above.
;-----------------------------------------------------------------------------
HProc   EmsGet1El, <Uses DS>, Array:DWord, ElSize:Ptr, ElNum:Ptr, Handle:Ptr
        Mov     EmsErr,1                ;assume an error
        Cmp     EmsPFSeg,0              ;is the page frame segment known?
        Je      EGEExit                 ;no, EMSLoaded hasn't been used yet

        Mov     SI,ElSize               ;see how long each element is
        Mov     CX,[SI]                 ;put it in CX
        Call    Code2Num                ;we need the actual element length
        Inc     EmsErr                  ;assume they slipped us a zero length
        Jcxz    EGEExit                 ;they did, exit with the error

        Mov     SI,ElNum                ;see which element they're getting
        Mov     AX,[SI]                 ;put ElNum% into AX
        Inc     EmsErr                  ;assume they asked for element zero
        Or      AX,AX                   ;did they?
        Jz      EGEExit                 ;yes, go away

        Dec     AX                      ;adjust element number to base zero
        Mov     EmsErr,0                ;and clear the error code

        Mul     CX                      ;now DX:AX holds an "absolute address"
        Push    CX                      ;save the number of bytes to copy
        Mov     CX,16 * 1024            ;divide DX:AX to get the page number
        Div     CX                      ;now AX holds page, DX holds offset
        Pop     CX                      ;retrieve the number of bytes to copy
        Mov     BX,AX                   ;copy the page number into BX
        Mov     SI,DX                   ;save the offset in SI for later

        Mov     DI,Handle               ;get the address for Handle%
        Mov     DX,[DI]                 ;put it into DX
        Mov     AX,4400h                ;service 44h, access EMS page zero
        Int     67h                     ;call the EMS driver
        Mov     EmsErr,AH               ;set EmsErr to reflect what happened
        Or      AH,AH                   ;was there an error?
        Jnz     EGEExit                 ;yes, get out now

        Inc     BX             ;line up 2nd page in case we span 16K ******
        Mov     AX,4401h       ;map this to physical page 1 ***************
        Int     67h            ;call the EMS driver, ignore errors ********

        Les     DI,Array                ;point ES:DI to the array element
        Mov     DS,EmsPFSeg             ;set DS to the EMS Page Frame segment
        Cld                             ;ensure forward string move
        Rep     Movsb                   ;do the move DS:SI ==> ES:DI

EGEExit:
        HRet
HEndp



;calculate the number of bytes and 16K pages needed to copy the array
;this is set up as a subroutine because both Array2Ems and Ems2Array use it
CalcEls Proc Near
        Inc     EmsErr                  ;assume Error 2 (zero element length)
        Call    Code2Num                ;let Code2Num do most of the work
        Jcxz    BadExit                 ;we were right, zero element length

        Inc     EmsErr                  ;assume Error 3 (no elements to copy)
        Or      AX,AX                   ;is it indeed zero?
        Jz      BadExit                 ;yup, go away

        Mul     CX                      ;now DX:AX holds total number of bytes
        Mov     CX,16 * 1024            ;divide DX:AX by 16K to get the
        Div     CX                      ;  number of pages needed

        Xchg    CX,DX                   ;swap 'em to fudge a remainder
        Jcxz    NoRemainder             ;no remainder, skip ahead
        Inc     AX                      ;yes, we need another entire page
        Xchg    CX,DX                   ;so we don't have to "create" a
                                        ;  remainder of 16K
NoRemainder:
        Mov     CS:TotPages,AX          ;remember how many pages to copy
        Mov     CS:Remainder,DX         ;and the number of bytes that remain
        Mov     CS:CurPage,1            ;initialize the current page counter
        Mov     EmsErr,0                ;show a successful completion

BadExit:
        Ret                             ;return to the appropriate subroutine

CalcEls Endp

        ;these variables must be kept in the code segment because DS is not
        ;necessarily valid while they are being accessed

        CurPage   DW ?                  ;tracks the current page being copied
        TotPages  DW ?                  ;remembers how many pages to copy
        Remainder DW ?                  ;and the number of bytes that remain

End
