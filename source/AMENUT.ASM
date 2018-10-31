; AMENUT - Copyright (c) 1989 by Chris May                      (4/1/1989)
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  Subroutine to list array elements and select one                     ³
;³  For fixed length string arrays                                       ³
;³                                                                       ³
;³ CALL AMenuT (BYVAL VARSEG(A$(1)), BYVAL VARPTR(A$(1)), Start%, _      ³
;³              StrLen%, Count%, ScanCode%, ElemClr%, HiLite%, NumRow%,_ ³
;³              NumCol%, Gap%, Row%, Col%)                               ³
;³                                                                       ³
;³ NOTE: USER MUST ENSURE THAT MENU FITS ON THE SCREEN                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

ArraySeg   EQU  [BP+30]    ;segment in which A$(1) is contained
ArrayAdr   EQU  [BP+28]    ;array A$(1) containing elements to be displayed
Start      EQU  [BP+26]    ;element number at top left of table
StrLen     EQU  [BP+24]    ;length of fixed string element
Count      EQU  [BP+22]    ;ON ENTRY:
                           ; = number of elements in array to be displayed
                           ;ON EXIT:
                           ; = selected element number
ScanCode   EQU  [BP+20]    ;ON ENTRY:
                           ; = 3 then no initialization will be done
                           ;ON EXIT:
                           ; = positive ASCII control code (eg. Enter = 13)
                           ; = negative keyboard scan code (eg. <F1> = -59)
ElemClr    EQU  [BP+18]    ;color to display array elements
HiLite     EQU  [BP+16]    ;color for inverse highlight
NumRow     EQU  [BP+14]    ;number of rows to display ( ó 25 )
NumCol     EQU  [BP+12]    ;number of columns to display
Gap        EQU  [BP+10]    ;number of spaces to leave between displayed columns
Row        EQU  [BP+08]    ;top row of displayed menu
Col        EQU  [BP+06]    ;left column of displayed menu

.MODEL medium

.DATA

   Extrn MonSeg:      Word    ;this is in Monitor.Asm
   Extrn CGAPort:     Word

.CODE

   Extrn Monitor:     Proc    ;so we can access monitor type
   Extrn PutString:   Proc
   Extrn RepStoswSub: Proc

Public AMenuT
AMenuT Proc Far

   Push   BP
   Mov    BP,SP

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
   Mov    AL,AH               ;put the columns in AL
   Add    AL,AL               ;double the columns
   Xor    AH,AH               ;make it a word

   Xor    CX,CX               ;zero out CX to be an offset to current page
   Or     BH,BH               ;are we in fact writing to page zero?
   Jz     DonePage            ;yes, skip ahead

Inc_Page:

   Add    CX,DI               ;no, adjust segment to point to next page
   Dec    BH                  ;are we on the right page now?
   Jnz    Short Inc_Page      ;no, increment the page

DonePage:

   Add    CX,MonSeg
   Mov    ES,CX               ;set ES to point to the screen segment
   Cld                        ;all string moves in forward direction

   Mov    SI,ScanCode         ;get ScanCode
   Mov    BX,[SI]
   Cmp    BX,3                ;is it 3 ?
   Jne    Do_Init             ;no, then continue to initialize

   Mov    DX,CGAPort          ;set port to check for retrace
   Push   DS                  ;save current DS on stack
   Jmp    Display             ;no initialization required

