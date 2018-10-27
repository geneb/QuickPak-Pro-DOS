; EDITOR - Copyright (c) 1989 by Chris May                      (7/1/1989)
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  Subroutine to edit an entry on the active screen page                ³
;³                                                                       ³
;³  Ed$ = Ed$ + SPACE$(Max% - LEN(Ed$))             'Max% = field length ³
;³                                                                       ³
;³  CALL Editor (Ed$, ALen%, ScanCode%, NumOnly%, CapsOn%, NormClr%, _   ³
;³               EditClr%, Row%, Col%,)                                  ³
;³                                                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

EditStr  EQU [BP+22]   ;string to be edited
ALen     EQU [BP+20]   ;actual length of returned string
ScanCode EQU [BP+18]   ;ON ENTRY:
                       ; = 1 then editing will resume at last cursor
                       ; = 2 then editing will resume at the new column
                       ;     given by Col%
                       ; = any other value editing will be assumed to be
                       ;     for the first time
                       ;ON EXIT:  
                       ; = positive ASCII control code (eg. Enter = 13)
                       ; = negative keyboard scan code (eg. <F1> = -59)
NumOnly  EQU [BP+16]   ;allow only numeric input if 1
CapsOn   EQU [BP+14]   ;force automatic conversion to CAPS if 1
NormClr  EQU [BP+12]   ;color on exit from program (eg. 7)
EditClr  EQU [BP+10]   ;inverse video color for editing (eg. 112)
Row      EQU [BP+08]   ;screen row to use
Col      EQU [BP+06]   ;screen column to use (or new column on re-entry)

.MODEL medium

.DATA

   Clr             DB    ?    ;color attribute for editing
   Caps            DB    ?    ; = 1 for Caps, 0 otherwise
   LCol            DB    ?    ;leftmost column in field
   RCol            DB    ?    ;rightmost column in field
   Ins             DB    ?    ; = 1 for insert mode on, 0 otherwise
   StartPt         DW    ?    ;screen address of field start
   LastPt          DW    ?    ;screen address of field end
   FieldLen        DW    ?    ;length of field
   LineSize        DB    ?    ;length of line in current mode
   PageNum         DB    ?    ;active page number
   Screen_Seg      DW    ?    ;save the screen segment for re-entry
   Position        DW    ?    ;save current cursor position for re-entry
   CursorSize      DW    ?    ;save cursor size here

   Extrn MonSeg:      Word    ;these are in Monitor.Asm
   Extrn CGAPort:     Word
   Extrn MonType:     Word

.CODE

   Extrn Monitor:     Proc    ;so we can access monitor type
   Extrn StosbSub:    Proc
   Extrn StoswSub:    Proc
   Extrn LodsbSub:    Proc
   Extrn LodswSub:    Proc
   Extrn RepStoswSub: Proc
   Extrn RepMovswSub: Proc

Public Editor
Editor Proc Far

   Push   BP
   Mov    BP,SP

   Mov    BX,Screen_Seg       ;initially set screen segment to address
   Mov    ES,BX               ; given in Screen_Seg, if any
   Mov    DX,Position         ;retrieve current cursor position

   Mov    SI,ScanCode         ;get ScanCode
   Mov    AL,[SI]             ;and load it into AL
   Cmp    AL,1                ;is it 1 ?
   Je     Do_Hilite           ;yes, then only do HiLite
   Cmp    AL,2                ;is it 2 ?
   Je     Change_Cursor       ;yes, then change cursor as well
   Jmp    First_Time          ;anything else must be first time

Change_Cursor:

   Mov    SI,Col              ;lets see what the new column is
   Mov    DL,[SI]             ;put it in DL
   Dec    DL                  ;change column 1 to column 0
   Cmp    DL,LCol             ;check if we are to the left of the field
   Jb     Reset_Left          ;yes then reset column to leftmost column
   Cmp    DL,RCol             ;check if we are to the right of the field
   Ja     Reset_Right         ;yes then reset column to rightmost column
   Jmp    Do_HiLite           ;all okay lets go

Reset_Left:

   Mov    DL,LCol             ;set at left column
   Jmp    Do_HiLite           ;now proceed

Reset_Right:

   Mov    DL,RCol             ;set at right column

