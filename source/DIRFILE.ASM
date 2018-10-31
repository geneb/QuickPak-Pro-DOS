; DIRFILE - Copyright (c) 1989 by Chris May                        (3/1/1989)
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Subroutine to obtain filename. DirFile may be called using the following ³
;³ QuickBASIC routine in conjunction with other assembly language routines: ³
;³                                                                          ³
;³ File.Spec$ = Drive$ + ":*.*"                                             ³
;³ CALL FCount(File.Spec$, Count%)                                          ³
;³ IF Count% = 0 THEN PRINT "No Files": END                                 ³
;³ REDIM File$(Count% + 1)                                                  ³
;³ FOR I% = 1 TO Count% + 1                                                 ³
;³    File$(I%) = SPACE$(12)                   'reserve space for each file ³
;³   NEXT I%                                                                ³
;³ File$(0) = File.Spec$                                                    ³
;³ CALL ReadFile(BYVAL VARPTR(File$(0)))           'get files matching spec ³
;³ CALL SortStr2(BYVAL VARPTR(File$(1)), Count% - 1) 'sort files (optional) ³
;³                  _____________________________                           ³
;³                                                                          ³
;³ CALL DirFile(BYVAL VARPTR(File$(1)), Count%, ScanCode%, MessClr%,_       ³
;³                                      FileClr%, HiLite%, BoxClr% )        ³
;³                                                                          ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

ArrayAdr EQU [BP+18]   ;File$(1) array containing filenames
Count    EQU [BP+16]   ;ON ENTRY:
                       ; = number of filenames in array
                       ;ON EXIT:
                       ; = selected file number
ScanCode EQU [BP+14]   ;ON EXIT:
                       ; = positive ASCII control code (eg. Enter = 13)
                       ; = negative keyboard scan code (eg. <F1> = -59)
MessClr  EQU [BP+12]   ;color for high intensity (eg. 15)
FileClr  EQU [BP+10]   ;color for low intensity (eg. 7)
HiLite   EQU [BP+08]   ;color for inverse highlight (eg. 112)
BoxClr   EQU [BP+06]   ;color attribute for box (eg. 15)

.MODEL medium

.DATA

  Screen_Display  DB ' file(s) found'
                  DB 'Filename : '
                  DB 'Use cursor keys to select file then press <ENTER>'
  DB 'ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿'
  DB 'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ'
  AAdr            DW    ?     ;address of first file in table
  First           DW    ?     ;file number at top left of table
  Last            DW    ?     ;last file number possible = Count%
  FileNo          DW    ?     ;current file number
  Color1          DB    ?     ;save file color here
  Color2          DB    ?     ;save HiLite color here
  Color3          DB    ?     ;save message color here

  Extrn MonSeg:   Word        ;these are in Monitor.Asm
  Extrn CGAPort:  Word

.CODE

  Extrn Monitor:     Proc     ;so we can access monitor type
  Extrn PutString:   Proc
  Extrn StoswSub :   Proc
  Extrn RepStoswSub: Proc

Public DirFile
DirFile Proc Far

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
   Int    10h                 ;returns active page in BH
   Pop    BP                  ;restore BP

   Xor    CX,CX               ;zero out CX to be an offset to current page
   Or     BH,BH               ;are we in fact writing to page zero?
   Jz     DonePage            ;yes, skip ahead

Inc_Page:

   Add    CX,DI               ;no, adjust segment to point to next page
   Dec    BH                  ;are we on the right page now?
   Jnz    Short Inc_Page      ;no, increment the page

DonePage:

   Add    CX,MonSeg           ;add on the monitor segment
   Mov    ES,CX               ;set ES to point to the screen segment
   Cld                        ;all string moves in forward direction

   Mov    SI,MessClr
   Mov    AH,[SI]             ;color attribute for message in AH
   Mov    Color3,AH           ;save it for later in Color3

   Mov    SI,Count            ;get address of Count
   Mov    BX,[SI]             ;put value into BX
   Mov    Last,BX             ;save as Last for later use

   Mov    DI,972              ;position of Count on screen
   Cmp    BX,1000             ;is Count below 1000?
   Jae    Div1                ;no, then start here
   Cmp    BX,100              ;is Count below 100?
   Jae    Div2                ;no, then start here
   Cmp    BX,10               ;is Count below 10?
   Jae    Div3                ;no, then start here
   Jmp    Div4