Do_Init:

   Mov    CS:Param4,AX        ;and save line size in Param4
   Mov    SI,Row              ;get the top row number
   Mov    AL,[SI]             ;and put it in AL
   Dec    AL                  ;change row 1 to row 0
   Mov    CX,CS:Param4        ;multiply by Param4 to get base address of row
   Mul    CL                  ;do the multiplication - answer ends up in AX
   Mov    SI,Col              ;get the left column number
   Mov    BX,[SI]             ;and save it in BX
   Dec    BX                  ;change column 1 to column 0
   Add    AX,BX               ;add once for the character byte
   Add    AX,BX               ;and once for the attribute byte
   Mov    CS:StartPt,AX       ;StartPt now holds screen address of field start
   Mov    CS:Param2,AX
   Mov    CS:Param5,AX
   Mov    SI,NumRow           ;get NumRow%
   Mov    AX,[SI]             ;NumRow% in AX
   Mov    CS:NRow,AX          ;save it as NRow for later
   Mov    CX,CS:Param4        ;retrieve LineSize
   Mul    CL                  ;AX contains  NRow * LineSize
   Add    CS:Param2,AX        ;Param2 is now set
   Mov    CS:Param3,AX        ;first part of Param3 is set
   Mov    SI,StrLen           ;get length of element
   Mov    CX,[SI]
   Mov    CS:ElemLen,CX       ;save it as ElemLen for later
   Mov    BX,CX
   Add    BX,CX               ;2 * ElemLen  in BX
   Sub    CS:Param4,BX        ;Param4 is now set
   Mov    AX,CS:NRow          ;retrieve NRow in AX
   Mul    CL                  ;AX now contains  ElemLen * NRow
   Mov    CS:Param1,AX        ;Param1 is now set
   Mov    AX,CS:NRow          ;retrieve NRow in AX again
   Mov    SI,NumCol           ;get NumCol%
   Mov    CX,[SI]
   Mul    CL                  ;AX now contains  Nrow * NCol
   Mov    CS:Param6,AX        ;Param6 is now set

   Mov    SI,Gap              ;get Gap%
   Mov    AX,[SI]
   Add    BX,AX
   Add    BX,AX               ;BX now contains  2 * (ElemLen + Gap)
   Sub    CS:Param3,BX        ;Param3 is now set

   Dec    CL                  ;CX now contains  NCol - 1
   Mov    AX,BX               ;AX now contains  2 * (ElemLen + Gap)
   Mul    CL                  ;(NCol - 1) * 2 * (ElemLen + Gap) now in AX
   Add    CS:Param5,AX        ;Param5 is now set

   Mov    SI,ElemClr          ;get ElemClr%
   Mov    AH,[SI]             ;and put it in AH
   Mov    CS:Color1,AH        ;save it for later

   Mov    SI,HiLite           ;get HiLite%
   Mov    AH,[SI]             ;color attribute to use
   Mov    CS:Color2,AH        ;save it for later

   Mov    SI,Count            ;get Count%
   Mov    AX,[SI]             ;put value into AX
   Mov    CS:Last,AX          ;save Count% as Last

   Mov    SI,Start            ;get Start% - the first element at top of table
   Mov    AX,[SI]             ;put value into AX
   Mov    CS:ElemNo,AX        ;save this as the current element number
   Mov    CS:First,AX         ; and first item in table
   Dec    AX                  ;work from base of 0
   Xor    DX,DX               ;zero out DX for division below
   Mov    BX,CS:Param6        ;put  (NRow * NCol) into BX, the divisor
   Div    BX                  ;quotient = ElemNo \ (NRow * NCol)  in AX
   Mov    CX,AX               ;save number of screen fulls in CX for looping
   Sub    CS:First,DX         ;DX should be zero if user input is correct
                              ;if not then this will correct it
   Mov    AX,CS:ElemLen       ;length of string is in AX
   Mul    BX                  ;StrLen * (NRow * NCol)  in AX
                              ;this is the number of bytes in table on screen

   Mov    DX,CGAPort          ;set port to check for retrace

   Push   DS                  ;save current DS on stack
   Mov    DS,ArraySeg
   Mov    BP,ArrayAdr         ;put address of A$(1) into DS:BP
   Mov    CS:ASeg,DS          ;save segment for later
   Mov    CS:AAdr,BP          ;save offset for later

Check_Seg:

   Or     CX,CX               ;is the number of screen fulls = 0 ?
   Jz     Display             ;yes, then no need to modify segment

   Add    CS:AAdr,AX          ;add on screen full to AAdr