Do_Hilite:

   Push   DX
   Mov    CX,FieldLen         ;get length of field
   Jcxz   First_Time          ;if zero then someone goofed
   Mov    DI,StartPt          ;get start of field
   Mov    SI,EditClr
   Mov    AL,[SI]             ;put color for editing in AL
   Mov    DX,CGAPort          ;get port to check for retrace

HiLite:

   Inc    DI                  ;skip character
   Call   StosbSub            ;put attribute byte on screen
   Loop   HiLite              ;do until complete

   Pop    DX
   Jmp    Cursor              ;all okay lets go

First_Time:

   Cmp    MonSeg,0            ;has Monitor been used yet?
   Jnz    MonOkay             ;yes, skip ahead
   Call   Monitor             ;no, call it to set segment and retrace words

MonOkay:

   Xor    AX,AX               ;look at screen buffer size in low memory
   Mov    ES,AX               ;through ES
   Mov    DI,ES:44Ch          ;this is a word stored at &H44C
   Mov    CL,4                ;divide by 16 since we'll be manipulating
   Shr    DI,CL               ;a segment

   Mov    AH,0Fh              ;get the video mode through BIOS
   Push   BP                  ;some old PC BIOS's trash BP during an Int 10h
   Int    10h                 ;returns active page in BH, columns in AH
   Pop    BP                  ;restore BP
   Mov    PageNum,BH          ;save the page

   Add    AH,AH
   Mov    LineSize,AH         ;save the line size

   Mov    AH,03h              ;get cursor info through BIOS
   Push   BP
   Int    10h                 ;returns cursor size in CX
   Pop    BP
   Mov    CursorSize,CX       ;save it as CursorSize
   Sub    CL,CH               ;height of cursor in CL
   Mov    Ins,0               ;ensure insert mode is off
   Cmp    CL,4                ;is it < 4
   Jl     No_Insert           ;yes, then insert not set
   Inc    Ins                 ;no, then set insert mode

No_Insert:

   Mov    SI,Row              ;get the row number
   Mov    DH,[SI]             ;and put it in DH
   Dec    DH                  ;change row 1 to row 0

   Mov    SI,Col              ;get the column number
   Mov    DL,[SI]             ;and put it in DL
   Dec    DL                  ;change column 1 to column 0

   Mov    LCol,DL             ;save left column for later use
   Mov    RCol,DL             ;setup for right column
   Call   Calc_Off            ;calculate column offset
   Mov    StartPt,AX          ;StartPt now holds screen address of field start

   Xor    CX,CX               ;zero out CX to be an offset to current page
   Or     BH,BH               ;are we in fact writing to page zero?
   Jz     DonePage            ;yes, skip ahead

Inc_Page:

   Add    CX,DI               ;no, adjust segment to point to next page
   Dec    BH                  ;are we on the right page now?
   Jnz    Short Inc_Page      ;no, increment the page

DonePage:

   Add    CX,MonSeg           ;add on the monitor segment
   Mov    Screen_Seg,CX       ;save for re-entry
   Mov    ES,CX               ;set ES to point to the screen segment

   Mov    SI,CapsOn           ;get address of CapsOn%
   Mov    BL,[SI]             ;put value into BL
   Mov    Caps,BL             ;save for later use

   Mov    SI,EditClr          ;get address of EditClr%
   Mov    AH,[SI]             ;put it into AH for direct screen writing below
   Mov    Clr,AH              ;save for later use

   Mov    SI,EditStr          ;get address of Ed$
   Mov    CX,[SI]             ;put length of Ed$ into CX
   Jcxz   FastExit            ;get out now if zero length string
   Mov    FieldLen,CX         ;save length for later use
   Add    RCol,CL
   Dec    RCol                ;right column now set
   Mov    SI,[SI+02]          ;put first character of Ed$ in SI
   Mov    DI,StartPt          ;point DI to the destination address on screen
   Cld                        ;string moves will be in the forward direction
   Push   DX
   Mov    DX,CGAPort

Display_Ed:

   Lodsb                      ;get the current character from Ed$ and Inc SI
   Call   Capital             ;change to Caps?
   Call   StoswSub            ;put on screen
   Loop   Display_Ed          ;done CX times
   Pop    DX
   Dec    DI
   Dec    DI
   Mov    LastPt,DI           ;save screen address of last point

