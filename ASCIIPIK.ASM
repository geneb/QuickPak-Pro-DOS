;----- ASCIIPik.Asm - sub routine to print set and return character selected

;Copyright (c) 1988 Jay Munro

.Model Medium
.Data

    Extrn MonSeg: Word      ;these are in Monitor.Asm
    Extrn CGAPort:Word

.Code
Extrn Monitor: Proc         ;so we can access the monitor type
Include Mixed.Inc

HProc ASCIIPick, ASCII_Char:Ptr, Colr1:Ptr, Colr2:Ptr, ExitCode:Ptr

    Cmp  MonSeg,0           ;has Monitor been used yet?
    Jnz  MonOkay            ;yes, skip ahead
    Call Monitor            ;no, call it to set the segment and retrace words

MonOkay:
    Push DS                 ;push DS since we are using it
    Mov  SI,ASCII_Char      ;get the incoming character value
    Mov  AL,[SI]            ;put it in AL
    Mov  CS:Current_Char,AL ;save it locally
    Mov  AH,3               ;specify BIOS service to read the current cursor position
    Xor  BH,BH              ;specify text page zero
    Push BP                 ;some old PC BIOS's trash BP during an Int 10h
    Int  10h                ;this service returns with the row/column in DH/DL
    Pop  BP
    Mov  CS:ULRow,DH        ;get current row into ULRow for mouse trap
    Mov  CS:ULCol,DL        ;get current col into ULCol for mouse trap
    Add  CS:ULCol,3         ;adjust to inside of box
    Add  CS:ULRow,2         ;adjust to inside of box
    Mov  AL,DH              ;put the current row number into AL
    Mov  CL,160             ;muliply times 160 for address of current row
    Mul  CL                 ;do the multiplication - answer ends up in AX
    Xor  DH,DH              ;clear DH for Add below, we only want DL
    Add  AX,DX              ;once for the character byte
    Add  AX,DX              ;and once for the attribute byte

    Mov  DI,AX              ;DI now holds starting memory position on display
    Mov  CS:Start_Cursor,AX ;save original cursor position for later
    Mov  DX,CGAPort         ;get CGA port if needed from monitor
    Mov  ES,MonSeg          ;through ES

Print_Chart:
    Mov  CX,16              ;we will be printing 16 characters across
    Cld                     ;all string moves below will be forward
    Mov  BL,CL              ;we will be printing 16 characters down
    Mov  BH,32              ;load a space for between characters
    Mov  SI,Colr2           ;get highlight color
    Mov  AL,[SI]            ;save it
    Mov  SI,Colr1           ;get normal color
    Mov  AH,[SI]            ;save it
    Push AX                 ;hang on to AX for a second
    Mov  SI,ExitCode        ;check exitcode on way in
    Mov  AL,[SI]            ;stash it away
    Mov  CS:Exit_Code,AL    ;in a local variable
    Pop  AX                 ;get AX back
    Push CS                 ;point DS at CS
    Pop  DS                 ;to find our data later
    Assume DS: @Code        ;so MASM will know that DS points to code segment
    Mov  Color2,AL          ;load color 2
    Mov  Color1,AH          ;load color 1

    Call DoBox              ;make box around Chart
    Mov  AH,Color1          ;load color 1 for ASCII characters
    Xor  AL,AL              ;clear AL for incrementing

Print_It:
    Call Print_Char
    Inc  AL                 ;make next char
    Cmp  CL,1               ;are we at last character?
    Je   Next_Row           ;yes, skip the space chars at end of row
    Xchg AL,BH              ;swap the character and attribute
    Call Print_Char         ;print the color
    Xchg AL,BH              ;swap back
    Loop Print_it           ;until done CX times

Next_Row:
    Add  Last_Location,160  ;drop cursor location to next line
    Mov  DI,Last_Location   ;put it in DI for
    Mov  CL,16              ;set up CL for 16 more characters
    Dec  BL                 ;dec row count
    Jnz  Print_it           ;go for more

    Cmp  CS:Exit_Code,-1    ;if it's a -1 then don't take input
    Jnz  Get_Char           ;anything else keep going
    Call HiLite             ;update our screen
    Pop  DS                 ;get our data segment back
    Jmp  Exit               ;bye

;========================= end of ASCII chart print