Div1:

   Mov    CX,1000             ;divide by 1000
   Call   Dec_Div

Div2:

   Mov    CX,100              ;divide by 100
   Call   Dec_Div

Div3:

   Mov    CX,10               ;divide by 10
   Call   Dec_Div

Div4:

   Mov    CX,1                ;divide by 1
   Call   Dec_Div

   Lea    SI,Screen_Display   ;address of Screen_Display loaded in SI
   Mov    CX,14               ;length of Screen_Display
   Mov    DX,CGAPort
   Call   PutString           ;put string on the screen

   Mov    CX,11               ;string length
   Mov    DI,2892             ;screen offset
   Call   PutString           ;put string on the screen

   Mov    CX,49               ;string length
   Mov    DI,3688             ;screen offset
   Call   PutString           ;put string on the screen

   Mov    BX,BoxClr
   Mov    AH,[BX]             ;color attribute to use for box

   Mov    CX,72               ;length of box
   Mov    DI,1290             ;screen offset
   Call   PutString           ;put string on the screen

   Mov    CX,72               ;length of box
   Mov    DI,2570
   Call   PutString           ;put string on the screen

Do_Sides:

   Mov    AL,179              ;vertical line character for sides
   Mov    DI,1450             ;start of sides
   Mov    CX,7                ;number of rows

Sides:

   Call   StoswSub            ;put the character and attribute on screen
   Add    DI,140
   Call   StoswSub            ;put the character and attribute on screen
   Add    DI,16
   Loop   Sides               ;do CX times

   Mov    SI,ArrayAdr         ;get address of A$()
   Mov    AAdr,SI             ;set first file in table

   Mov    SI,HiLite
   Mov    AH,[SI]             ;color attribute for cursor in AH
   Mov    Color2,AH

   Mov    SI,FileClr
   Mov    BH,[SI]             ;color attribute for window in BH
   Mov    Color1,BH           ;save it here also
   Mov    AX,0600h            ;service 6 with no scrolling
   Mov    CX,0906h            ;top left row 9 /column 6
   Mov    DX,0F4Bh            ;bottom right row 15 / column 75
   Int    10h                 ;call BIOS

   Mov    DX,CGAPort

Start_Point:

   Mov    First,1             ;initial file number
   Mov    FileNo,1          

Display:

   Mov    DI,1454             ;screen offset of first file
   Mov    BP,AAdr             ;get address of first file in table
   Mov    BX,First            ;set counter at First

Next_File:

   Mov    AH,Color1           ;color attribute to use for file display
   Cmp    BX,FileNo           ;is this the cursor?
   Jne    Regular_File        ;no, then continue

   Mov    AH,Color3           ;yes, do filename below box
   Push   DI                  ;save current screen address
   Mov    DI,2914             ;show file name below box
   Mov    SI,[BP+02]
   Mov    CX,12               ;length of file
   Call   PutString           ;put the filename on screen
   Pop    DI                  ;restore DI
   Mov    AH,Color2           ;use color for cursor

Regular_File:

   Mov    SI,[BP+02]          ;get first character
   Mov    CX,12               ;length of string
   Call   PutString

   Cmp    BX,Last             ;is this the last file?
   Je     Do_Blanks           ;yes, then fill remaining field with blanks
   Inc    BX                  ;move counter to next file
   Add    BP,4                ;set BP to point to next file address
   Add    DI,136              ;next row
   Cmp    DI,2574             ;is this the bottom row?
   Jb     Next_File           ;no, then continue down the column
   Sub    DI,1092             ;yes, move to next column
   Cmp    DI,1566             ;have we done the rightmost column?
   Ja     Get_Key             ;yes, then get user key
   Jmp    Next_File           ;no, then get more

Do_Blanks:

   Mov    AH,Color1           ;set the element color
   Mov    AL," "              ;put space character in AL

Blank_Return:

   Add    DI,136              ;next row
   Cmp    DI,2574             ;is this the bottom row?
   Jb     Next_Blank          ;no, then continue down the column
   Sub    DI,1092             ;yes, move to next column
   Cmp    DI,1566             ;have we done the rightmost column?
   Ja     Get_Key             ;yes, then get key