Cursor:

   Cmp    Ins,1               ;is insert mode on?
   Je     Large_Cursor        ;yes, then do large cursor

   Mov    CH,12               ;top of cursor (assumes monochrome)
   Mov    CL,13               ;bottom of cursor (assumes monochrome)
   Cmp    MonType,2           ;is monochrome adapter used?
   Jbe    Set_Cursor          ;yes, then set cursor
   Mov    CH,6                ;top of cursor (for CGA)
   Mov    CL,7                ;bottom of cursor (for CGA)
   Jmp    Set_Cursor

FastExit:

   Jmp    Null_String_Exit    ;"lily pad" jump to exit

Large_Cursor:

   Mov    CH,6                ;top of cursor (assumes monochrome)
   Mov    CL,13               ;bottom of cursor (assumes monochrome)
   Cmp    MonType,2           ;is monochrome adapter used?
   Jbe    Set_Cursor          ;yes, then set cursor
   Mov    CH,3                ;top of cursor (for CGA)
   Mov    CL,7                ;bottom of cursor (for CGA)

Set_Cursor:

   Mov    AH,1                ;set cursor
   Push   BP
   Int    10h                 ;call BIOS
   Pop    BP

Position_Cursor:

   Mov    BH,PageNum          ;get active page number
   Mov    AH,2                ;cursor position
   Push   BP
   Int    10h                 ;call BIOS
   Pop    BP

Get_Key:

   Mov    AH,0                ;get the key that is waiting
   Int    16h                 ;pressed key given in AL

   Cmp    AL,8                ;has <BACKSPACE> key been pressed?
   Jne    Control_Key         ;no, check for Control_Key

   Cmp    DL,LCol             ;is Cursor already at left?
   Je     Do_Control          ;yes, then exit with backspace key

   Dec    DL
   Jmp    LShift

Control_Key:

   Cmp    AL,0                ;check if extended code
   Jz     Left_Arrow          ;yes, then check for LEFT ARROW and others

   Cmp    AL,31               ;is it a control key ?
   Ja     Normal_Key          ;no, then it is a Normal_Key

Do_Control:

   Xor    AH,AH               ;clear contents of AH
   Jmp    Exit                ;then quit with the positive control code

Go_Back:

   Jmp    Get_Key             ;get again

Normal_Key:

   Mov    SI,NumOnly          ;get address of NumOnly%
   Mov    BL,[SI]             ;put value into BL
   Cmp    BL,1                ;are numbers only required?
   Jne    Display_Entry       ;no, then continue
   Cmp    AL,'-'              ;is it a "-"?
   Je     Display_Entry       ;yes, acceptable so display it
   Cmp    AL,'+'              ;is it a "+"?
   Je     Display_Entry       ;yes, acceptable so display it
   Cmp    AL,'.'              ;is it a "."?
   Je     Display_Entry       ;yes, acceptable so display it
   Cmp    AL,'E'              ;is it an "E"?
   Je     Display_Entry       ;yes, acceptable so display it
   Cmp    AL,'e'              ;is it an "e"?
   Je     Display_Entry       ;yes, acceptable so display it
   Cmp    AL,'0'              ;is it less than "0"
   Jb     Go_Back             ;yes, so not a number - go back
   Cmp    AL,'9'              ;is it greater than "9"
   Ja     Go_Back             ;yes, so not a number - go back

Display_Entry:

   Cmp    Ins,1               ;is insert mode on?
   Jne    Disp_it             ;no, then display it

   ;--- Shift all characters, at and to the right of the cursor, one place
   ;    to the right. Any character in the rightmost column is removed.

   Push   AX                  ;save contents of AX on stack
   Mov    DI,LastPt           ;screen "to" address
   Mov    AX,DI
   Dec    AX                  ;move one column to the left
   Dec    AX
   Mov    SI,AX               ;screen "from" address
   Xor    CH,CH
   Mov    CL,RCol             ;set length of string to read from screen
   Sub    CL,DL               ;subtract current cursor position
                              ; = no. of characters to shift
   Push   DX
   Mov    DX,CGAPort
   Push   DS                  ;save data segment on stack
   Push   ES                  ;save extra segment on stack
   Pop    DS                  ;put the "from" segment into DS
   Std                        ;backward string moves
   Call   RepMovswSub
   Pop    DS                  ;get DS back from stack
   Pop    DX
   Pop    AX                  ;restore contents of AX
   Cld                        ;make all string moves forward again