AheadSeg:

   Mov    BP,CS:AAdr
   Or     BP,BP               ;are we in the second half of the segment?
   Jns    Ahead               ;no, then okay to continue

   Sub    CS:AAdr,4000h       ;yes, then move ahead by a quarter segment
   Add    CS:ASeg,400h        ;correspondingly shift the segment

Ahead:

   Loop   Check_Seg           ;continue until CX is zero

Display:

   Mov    DI,CS:StartPt       ;screen offset of first element
   Mov    DS,CS:ASeg          ;segment at start of table
   Mov    BP,CS:AAdr          ;get address of first element in table
   Mov    BX,CS:First         ;set counter at first

Next_Element:

   Mov    AH,CS:Color1        ;use regular color as default
   Cmp    BX,CS:ElemNo        ;is this the cursor?
   Jne    Regular_Element     ;no, then continue
   Mov    AH,CS:Color2        ;yes, use color for cursor

Regular_Element:

   Mov    SI,BP               ;get first character
   Mov    CX,CS:ElemLen       ;length of string
   Call   PutString

   Cmp    BX,CS:Last          ;is this the last element ?
   Je     Do_Blanks           ;yes, then fill remaining field with blanks
   Inc    BX                  ;move counter to next element
   Add    BP,CS:ElemLen       ;set BP to point to next element address
   Add    DI,CS:Param4        ;next row
   Cmp    DI,CS:Param2        ;is this the bottom row?
   Jb     Next_Element        ;no, then continue down the column
   Sub    DI,CS:Param3        ;yes, move to next column
   Cmp    DI,CS:Param5        ;have we done the rightmost column?
   Ja     Get_Key             ;yes, then get key
   Jmp    Next_Element        ;no, then get more

Do_Blanks:

   Mov    AH,CS:Color1        ;set the element color
   Mov    AL," "              ;put space character in AL

Blank_Return:

   Add    DI,CS:Param4        ;next row
   Cmp    DI,CS:Param2        ;is this the bottom row?
   Jb     Next_Blank          ;no, then continue down the column
   Sub    DI,CS:Param3        ;yes, move to next column
   Cmp    DI,CS:Param5        ;have we done the rightmost column?
   Ja     Get_Key             ;yes, then get key

Next_Blank:

   Mov    CX,CS:ElemLen       ;set element length
   Call   RepStoswSub
   Jmp    Blank_Return

Get_Key:

   Mov    AH,0                ;call BIOS service to get key
   Int    16h                 ;pressed key given in AL
   Cmp    AL,0                ;check if extended code
   Jz     Down_Arrow          ;yes, then check for down arrow and others

   Xor    AH,AH               ;clear contents of AH

Exit:

   Pop    DS
   Mov    BP,SP               ;ensure at start of stack
   Mov    SI,ScanCode         ;put address of ScanCode% in SI
   Mov    [SI],AX             ;set ScanCode%
   Mov    SI,Count            ;get address of Count%
   Mov    BX,CS:ElemNo        ;put current element number in BX
   Mov    [SI],BX             ;put in Count%
   Pop    BP
   Ret    26                  ;return to Basic

Down_Arrow:

   Cmp    AH,80               ;has down arrow been pressed?
   Jne    Up_Arrow            ;no, check for up arrow

   Mov    BX,CS:ElemNo
   Cmp    CS:Last,BX          ;is this all the elements?
   Je     Get_Key             ;yes, then get again

   Inc    CS:ElemNo           ;move to next element

Check_Right:

   Mov    BX,CS:ElemNo
   Sub    BX,CS:First         ;ElemNo - First  in BX
   Cmp    BX,CS:Param6        ;are we still on the table?
   Jae    Move_Table_Right    ;no, so move it
   Jmp    Display             ;yes, go display table