Next_Blank:

   Mov    CX,12               ;set element length
   Call   RepStoswSub
   Jmp    Blank_Return

Get_Key:

   Mov    AH,0                ;call BIOS service to get key
   Int    16h                 ;pressed key given in AL
   Cmp    AL,0                ;check if extended code?
   Jz     Down_Arrow          ;yes, then check for down arrow and others

   Xor    AH,AH               ;clear contents of AH

Exit:

   Mov    BP,SP               ;ensure at start of stack
   Mov    SI,ScanCode         ;put address of ScanCode in SI
   Mov    [SI],AX             ;set ScanCode%
   Mov    AX,FileNo           ;get current file number
   Mov    SI,Count            ;put address of Count in SI
   Mov    [SI],AX             ;put in Count
   Pop    BP
   Ret    14

Down_Arrow:

   Cmp    AH,80               ;has down arrow been pressed?
   Jne    Up_Arrow            ;no, check for up arrow

   Mov    BX,FileNo
   Cmp    Last,BX             ;are we on the last file?
   Je     Get_Key             ;yes, then get again

   Inc    FileNo              ;goto to next file number

Check_Right:

   Mov    BX,FileNo
   Sub    BX,First            ;FileNo - First  in BX
   Cmp    BX,35               ;are we still on the table?
   Jae    Move_Table_Right    ;no, so move it
   Jmp    Display             ;yes, go display table

Move_Table_Right:

   Add    First,7             ;advance First by 7 files
   Add    AAdr,28             ;move table by one column
   Jmp    Display

Up_Arrow:

   Cmp    AH,72               ;has up arrow been pressed?
   Jne    Left_Arrow          ;no, check for left arrow

   Cmp    FileNo,1            ;are we at first file?
   Je     Get_Key             ;yes, then get again

   Dec    FileNo              ;move back one file name

Check_Left:

   Mov    BX,FileNo
   Sub    BX,First            ;FileNo - First  in BX
   Js     Move_Table_Left     ;not on table if sign flag set, so move it
   Jmp    Display             ;go display the table

Move_Table_Left:

   Sub    First,7             ;reduce First by 7 files
   Sub    AAdr,28             ;move table by one column to the left
   Jmp    Display

Left_Arrow:

   Cmp    AH,75               ;has left arrow been pressed?
   Jne    Right_Arrow         ;no, check for right arrow

   Cmp    FileNo,7            ;is file number greater than number of rows?
   Ja     Left_Okay           ;yes, then left arrow is allowed
   Jmp    Start_Point         ;no, start again

Left_Okay:

   Sub    FileNo,7            ;move back 7 file names
   Jmp    Check_Left          ;go check whether table needs shifting left

Right_Arrow:

   Cmp    AH,77               ;has right arrow been pressed?
   Je     Do_Right_Arrow      ;yes, then do it
   Mov    AL,AH               ;no, move scan code to AL
   Xor    AH,AH               ; and clear AH
   Neg    AX                  ; change sign of AX
   Jmp    Exit                ; and return with scan code

Do_Right_Arrow:

   Add    FileNo,7            ;move cursor ahead by 7 files
   Mov    AX,FileNo
   Sub    AX,Last             ;FileNo - Last  in AX
   Js     Check_Right         ;if sign flag is set then no need to adjust

   Mov    BX,Last
   Mov    FileNo,BX           ;make FileNo = Last
   Jmp    Check_Right

;----------------------------------------------------------------------------
Dec_Div Proc Near             ;Subroutine to divide number in BX by number in
                              ;CX, and print quotient on screen
                              ;(numerator in AX and DX, denominator in CX)

   Mov    AX,BX               ;number in high half
   Xor    DX,DX               ;zero out low half
   Div    CX                  ;divide by CX
   Push   DX                  ;save remainder on stack
   Add    AL,30h              ;convert to ASCII
   Mov    BL,AL               ;put character in BL
   Mov    AH,Color3           ;color attribute to use
   Mov    DX,CGAPort
   Call   StoswSub            ;put it on screen
   Pop    BX                  ;restore remainder into BX
   Ret

Dec_Div EndP
;----------------------------------------------------------------------------
DirFile EndP
End

