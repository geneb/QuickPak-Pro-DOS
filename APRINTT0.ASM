;----- APrintT0.Asm - like APrintT, but always prints on page zero

;Copyright (c) 1988 Ethan Winer
;revised by CWM to incorporate StoswSub & StosbSub instead of WritChar.Asm

;Syntax -
;   Locate V, H
;   CALL APrintT0(BYVAL VARSEG(A$(First)), BYVAL VARPTR(A$(First)), StrLen%, _
;        NumEls%, MidFirst%, NumChars%, Colr%)
;
;   where Colr% is the color to use, or -1 to honor the current colors.

.Model Medium
.Data

   Extrn MonSeg:Word        ;this is in Monitor.Asm
   Extrn CGAPort:Word       ;this too

.Code
Extrn Monitor: Proc
Extrn StosbSub: Proc
Extrn StoswSub: Proc
Include Mixed.Inc

HProc APrintT0, <Uses DS>, AAdr:DWord, StrLen:Ptr, NumEls:Ptr, MidFirst:Ptr, NumChars:Ptr, Colr:Ptr

    Cmp  MonSeg,0           ;has Monitor been used yet?
    Jnz  MonOkay            ;yes, skip ahead
    Call Monitor            ;no, call it to set the segment and retrace words

MonOkay:
    Mov  AH,0Fh             ;get the video mode through BIOS
    Push BP
    Int  10h                ;returns current page in BH, columns in AH
    Shl  AH,1               ;double the width for the calculations below
    Mov  CS:Wide,AH         ;and remember it for later

    Mov  AH,3               ;BIOS service to read the current cursor position
    Xor  BH,BH              ;use page zero
    Int  10h                ;enter with BH = page number,
    Pop  BP                 ;  returns with row/column in DH/DL
    Mov  BX,MonSeg          ;get the current monitor segment from Monitor.Asm

    Mov  AL,DH              ;put the current row number into AL
    Mov  CL,CS:Wide         ;multiply by Wide for base address of current row
    Mul  CL                 ;do the multiplication - answer ends up in AX
    Xor  DH,DH              ;clear DH for Add below, we only want DL
    Add  AX,DX              ;once for the character byte
    Add  AX,DX              ;and once for the attribute byte
    Mov  CS:Dest,AX         ;Dest now holds starting memory position on screen

    Mov  DX,CGAPort         ;get the CGA retrace port from Monitor.Asm
    Mov  ES,BX              ;set ES to point to the appropriate screen segment

    Mov  SI,Colr            ;get address of Colr%
    Mov  AH,[SI]            ;put it into AH for direct screen writing below

    Mov  SI,NumEls          ;get address of NumEls%
    Mov  BL,[SI]            ;put value into BL
    Mov  CS:Els,BL          ;and save it internally
    Mov  SI,MidFirst        ;get address of MidFirst%
    Mov  BX,[SI]            ;put value into BX
    Dec  BX                 ;adjust to base 0
    Mov  CS:First,BX        ;and save it
    Mov  CS:Last,BX         ;for now show First = Last
    Mov  SI,NumChars        ;get address of NumChars%
    Mov  BX,[SI]            ;number of characters to display into BX
    Add  CS:Last,BX         ;now last holds final char count
    Cld                     ;all string moves below will be forward

    Mov  BX,StrLen          ;get the length of each array element
    Mov  BX,[BX]
    Mov  CS:ElLength,BX     ;save it internally
    Lds  BP,AAdr            ;put address of Array$(First) into DS:BP
    Or   BP,BP              ;might we be about to cross a segment boundary?
    Jns  More               ;no, leave things as they are
    Sub  BP,8000h           ;yes, consider an address 32K less
    Mov  DI,DS              ;and add "32K" to DS (can't add to DS, use DI)
    Add  DI,800h            ;800h added to a segment is the same as 32K
    Mov  DS,DI

More:
    Mov  DI,CS:Dest         ;point DI to the destination address on the screen
    Mov  CX,CS:ElLength     ;put length of current Array$() into CX
    Mov  SI,BP              ;put address of its first character into SI

    Mov  BX,CS:First        ;put starting character number into BX
    Cmp  BX,CX              ;are we past the end of the string?
    Jae  Pad_Spc            ;yes, fill the rest of the screen with blanks
    Add  SI,BX              ;point SI to first character in string to print

Print:
    Cmp  AH,-1              ;are we leaving the current color alone?
    Lodsb
    Je   Print2             ;yes, skip over
    Call StoswSub           ;no, call Write_Both to use Colr%
    Jmp  Short Next_Char    ;and go on to the next character in the string

Print2:
    Call StosbSub           ;write just the character
    Inc  DI

Next_Char:
    Inc  BX                 ;show that we're about to print the next character
    Cmp  BX,CX              ;have we reached the end of the string?
    Jae  Pad_Spc            ;yes, fill the rest of the row with blanks
    Cmp  BX,CS:Last         ;are we finished with this element?
    Jae  Next_Element       ;yes, go on to the next one
    Jmp  Short Print        ;no, continue printing

Pad_Spc:
    Cmp  BX,CS:Last         ;are we finished filling the line with blanks?
    Jae  Next_Element       ;yes, go on to the next element

    Push SI                 ;save DS and SI for a moment
    Push DS
    Mov  SI,CS              ;point DS to the code segment to get at Blank
    Mov  DS,SI
    Lea  SI,Blank           ;point SI to the blank space in local storage

    Cmp  AH,-1              ;are we leaving the current color alone?
    Lodsb
    Je   Pad_Spc2           ;yes, skip over
    Call StoswSub           ;no, call Write_Both to use Colr%
    Jmp  Short Next_Spc     ;and go on to the next blank space

Pad_Spc2:
    Call StosbSub           ;write just the character
    Inc  DI

Next_Spc:
    Pop  DS                 ;get DS and SI back again
    Pop  SI
    Inc  BX                 ;consider the next column
    Jmp  Short Pad_Spc      ;and do it again

Next_Element:
    Dec  Byte Ptr CS:Els    ;show that we just completed another element
    Jz   Exit               ;no more, exit
    Add  BP,CS:ElLength     ;point to the next string element
    Mov  CL,CS:Wide         ;get the screen width into CL
    Xor  CH,CH              ;clear CH so we can use all of CX
    Add  CS:Dest,CX         ;point to the next screen row address
    Jmp  More               ;continue

Exit:
    HRet                    ;return to BASIC


    Els        DB    ?      ;holds number of elements to print
    First      DW    ?      ;holds number of first character to print
    Last       DW    ?      ;holds last character to be printed
    Dest       DW    ?      ;holds screen destination address
    Wide       DB    ?      ;holds width of screen (40 or 80)
    Blank      DB   32      ;holds a blank space for padding the screen
    ElLength   DW    ?      ;remembers the length of each string element

HEndp
End

