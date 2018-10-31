;********** Assembly.Asm

;This is a sample assembler program that shows how to set up calls and
;variables for use with QuickPak Professional assembler subroutines.


DosSeg                            ;mandatory to establish DOS segment order

IncludeLib Pro                    ;tell LINK to look in PRO.LIB automatically
;IncludeLib YourLib               ;you may also specify additional libraries

.Model  Medium                    ;medium allows 64K data, unlimited code
.Stack  1000                      ;reserve 1000 bytes for a stack

;----- start of data segment - variables listed as encountered in the program

.Data

        Extrn MonSeg:   Word      ;this is in Monitor.Asm, tells display type
        ScrnColor       DW 7      ;default to mono color for the screen
        CsrSiz          DW ?      ;save the current cursor parameters here
        CsrLoc          DW ?
        OldAX           DW ?      ;saves the registers trashed by Int 10h
        OldBX           DW ?
        OldCX           DW ?
        OldDX           DW ?
        OldBP           DW ?

        DescrLen        DW ?      ;this holds a "scratch" string descriptor
        DescrAdr        DW ?

        ScrnArray       DW 2000 Dup (?)      ;holds the DOS screen
        FileNames       DB 300 * 12 Dup (?)  ;holds the file names

        ULRow           DW ?                 ;we'll assign these later
        ULCol           DW ?                 ;  just to show how it's done
        LRRow           DW ?
        LRCol           DW ?

        Spec$           DW Offset Spec$Done - Offset Spec$Data
        Spec$Addr       DW Offset Spec$Data
        Spec$Data       DB "*.*",30 Dup (32) ;holds the file specification
        Spec$Done       Label Byte

        ALen            DW 0                 ;we'll initialize these here
        SCode           DW 0                 ;  to show an alternate method
        Num             DW 0
        Cap             DW 0
        NormClr         DW 112
        EditClr         DW 112
        Row             DW 5
        Col             DW 30

        Const2          DW 2                 ;this shows how to use constants
        Const6          DW 6                 ;  as parameters in a Call
        Const9          DW 9
        Const20         DW 20
        Const72         DW 72

        Message1        DW Offset Msg1Done - Offset Msg1Data
        Msg1Addr        DW Offset Msg1Data
        Msg1Data        DB "Enter a file specification:"
        Msg1Done        Label Byte

        Message2        DW Offset Msg2Done - Offset Msg2Data
        Msg2Addr        DW Offset Msg2Data
        Msg2Data        DB "Too many files, must be three hundred or less"
        Msg2More        DB " - press a key"
        Msg2Done        Label Byte

        Message3        DW Offset Msg3Done - Offset Msg3Data
        Msg3Addr        DW Offset Msg3Data
        Msg3Data        DB "No matching files - press a key"
        Msg3Done        Label Byte

        Message4        DW Offset Msg4Done - Offset Msg4Data
        Msg4Addr        DW Offset Msg4Data
        Msg4Data        DB "You picked choice number"
        Msg4Done        Label Byte

        Count           DW ?

        Start           DW ?
        Lenth           DW ?
        HColor          DW ?
        Rows            DW ?
        Cols            DW ?
        Gap             DW ?

;----- start of code segment

.Code

;-----  declare the external procedures that will be called by this program

        Extrn AMenuT     :Proc
        Extrn Box0       :Proc
        Extrn ClearScr0  :Proc
        Extrn Editor     :Proc
        Extrn QPrint0    :Proc
        Extrn ReadFileT  :Proc
        Extrn ScrnRest0  :Proc
        Extrn ScrnSave0  :Proc
        Extrn WaitKey    :Proc

        Extrn FCount     :Proc
        Extrn Monitor    :Proc
        Extrn QPStrI     :Proc
        Extrn QPTrim     :Proc

;----- macro to locate the cursor

Locate  Macro Row, Column         ;accepts a row and column as arguments
        Call  PushAll             ;save the registers it uses
        Mov   AH,0Fh              ;get the video mode so we'll know the page
        Int   10h                 ;BH returns page, then passed to service 2
        Mov   DH,Row - 1          ;adjust 1-25 to 0-24
        Mov   DL,Column - 1       ;adjust 1-80 to 0-79
        Mov   AH,2                ;set cursor position service
        Int   10h                 ;call the video BIOS
        Call  PopAll              ;restore registers
Endm

;----- macro to save the current cursor parameters

SaveCursor Macro
        Call  PushAll
        Mov   AH,0Fh              ;get the video page for service 3 below
        Int   10h
        Mov   AH,3                ;get current cursor parameters
        Int   10h
        Mov   CsrLoc,DX
        Mov   CsrSiz,CX
        Call  PopAll