Get_Char:                   ;handles character input etc...
    Call UnHilite           ;blank out current character
    Mov  AL,Current_Char    ;Get current ASCII character
    Call HiLite             ;Hilight current character

    Call GetaKey            ;grab some input
    Or   AL,AL              ;is it a special key?
    Jz   Get_Other_Char     ;yes, get other half
    Cmp  AL,27              ;is it an ESC char?
    Je   Leave              ;  yes bag out without saving
    Cmp  AL,13              ;is it a return?
    Jz   Save_Char          ;  yes, go save it
    Mov  Current_Char,AL    ;it is a normal char or <ALT> + number
    Jmp  Short Get_Char     ;  so just back for more input

Save_Char:
    Pop  DS                 ;get back DS so we can save to passed params
    Xor  AH,AH              ;clear ah
    Mov  SI,ExitCode        ;get address of exitcode
    Mov  Byte Ptr [SI],0    ;set it to 0 for Enter
    Mov  AL,CS:Current_Char ;get current character
    Mov  SI,ASCII_Char      ;yes, save the ASCII value
    Mov  Byte Ptr [SI], AL  ;put AL into ASCII_Char and exit
    Jmp  Exit

Leave:
    Pop  DS                 ;get back DS so we can save to passed params
    Mov  SI,ExitCode        ;get address of exitcode
    Mov  Byte Ptr [SI],2    ;set it to 2 for Escape
    Jmp  Exit               ;bye

Get_Other_Char:
    Cmp  AH,72              ;is it an up arrow?
    Jne  Down_Arrow         ;no go to next test
    Mov  AL,Current_Char    ;make copy of current character
    Sub  Current_Char,16    ;subtract 16 to go up one row
    Cmp  AL,16              ;if last character was less than 16
    Jb   Check_Up           ;handle specially
    Jmp  Short Get_Char     ;otherwise leave -16

Check_Up:
    Or   AL,AL              ;was last character at 0
    Jnz  Slide_Over         ;  no skip
    Add  AL,255             ;yes, make character 255
    Mov  Current_Char,AL    ;and update current character
    Jmp  Short Get_Char

Slide_Over:
    Add  AL,239             ;add 239 to original number in AL
    Mov  Current_Char,AL    ;put it back
    Jmp  Short Get_Char     ;go again

Down_Arrow:
    Cmp  AH,80              ;is it a down arrow?
    Jne  Left_Arrow         ;no go to next test
    Mov  AL,Current_Char    ;make copy of current character
    Add  Current_Char,16    ;add 16 to it for down one row
    Cmp  AL,240             ;did we go too far?
    Jb   Leave_Keys         ;no go back for more
    Cmp  AL,255             ;was last char a 255?
    Jz   Fix255             ;yes, jump again
    Inc  Current_Char       ;no just bump char number up one
    Jmp  Get_Char

Fix255:
    Mov Current_Char,0      ;go right to 0
    Jmp Get_Char

Left_Arrow:
    Cmp  AH,75              ;is it a left arrow?
    Jne  Right_Arrow        ;no go to next test
    Dec  Current_Char       ;back up one
    Jmp  Get_Char

Right_Arrow:
    Cmp  AH,77              ;is it a right arrow?
    Jne  Home               ;no go to next test
    Inc  Current_Char       ;advance one
    Jmp  Get_Char

Home:
    Cmp  AH,71              ;is it the home key?
    Jne  End_Key            ;no go to next test
    Sub  Current_Char,17    ;back up one row - 1 char
    Jmp  Get_Char

End_Key:
    Cmp  AH,79              ;is it the end key?
    Jne  Ctrl_End           ;no go to next test
    Add  Current_Char,15    ;advance one row - 1 char
    Jmp  Get_Char

Ctrl_End:
    Cmp  AH,117             ;is it ctrl-end?
    Jne  Ctrl_Home          ;no go to next test
    Mov  Current_Char,255   ;go to last char (255)
    Jmp  Get_Char

Ctrl_Home:
    Cmp  AH,119             ;is it ctrl-home?
    Jne  Pg_Down            ;no go to next test
    Mov  Current_Char,0     ;go to first char (0)
    Jmp  Get_Char

Pg_Down:
    Cmp  AH,81              ;is it page down?
    Jne  Pg_Up              ;no go to next test
    Add  Current_Char,17    ;advance one row + 1 char
    Jmp  Get_Char

Pg_Up:
    Cmp  AH,73              ;is it page up?
    Jne  Leave_Keys         ;no go to next test
    Sub  Current_Char,15    ;go back 1 row ,over 1
    Jmp  Get_Char