Disp_it:

   Call   Capital             ;change to Caps?
   Push   AX                  ;save contents of AX register
   Call   Calc_Off            ;get screen destination address
   Mov    DI,AX               ;and put it in DI
   Pop    AX                  ;restore contents of AX register
   Push   DX
   Mov    DX,CGAPort
   Call   StosbSub            ;put character on screen
   Pop    DX
   Cmp    DL,RCol             ;are we at the rightmost column?
   Je     Do_Control          ;yes, then exit with control code
   Inc    DL                  ;no, move to right
   Jmp    Position_Cursor

Left_Arrow:

   Cmp    AH,75               ;has left arrow been pressed?
   Jne    Right_Arrow         ;no, check for RIGHT ARROW

   Cmp    DL,LCol             ;is Cursor already at left?
   Jne    Move_Left           ;no, then move left
   Jmp    Do_ScanCode         ;yes, then exit with scan code

Move_Left:

   Dec    DL                  ;no, then move one column left
   Jmp    Position_Cursor     ;get another

Right_Arrow:

   Cmp    AH,77               ;has right arrow been pressed?
   Jne    Delete              ;no, check for delete key

   Cmp    DL,RCol             ;is cursor already at right?
   Jne    Move_Right          ;no, then move right
   Jmp    Do_ScanCode         ;yes, then exit with scan code

Move_Right:

   Inc    DL                  ;no, then move one column right
   Jmp    Position_Cursor     ;get another

Delete:

   Cmp    AH,83               ;has <DEL> been pressed?
   Jne    Home                ;no, then check for <HOME>

LShift:                ;Shifts all characters to the right of the cursor, one
                       ;place to the left, then add a space to the right.
   Call   Calc_Off
   Mov    DI,AX               ;current screen "to" address
   Mov    SI,AX
   Inc    SI
   Inc    SI                  ;screen "from" address
   Xor    CH,CH
   Mov    CL,RCol             ;set length of string to read from screen
   Sub    CL,DL               ;subtract current Cursor position
                              ; = no. of characters to shift
   Push   DX
   Mov    DX,CGAPort
   Jz     Do_Space            ;at end of field so put space only
   Push   DS                  ;save data segment on stack
   Push   ES                  ;save extra segment on stack
   Pop    DS                  ;put the "from" segment into DS
   Call   RepMovswSub
   Pop    DS                  ;get DS back from stack

Do_Space:

   Mov    AL,' '              ;blank out rightmost character
   Call   StosbSub            ;by putting space character on screen
   Pop    DX
   Jmp    Position_Cursor

Home:

   Cmp    AH,71               ;has <HOME> been pressed?
   Jne    End_Key             ;no, then check for <END>

   Mov    DL,LCol             ;move cursor to left column
   Jmp    Position_Cursor

End_Key:

   Cmp    AH,79               ;has <END> been pressed?
   Jne    Alt_C               ;no, then check for <ALT><C>

   Call   Find_End            ;find end of current string
   Jmp    Position_Cursor

Alt_C:

   Cmp    AH,46               ;has <ALT><C> been pressed?
   Jne    Alt_R               ;no, then check for <ALT><R>

   Mov    AL,' '              ;space to display
   Mov    AH,Clr              ;color attribute
   Mov    DI,StartPt          ;destination address of first column
   Mov    CX,FieldLen         ;length of string to display
   Push   DX
   Mov    DX,CGAPort
   Call   RepStoswSub         ;put the spaces on screen
   Pop    DX 
   Mov    DL,LCol             ;move cursor to left column
   Jmp    Position_Cursor

Alt_R:

   Cmp    AH,19               ;has <ALT><R> been pressed?
   Jne    Insert              ;no, then check for <INS>

   Mov    SI,EditStr          ;get address of Ed$
   Mov    SI,[SI+02]          ;point to first character
   Mov    DI,StartPt          ;destination address of first column
   Mov    CX,FieldLen         ;length of string to display
   Mov    AH,Clr              ;color attribute
   Push   DX
   Mov    DX,CGAPort

Ed_Again:

   Lodsb                      ;get the current character from Ed$ and Inc SI
   Call   Capital             ;change to Caps?
   Call   StoswSub            ;put on screen
   Loop   Ed_Again            ;done CX times
   Pop    DX
   Jmp    Get_Key

Insert:

   Cmp    AH,82               ;has <INS> been pressed?
   Jne    Do_ScanCode         ;no, then exit with scan code

   Xor    Ins,1               ;toggle insert mode on and off
   Jmp    Cursor

