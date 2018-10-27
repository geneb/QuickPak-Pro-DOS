;----- APrint.Asm - Pro version prints on any video page

;Copyright (c) 1987 Ethan Winer
;revised by CWM to incorporate StoswSub & StosbSub instead of WritChar.Asm

;Syntax -
;   Locate V, H
;   CALL APrint(BYVAL VARPTR(A$(First)), NumEls%, MidFirst%, NumChars%, Colr%, Page%)
;
;   Where Page% is a video page number or -1 to use the current page,
;   and Colr% is the color to use or -1 to honor the current colors.

.Model Medium
.Data

   Els         DB    ?      ;holds number of elements to print
   First       DW    ?      ;holds number of first character to print
   Last        DW    ?      ;holds last character to be printed
   Dest        DW    ?      ;holds screen destination address
   Wide        DB    ?      ;holds width of screen (40 or 80)
   Total       DW    ?      ;holds total size of screen in bytes / 16
   Blank       DB   32      ;holds a blank space for padding the screen

   Extrn MonSeg:Word        ;this is in Monitor.Asm
   Extrn CGAPort:Word       ;this too

.Code
Extrn Monitor: Proc         ;we may need to call this from here
Extrn StosbSub: Proc
Extrn StoswSub: Proc
Include Mixed.Inc

HProc APrint, Array:Ptr, NumEls:Ptr, MidFirst:Ptr, NumChars:Ptr, Colr:Ptr, PageNum:Ptr

    Cmp  MonSeg,0           ;has Monitor been used yet?
    Jnz  MonOkay            ;yes, skip ahead
    Call Monitor            ;no, call it to set the segment and retrace words

MonOkay:
    Xor  AX,AX              ;look at screen buffer size in low memory
    Mov  ES,AX              ;through ES
    Mov  AX,ES:44Ch         ;this is a word stored at &H44C
    Mov  CL,4               ;divide by 16 since we'll be manipulating
    Shr  AX,CL              ;a segment
    Mov  Total,AX           ;save it internally

    Mov  AH,0Fh             ;get the video mode through BIOS
    Push BP
    Int  10h                ;returns current page in BH, columns in AH
    Add  AH,AH              ;double the width for the calculations below
    Mov  Wide,AH            ;and remember it for later

    Mov  SI,PageNum         ;get the address for Page%
    Mov  AX,[SI]            ;see what page they want to use
    Cmp  AX,-1              ;default page?
    Je   Default            ;yes, and BH is already correct
    Mov  BH,AL              ;no, put the page into BH

Default:
    Mov  AH,3               ;BIOS service to read the current cursor position
    Int  10h                ;enter with BH = page number,
    Pop  BP                 ;  returns with row/column in DH/DL
    Mov  BL,BH              ;put the page number into BL
    Xor  BH,BH              ;now clear BH
    Mov  SI,BX              ;save the returned page number in SI

    Mov  BX,MonSeg          ;get the current monitor segment from Monitor.Asm
    Or   SI,SI              ;are we writing to page zero?
    Jz   DonePage           ;yes, skip ahead

Inc_Page:
    Add  BX,Total           ;no, adjust segment to point to next page
    Dec  SI                 ;are we on the right page now?
    Jnz  Inc_Page           ;no, increment the page

DonePage:
    Mov  AL,DH              ;put the current row number into AL
    Mov  CL,Wide            ;multiply by Wide for base address of current row
    Mul  CL                 ;do the multiplication - answer ends up in AX
    Xor  DH,DH              ;clear DH for Add below, we only want DL
    Add  AX,DX              ;once for the character byte
    Add  AX,DX              ;and once for the attribute byte
    Mov  Dest,AX            ;Dest now holds starting memory position on screen

    Mov  DX,CGAPort         ;get the CGA retrace port from Monitor.Asm
    Mov  ES,BX              ;set ES to point to the appropriate screen segment

    Mov  SI,Colr            ;get address of Colr%
    Mov  AH,[SI]            ;put it into AH for direct screen writing below

    Mov  SI,NumEls          ;get address of NumEls%
    Mov  BL,[SI]            ;put value into BL
    Mov  Els,BL             ;and save it internally
    Mov  SI,MidFirst        ;get address of MidFirst%
    Mov  BX,[SI]            ;put value into BX
    Dec  BX                 ;adjust to base 0
    Mov  First,BX           ;and save it
    Mov  Last,BX            ;for now show First = Last
    Mov  SI,NumChars        ;get address of NumChars%
    Mov  BX,[SI]            ;number of characters to display into BX
    Add  Last,BX            ;now last holds final char count
    Mov  BP,Array           ;put address of Array$(First) descriptor into BP
    Cld                     ;all string moves below will be forward

More:
    Mov  DI,Dest            ;point DI to the destination address on the screen
    Mov  CX,DS:[BP]         ;put length of current Array$() into CX
    Mov  SI,DS:[BP+02]      ;put address of its first character into SI
    Mov  BX,First           ;put starting character number into BX
    Cmp  BX,CX              ;are we past the end of the string?
    Jae  Pad_Spc            ;yes, fill the rest of the screen with blanks
    Add  SI,BX              ;point SI to first character in string to print

Print:
    Cmp  AH,-1              ;are we leaving the current color alone?
    Lodsb                                                         ;CWM
    Je   Print2             ;yes, skip over
    Call StoswSub           ;no, call Write_Both to use Colr%     ;CWM
    Jmp  Short Next_Char    ;and go on to the next character in the string

Print2:
    Call StosbSub           ;write just the character
    Inc  DI                 ;skip over the attribute byte

Next_Char:
    Inc  BX                 ;show that we're about to print the next character
    Cmp  BX,CX              ;have we reached the end of the string?
    Jae  Pad_Spc            ;yes, fill the rest of the row with blanks
    Cmp  BX,Last            ;are we finished with this element?
    Jae  Next_Element       ;yes, go on to the next one
    Jmp  Short Print        ;no, continue printing

Pad_Spc:
    Cmp  BX,Last            ;are we finished filling the line with blanks?
    Jae  Next_Element       ;yes, go on to the next element

    Push SI                 ;save SI for a moment
    Lea  SI,Blank           ;point SI to the blank space in local storage

    Cmp  AH,-1              ;are we leaving the current color alone?
    Lodsb                                                       ;CWM
    Je   Pad_Spc2           ;yes, skip over
    Call StoswSub           ;no, call Write_Both to use Colr%
    Jmp  Short Next_Spc     ;and go on to the next blank space

Pad_Spc2:
    Call StosbSub           ;write just the character           ;CWM
    Inc  DI                 ;skip over the attribute byte

Next_Spc:
    Pop  SI                 ;get SI back again
    Inc  BX                 ;consider the next column
    Jmp  Short Pad_Spc      ;and do it again

Next_Element:
    Dec  Byte Ptr Els       ;show that we just completed another element
    Jz   Exit               ;no more, exit
    Add  BP,4               ;point to the next element's string descriptor
    Mov  CL,Wide            ;get the screen width into CL
    Xor  CH,CH              ;like CBW, but do it on CX
    Add  Dest,CX            ;point to the next screen row address
    Jmp  More               ;continue

Exit:
    HRet                    ;return to BASIC

HEndp
End