Leave_Keys:                  ;none of the above
    Jmp  Get_Char            ;go get another character

Exit:                        ;End of main program
    HRet

;Datastuff

    Color1            DB  ? ;normal color
    Color2            DB  ? ;highlight color
    Start_Cursor      DW  ? ;save the Upper left cursor position
    Current_Cursor    DW  ? ;where we are now
    Current_Char      DB  ? ;current ASCII value to be passed back
    Message_Location  DW  ? ;where to print message
    Last_Location     DW  ? ;the last place where cursor was
    Scratch           DW  ? ;misc stuff
    Exit_Code         DB  ? ;hold exit code
    Top               DB  "ษอออออออออออออออออออออออออออออออออป"
    Middle            DB  "บ                                 บ"
    Bottom            DB  "ศต ASCII Code: Dec       Hex     ฦผ"
    UlCol             DB  ? ;Upper Left colunm of chart
    UlRow             DB  ? ;Upper Left Row of Chart

HEndP



;================================================= End of Main

GetAKey      Proc    Near
    Xor  AH,AH              ;use BIOS call
    Int  16h                ; to get key in AL/AH
    Ret
GetAKey      Endp



HiLite    Proc    Near
   Cld
   Mov  DI,Start_Cursor
   Mov  AH,Current_Char    ;get current ASCII value
   Mov  CL,4               ;divide by 16 for horizontal pos
   Shr  AX,CL
   Shr  AL,CL              ;get remainder
   Shl  AL,1               ;multiply by 2 since we skip a space
   Shl  AL,1               ;and another 2 since we are in words
   Xor  AH,AH              ;Clear high stuff
   Add  DI,AX              ;store horizontal location (Col)
   Mov  AH,Current_Char    ;get current ASCII value
   Shr  AH,CL              ;get vertical location (Row)
   Shl  CL,1               ;double CX for a shift by 8
   Shr  AX,CL
   Mov  DX,AX
   Mov  AX,160             ;load with line offset
   Mul  DX                 ;get proper location
   Add  DI,AX              ;put it in DI
   Mov  AH,Color2          ;put color in AL
   Mov  Current_Cursor,DI  ;retread current cursor
   Mov  AL,Current_Char    ;get current character
   Call Print_Char         ;print it
   Call Print_ASCII        ;print ASCII code
   Ret
HiLite    EndP



UnHilite  Proc     Near
   Push AX                 ;save AX
   Mov  DI, Current_Cursor ;point DI to attribute
   Inc  DI
   Mov  Ah,Color1          ;get normal color
   Or   DL,DL              ;are we doing monochrome or EGA?
   Jz   Mono_Ega1          ;yes, go do it

No_Retrace1:
   In   AL,DX              ;get the video status byte
   Test AL,1               ;test just the horizontal retrace bit
   Jnz  No_Retrace1        ;if doing a retrace, wait until it's not
   Cli                     ;disable interrupts until we're done writing to screen

Retrace1:
   In   AL,DX              ;get the status byte again
   Test AL,1               ;are we currently doing a retrace?
   Jz   Retrace1           ;no wait until we are

Mono_EGA1:
   Mov   AL,AH             ;put attribute in AL
   Stosb                   ;store attribute into screen memory
   Sti                     ;re-enable interrupts
   Pop   AX                ;retrieve AX
   Ret

UnHilite    EndP



Print_ASCII     Proc     Near
   Cld
   Mov  DI,Message_Location ;point DI to message where message is going
   Mov  CL,3               ;we need 3 spaces
   Mov  AH,Color1          ;and it is normal color
   Mov  AL,32              ;make space

Do_Message:
   Call Print_Char         ;print them
   Loop Do_Message         ;continue till CX is 0
   Mov  DI,Message_Location ;get message location again
   Add  DI,4               ;slide over message to clear area
   Mov  AL,Current_Char    ;Get character
   Mov  CL,3               ;allow 3 digits to be printed
   Std                     ;and do it backward
   Jmp  Divide_Up          ;print it

Next_Char:
   Mov  AH," "             ;print a space
   Or   AL,AL              ;is AL a 0
   Jz   Display            ;yes

Divide_up:
   Mov  Bh,10              ;divisor of 10
   Xor  AH,AH              ;clear high byte
   Div  BH                 ;divide AL by 10
   Add  AH,"0"             ;convert it to ASCII (ie 1 + 32 = ASCII 33 (1))