Endm

;----- macro to restore the previously saved cursor parameters

RestoreCursor Macro
        Call  PushAll
        Mov   AH,0Fh              ;get the video page for services 1+2 below
        Int   10h
        Mov   CX,CsrSiz
        Mov   AH,1
        Int   10h
        Mov   DX,CsrLoc
        Mov   AH,2
        Int   10h
        Call  PopAll
Endm

;----- mandatory startup code

Begin:
        Mov  AX,@Data             ;assign DS to the correct segment
        Mov  DS,AX

        Cli                       ;fudge SS:SP so SS can be the same as DS
        Mov  SS,AX
        Mov  SP,Offset Stack
        Sti

;----- start of program - determine the screen colors to use

        Call Monitor              ;monitor must be run to obtain video segment
        Cmp  MonSeg,0B000h        ;are we running on a mono display?
        Je   DoneMonitor          ;yes, skip ahead
        Mov  ScrnColor,23         ;no, use white on blue for screen colors

DoneMonitor:

;----- save the current screen

    ;ULRow = 1
        Mov  ULRow,1

    ;ULCol = 1
        Mov  ULCol,1

    ;LRRow = 25
        Mov  LRRow,25

    ;LRCol = 80
        Mov  LRCol,80

    ;ScrnSave0 ULRow, ULCol, LRRow, LRCol, SEG ScrnArray(1)
        SaveCursor                ;this isn't in the BASIC source code, but
                                  ;  it's needed to save the cursor size/loc
        Mov  AX,Offset ULRow
        Push AX
        Mov  AX,Offset ULCol
        Push AX
        Mov  AX,Offset LRRow
        Push AX
        Mov  AX,Offset LRCol
        Push AX
        Push DS
        Mov  AX,Offset ScrnArray
        Push AX
        Call ScrnSave0

    ;ClearScr0 ULRow, ULCol, LRRow, LRCol, ScrnColor
        Mov  AX,Offset ULRow
        Push AX
        Mov  AX,Offset ULCol
        Push AX
        Mov  AX,Offset LRRow
        Push AX
        Mov  AX,Offset LRCol
        Push AX
        Mov  AX,Offset ScrnColor
        Push AX
        Call ClearScr0

    ;LOCATE 5, 1
        Locate 5, 1

    ;QPrint0 "Enter a file specification:", ScrnColor
        Mov  AX,Offset Message1
        Push AX
        Mov  AX,Offset ScrnColor
        Push AX
        Call QPrint0

    ;Editor Spec$, ALen, SCode, Num, Cap, NormClr, EditClr, Row, Col
        Mov  AX,Offset Spec$
        Push AX
        Mov  AX,Offset ALen
        Push AX
        Mov  AX,Offset SCode
        Push AX
        Mov  AX,Offset Num
        Push AX
        Mov  AX,Offset Cap
        Push AX
        Mov  AX,Offset NormClr
        Push AX
        Mov  AX,Offset EditClr
        Push AX
        Mov  AX,Offset Row
        Push AX
        Mov  AX,Offset Col
        Push AX
        Call Editor

    ;Count = FCount%(QPTrim$(Spec$))
        Mov  AX,Offset Spec$      ;show QPTrim where Spec$ is located
        Push AX
        Call QPTrim               ;QPTrim returns a descriptor address in AX
        Push AX                   ;now pass that on to FCount
        Call FCount               ;FCount returns the count in AX
        Mov  Count,AX             ;save the count in the variable Count

    ;IF Count > 300 THEN          ;we must see if Count is <= 300 rather
        Cmp  AX,300               ;  than > 300
        Jbe  ZeroCount            ;not more than 300, but see if it's zero
        Locate 7, 1
        Mov  AX,Offset Message2   ;as above
        Push AX
        Mov  AX,Offset ScrnColor
        Push AX
        Call QPrint0
        Jmp  BadEnd

ZeroCount:
    ;IF Count = 0 THEN            ;likewise, we'll jump ahead if Count <> 0
        Or   AX,AX                ;Or is faster and creates less code than Cmp
        Jnz  GoodCount            ;as above
        Locate 7, 1
        Mov  AX,Offset Message3
        Push AX
        Mov  AX,Offset ScrnColor
        Push AX
        Call QPrint0
        Jmp  BadEnd