Move_Table_Right:

   Mov    BX,CS:NRow
   Add    CS:First,BX         ;advance First by NRow elements
   Mov    BX,CS:Param1
   Add    CS:AAdr,BX          ;move table by one column
   Mov    CX,1                ;set CX = 1  for loop
   Jmp    AheadSeg            ;check that segment is still okay

Up_Arrow:

   Cmp    AH,72               ;has up arrow been pressed?
   Jne    Left_Arrow          ;no, check for left arrow

   Cmp    CS:ElemNo,1         ;are we at first element already?
   Je     Get_Key             ;yes, then get again

   Dec    CS:ElemNo           ;move back one element

Check_Left:

   Mov    BX,CS:ElemNo
   Sub    BX,CS:First         ;ElemNo - First  in BX
   Js     Move_Table_Left     ;not on table if sign flag set, so move it
   Jmp    Display             ;go display table if okay

Move_Table_Left:

   Mov    BX,CS:NRow
   Sub    CS:First,BX         ;reduce First by NRow elements
   Mov    BX,CS:Param1
   Sub    CS:AAdr,BX          ;move table by one column to the left
   Mov    BP,CS:AAdr          ;put AAdr in BP for segment checking
   Or     BP,BP               ;are we in the second half of the segment
   Js     Back                ;yes, then okay to continue

   Add    CS:AAdr,4000h       ;no, then move back by a quarter segment
   Sub    CS:ASeg,400h        ;correspondingly shift the segment

Back:

   Jmp    Display

Left_Arrow:

   Cmp    AH,75               ;has left arrow been pressed?
   Jne    Right_Arrow         ;no, check for right arrow

   Mov    BX,CS:NRow
   Cmp    CS:ElemNo,BX        ;is ElemNo > NRow ?
   Ja     Left_Okay           ;yes, then left arrow is allowed

   Mov    CS:First,1          ;initial element number
   Mov    CS:ElemNo,1
   Jmp    Display             ;start again

Left_Okay:

   Sub    CS:ElemNo,BX        ;move back NRow elements
   Jmp    Check_Left          ;go check whether table needs shifting left

Right_Arrow:

   Cmp    AH,77               ;has right arrow been pressed?
   Je     Do_Right_Arrow      ;yes, then do it
   Mov    AL,AH               ;no, move scan code to AL
   Xor    AH,AH               ; and clear AH
   Neg    AX                  ; change sign of AX
   Jmp    Exit                ; and return with scan code

Do_Right_Arrow:

   Mov    BX,CS:NRow
   Add    CS:ElemNo,BX        ;move cursor ahead by NRow
   Mov    AX,CS:ElemNo
   Sub    AX,CS:Last          ;ElemNo - Last  in AX
   Jns    Set_Last            ;if sign flag is not set then need to adjust
   Jmp    Check_Right         ;check if still on the table

Set_Last:

   Mov    BX,CS:Last
   Mov    CS:ElemNo,BX        ;make ElemNo = Last
   Jmp    Check_Right

   ASeg            DW    ?    ;contains segment address of A$(1)
   AAdr            DW    ?    ;address of first element in table
   First           DW    ?    ;element number at top of table = Start%
   Last            DW    ?    ;last element number possible = Count%
   ElemNo          DW    ?    ;current element number
   StartPt         DW    ?    ;screen offset at top left of menu
   ElemLen         DW    ?    ;length of element
   Param1          DW    ?    ;NRow * ElemLen
   Param2          DW    ?    ;StartPt + NRow * LineSize
   Param3          DW    ?    ;LineSize * NRow - 2 * (ElemLen + Gap)
   Param4          DW    ?    ;LineSize - 2 * ElemLen
   Param5          DW    ?    ;StartPt + (NCol - 1) * 2 * (ElemLen + Gap)
   Param6          DW    ?    ;NRow * NCol
   NRow            DW    ?    ;save number of rows here
   Color1          DB    ?    ;save color for regular printing here
   Color2          DB    ?    ;save color for cursor here

AMenuT EndP
End