Display:
   Mov  Scratch,AX         ;save number for a moment
   Xchg AL,AH              ;put ASCII number into AL
   Mov  AH,Color1          ;put color attribute in AH
   Call Print_Char         ;print it
   Xchg AX,Scratch         ;put AL back in AH
   Loop Next_Char          ;do it again
   Cld                     ;reset direction

PrintHex:
   Mov CL,2                ;clear 2 characters
   Mov DI,Message_Location ;get message location
   Add DI,16               ;put into position
   Mov AH,Color1           ;for background color
   Mov AL,32               ;space char

ClearHex:
   Call Print_Char         ;print a space
   Loop ClearHex           ;keep going
   Mov  Ch,2               ;2 digits
   Mov  BL,Current_Char    ;get our current char

DoHexChar:
   Mov  CL,4               ;for Rotate -> 4 bits
   Rol  BL,CL              ;move low byte to high
   Mov  AL,BL              ;put in AL for doing
   And  AL,0Fh             ;clear left digits
   Add  AL,30h             ;convert to ASCII
   Cmp  AL,3Ah             ;is is > 9?
   Jl   ShowChar           ;go print it if between 0 - 9
   Add  AL,7h              ;convert to A - F

ShowChar:
   Call Print_Char         ;print digit
   Dec  CH                 ;get next one if there
   Jnz  DoHexChar
   Ret                     ;bye

Print_ASCII   EndP



Print_Char      Proc    Near
    Push AX
    Push BX
    Mov  BX,AX             ;save our stuff
    Or   DL,DL             ;are we doing monochrome or EGA?
    Jz   Mono_Ega          ;yes, go do it

No_Retrace:
    In   AL,DX             ;get the video status byte
    Test AL,1              ;test just the horizontal retrace bit
    Jnz  No_Retrace        ;if doing a retrace, wait until it's not
    Cli                    ;disable interrupts until we're done writing to screen

Retrace:
    In   AL,DX             ;get the status byte again
    Test AL,1              ;are we currently doing a retrace?
    Jz   Retrace           ;no wait until we are

Mono_EGA:
    Mov  AX,BX
    Stosw                  ;store the character and attribute into screen memory
    Sti                    ;re-enable interrupts
    Pop  BX                ;put registers back to original values
    Pop  AX
    Ret

Print_Char    EndP



DoBox         Proc   Near
    Push BX                ;save stuff
    Push CX
    Push DX
    Mov  DI,Start_Cursor   ;get start cursor
    Mov  BX,DI             ;save starting location
    Mov  SI,Offset Top     ;get address of box top data
    Mov  CX,35             ;set CX to length of data

DoTop:
    Lodsb                  ;get a byte of data
    Call Print_Char        ;print it
    Loop DoTop             ;go back for more
    Add  BX,160            ;move to beginning of next line
    Mov  DI,BX             ;point DI to it
    Mov  CX,35             ;set length of data again
    Mov  Scratch,16        ;make a counter
    Mov  SI,Offset Middle  ;point SI to middle data

DoMid:
    Lodsb                  ;get a byte of data
    Call Print_Char        ;print it
    Loop DoMid             ;continue
    Mov  SI,Offset Middle  ;reset SI to start of data
    Add  BX,160            ;move to next line on screen
    Mov  DI,BX             ;point DI to it
    Mov  CX,35             ;again do 35 characters
    Dec  Scratch           ;decrement our counter
    Jnz  DoMid             ;keep printing if counter isn't 0
    Mov  SI,Offset Bottom  ;point SI to Bottom data
    Mov  DI,BX             ;point DI to next line
    Mov  CL,35             ;set CX to length of data

DoBottom:
    LodSb                  ;get a byte of data
    Call Print_Char        ;print it
    Loop DoBottom          ;go back for more
    Mov  AX,Start_Cursor   ;get starting cursor
    Add  AX,4              ;slide over 2 spaces
    Add  AX,160            ;drop down one line
    Mov  Start_Cursor, AX       ;reset start cursor to new position
    Mov  Current_Cursor, AX     ;ditto for current cursor
    Mov  Last_Location, AX      ;ditto for last location
    Mov  Message_Location, AX   ;ditto for here but...
    Add  Message_Location, 2596 ;  adjust edge + 2596
    Mov  DI,AX                  ;point DI at current cursor

BoxOut:
    Pop  DX                ;put things back
    Pop  CX
    Pop  BX
    Ret

DoBox      EndP

End                        ;th,th,th,that's all folks. . .