Do_ScanCode:

   Mov    AL,AH               ; move scan code to AL
   Xor    AH,AH               ; and clear AH
   Neg    AX                  ; change sign of AX

Exit:

   Mov    Position,DX         ;save cursor position for re-entry
   Mov    SI,ScanCode
   Mov    [SI],AX             ;save the scan code

   Call   Find_End
   Mov    SI,ALen             ;get address of ALen%
   Xor    BH,BH               ;clear out upper byte
   Mov    [SI],BX             ;save length of string in ALen%

   Mov    SI,EditStr          ;get address of Ed$
   Mov    DI,[SI+02]          ;put address of first character in DI
   Mov    SI,StartPt          ;set at start of string on screen

   Mov    CX,FieldLen         ;set length of string to read from screen
   Mov    DX,CGAPort
   Push   DS                  ;swap ES and DS using stack
   Push   ES
   Pop    DS
   Pop    ES

Read_Again:

   Call   LodswSub            ;get the character and attribute
   Stosb                      ;place just the character into Ed$
   Loop   Read_Again

   Push   DS                  ;swap ES and DS using stack
   Push   ES
   Pop    DS
   Pop    ES
   Mov    SI,NormClr          ;get address of NormClr%
   Mov    AL,[SI]             ;put it into AL for direct screen writing below
   Mov    CX,FieldLen         ;length of field
   Mov    DI,StartPt

Color_Change:

   Inc    DI                  ;address of first character attribute
   Call   StosbSub            ;change attribute
   Loop   Color_Change

Null_String_Exit:

   Mov    CX,CursorSize       ;restore cursor size
   Mov    AH,1                ;set cursor
   Int    10h                 ;call BIOS
   Pop    BP
   Ret    18                  ;return to Basic

;----------------------------------------------------------------------------
Calc_Off Proc Near            ;Calculates the screen offset from row/column
                              ;given in DH/DL

   Push   DX                  ;save DX register on stack
   Mov    AL,DH               ;put the current row number into AL
   Mov    CL,LineSize         ;multiply by length of line to get base
                              ;address of current row
   Mul    CL                  ;do the multiplication - answer ends up in AX
   Xor    DH,DH               ;clear DH for ADD below, we only want DL
   Add    AX,DX               ;once for the character byte
   Add    AX,DX               ;and once for the attribute byte
   Pop    DX                  ;restore DX register from stack
   Ret

Calc_Off EndP
;----------------------------------------------------------------------------
Capital Proc Near

   Cmp    Caps,1              ;are Caps required?
   Jne    No_Caps             ;no, continue with no change
   Cmp    AL,'a'              ;is it below "a" ?
   Jb     No_Caps             ;yes, continue with no change
   Cmp    AL,'z'              ;is it above "z" ?
   Ja     No_Caps             ;yes, continue with no change
   And    AL,95               ;mask out lower case bit

No_Caps:  Ret

Capital EndP
;----------------------------------------------------------------------------
Find_End Proc Near            ;Sets DL equal to the cursor position at end of
                              ;string and sets BL equal to the actual length
                              ;of the string, ALen%

   Mov    DL,RCol             ;move cursor to right column
   Mov    BL,DL
   Sub    BL,LCol

One_Less:

   Call   Calc_Off            ;calculate offset of current position
   Mov    SI,AX               ;screen source
   Push   DX
   Mov    DX,CGAPort
   Push   DS
   Push   ES                  ;save DS and ES on stack
   Pop    DS                  ;temporarily put ES in DS
   Call   LodsbSub            ;load character from screen
   Pop    DS                  ;get back DS
   Pop    DX
   Cmp    AL,' '              ;is character a space?
   Jne    No_More_Spaces      ;no, then no more spaces
   Cmp    DL,LCol             ;yes, are we also at start of string?
   Je     Got_End             ;yes, then finish
   Dec    DL                  ;yes, move Cursor one place to left
   Dec    BL                  ;decrease length of string also
   Jmp    One_Less

No_More_Spaces:

   Inc    BL
   Cmp    DL,RCol             ;is it last character?
   Je     Got_End             ;yes, then do not shift cursor to the right
   Inc    DL                  ;found last character

Got_End:  Ret

Find_End EndP
;----------------------------------------------------------------------------
Editor EndP
End