GoodCount:
    ;ReadFileT QPTrim$(Spec$), VARSEG(FileNames(1)), VARPTR(FileNames(1))
        Mov  AX,Offset Spec$
        Push AX
        Call QPTrim
        Push AX                   ;push descriptor address returned by QPTrim
        Push DS                   ;push VARSEG of FileNames array
        Mov  AX,Offset FileNames  ;then get and push VARPTR of FileNames(1)
        Push AX
        Call ReadFileT

    ;Box0 9, 6, 20, 72, 2, ScrnColor
        Mov  AX,Offset Const9     ;of course, these are really "variables"
        Push AX
        Mov  AX,Offset Const6
        Push AX
        Mov  AX,Offset Const20
        Push AX
        Mov  AX,Offset Const72
        Push AX
        Mov  AX,Offset Const2
        Push AX
        Mov  AX,Offset ScrnColor
        Push AX
        Call Box0

    ;Start = 1, Length = 12, etc.
        Mov  Start,1
        Mov  Lenth,12
        Mov  HColor,15
        Mov  Rows,10
        Mov  Cols,4
        Mov  Gap,5
        Mov  Row,10
        Mov  Col,8

    ;AMenuT VARSEG(FileNames(1)), VARPTR(FileNames(1)), Start, Length, _
    ;       Count, SCode, NormClr, HColor, Rows, Cols, Gap, Row, Col
        Push DS
        Mov  AX,Offset FileNames
        Push AX
        Mov  AX,Offset Start
        Push AX
        Mov  AX,Offset Lenth
        Push AX
        Mov  AX,Offset Count
        Push AX
        Mov  AX,Offset SCode
        Push AX
        Mov  AX,Offset NormClr
        Push AX
        Mov  AX,Offset HColor
        Push AX
        Mov  AX,Offset Rows
        Push AX
        Mov  AX,Offset Cols
        Push AX
        Mov  AX,Offset Gap
        Push AX
        Mov  AX,Offset Row
        Push AX
        Mov  AX,Offset Col
        Push AX
        Call AMenuT

    ;LOCATE 22, 1
        Locate 22, 1

    ;QPrint0 "You picked choice number", ScrnColor
        Mov  AX,Offset Message4
        Push AX
        Mov  AX,Offset ScrnColor
        Push AX
        Call QPrint0

    ;LOCATE 22,26
        Locate 22, 26

    ;QPrint0 QPStrI$(Count), ScrnColor
        Mov  AX,Offset Count
        Push AX
        Call QPStrI
        Push AX
        Mov  AX,Offset ScrnColor
        Push AX
        Call QPrint0

    ;LOCATE 22, 30
        Locate 22, 30

    ;QPrint0 FileNames(Count), ScrnColor
        Mov  CX,12                      ;the length of each array element
        Mov  DescrLen,CX                ;assign the length part of descriptor
        Mov  DescrAdr,Offset FileNames  ;point descriptor to FileNames(Count)
        Mov  AX,Count                   ;get count
        Dec  AX                         ;adjust to zero-based
        Mul  CL                         ;multiply for offset into the array
        Add  DescrAdr,AX                ;now descriptor points to correct name
        Mov  AX,Offset DescrLen         ;show QPrint0 where the descriptor is
        Push AX
        Mov  AX,Offset ScrnColor        ;and where ScrnColor is too
        Push AX
        Call QPrint0

BadEnd:
    ;WaitKey
        Call WaitKey

    ;ScrnRest0 ULRow, ULCol, LRRow, LRCol, ScrnArray(1)
        Mov  AX,Offset ULRow      ;set up for call to ScrnRest0
        Push AX
        Mov  AX,Offset ULCol
        Push AX
        Mov  AX,Offset LRRow
        Push AX
        Mov  AX,Offset LRCol
        Push AX
        Push DS
        Mov  AX,Offset ScrnArray
        Push AX
        Call ScrnRest0
        RestoreCursor             ;restore the cursor too

    ;END
        Mov  AX,4C00h             ;exit with ERRORLEVEL set to 0
        Int  21h

PushAll Proc Near                 ;saves all necessary registers
        Mov  OldAX,AX
        Mov  OldBX,BX
        Mov  OldCX,CX
        Mov  OldDX,DX
        Mov  OldBP,BP             ;some old PC BIOS's trash BP during Int 10h
        Ret                       ;  though it doesn't really matter here
PushAll Endp

PopAll Proc Near                  ;restores all necessary registers
        Mov  AX,OldAX
        Mov  BX,OldBX
        Mov  CX,OldCX
        Mov  DX,OldDX
        Mov  BP,OldBP
        Ret
PopAll Endp

End Begin
