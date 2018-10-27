;****** ColorPik.Asm - prints Color Chart at current cursor location
;                      must be enough room to fit 34 col wide and 18 rows high

;Copyright (c) 1990 Crescent Software
;Copyright (c) 1990 Jay Munro

;syntax: CALL ColorPick(Colr%, BoxColor%, ExitCode%)
;
;Colr% is the color they picked, and ExitCode% is 0 if they pressed Enter,
;or 2 if they pressed Escape.  If Escape, then the Colr% parameter is left
;unchanged.  If ExitCode% is -1 on entry, the chart is simply displayed.


.Model Medium,BASIC
.Data

    Extrn MonSeg: Word     ;these are in Monitor.Asm
    Extrn CGAPort:Word

.Code
Extrn Monitor: Proc        ;so we can access the monitor type

ColorPick Proc Uses ES SI DI, Color_Char:Ptr, BoxColr:Ptr, ExitCode:Ptr

    Cmp  MonSeg,0          ;has Monitor been used yet?
    Jnz  MonOkay           ;yes, skip ahead
    Call Monitor           ;no, call it to set the segment and retrace words

MonOkay:
    Push DS                ;push DS since we are using it
    Mov  SI,Color_Char     ;get the incoming color value
    Mov  AL,[SI]           ;put it in AL
    And  AL,127            ;kill flashing if passed
    Mov  CS:Current_Color,AL ;save it locally
    Mov  AH,3              ;BIOS service to read current cursor position
    Xor  BH,BH             ;specify text page zero
    Push BP                ;some old PC BIOS's trash BP during an Int 10h
    Int  10h               ;this service returns with the row/column in DH/DL
    Pop  BP

    Mov  AL,DH             ;put the current row number into AL
    Mov  CL,160            ;multiply times 160 for base address of current row
    Mul  CL                ;do the multiplication - answer ends up in AX
    Xor  DH,DH             ;clear DH for Add below, we only want DL
    Add  AX,DX             ;once for the character byte
    Add  AX,DX             ;and once for the attribute byte
    Mov  DI,AX             ;DI now holds starting memory position on screen
    Mov  CS:Start_Cursor,AX ;save original cursor position for later
    Mov  DX,CGAPort        ;get CGA port if needed from monitor
    Mov  ES,MonSeg         ;put the correct monitor segment into ES

Print_Chart:
    Mov  SI,BoxColr        ;get normal color
    Mov  AL,[SI]
    Mov  CS:Color1, AL     ;save it locally in Color1
    Mov  SI,ExitCode       ;check ExitCode% on way in
    Mov  AL,[SI]           ;stash it away
    Mov  CS:Exit_Code,AL
    Push CS                ;make DS equal CS
    Pop  DS                ;    to find our data later
    Assume DS: @Code       ;so MASM will know that DS points to code segment
    Call DoBocC            ;make box around Chart

    Mov  DI,Current_Cursor ;load DI with current cursor
    Mov  CX,16             ;we will be printing 16 colors down
    Cld                    ;all string moves will be forward direction
    Mov  BL,8              ;we will be printing 8 colors across
    Mov  BH,32             ;load a space for between colors
    Xor  AL,AL             ;start with 0 for colors

Print_It:
    Mov  AH,AL             ;put current color in high byte
    Call Print_Color       ;show it
    Inc  AL                ;go on to the next color
    Add  Current_Cursor,160  ;jump to next row
    Cmp  CL,1              ;are we at last color?
    Je   Next_Row          ;yes, skip the space chars at end of row
    Mov  DI,Current_Cursor ;no, get current cursor
    Loop Print_it          ;until done CX times

Next_Row:
    Add  Last_Location,8   ;drop cursor location to next line
    Mov  DI,Last_Location  ;put it in DI for UnHiLiteC later
    Mov  Current_Cursor,DI ;
    Mov  CL,16             ;set up CL for 16 more colors
    Dec  BL                ;decrement row count
    Jnz  print_it          ;go for more
    Cmp  Exit_Code,-1      ;if it's a -1 then don't take input
    Jnz  Go_For_Input      ;anything else keep going
    Pop  DS                ;get our data segment back
    Jmp  Exit              ;bye

Go_For_Input:
    Mov  AL,Current_Color  ;put current char in AL
    Call HiLiteC            ;flash it
    Mov  AL,Current_Color  ;get current color again
    Mov  Last_Color,AL     ;make last color same as current color

Get_Char:                  ;handles character input etc...
    Call UnHiLiteC         ;blank out current color
    Mov  AL,Current_Color  ;get current color number
    Mov  Last_Color,AL     ;load last color
    Call HiLiteC           ;highlight current color
    Call GetaKeyC          ;grab some input
    Or   AL,AL             ;is it a special key?
    Jz   Get_Other_Char    ;yes, get other half
    Cmp  AL,27             ;is it an Escape character?
    Je   Leave             ;  yes, bag out without saving
    Cmp  AL,13             ;is it a Return?
    Jz   Save_Char         ;  yes, go save it
    Jmp  Short Get_Char    ;  so just go back for more input

Save_Char:
    Pop  DS                ;get back DS so we can save to passed params
    Xor  AH,AH             ;clear AH
    Mov  SI,ExitCode       ;get address of ExitCode%
    Mov  Byte ptr [SI],0   ;set it to 0 for Enter
    Mov  AL,CS:Current_Color  ;get current color value
    Mov  SI, Color_Char    ;save the color value
    Mov  Byte ptr [SI], AL ;put AL into Color_Char and exit
    Jmp  Exit

Leave:
    Pop  DS                ;get back DS so we can save to passed params
    Mov  SI,ExitCode       ;get address of ExitCode%
    Mov  Byte ptr [SI],2   ;set it to 2 for Escape
    Jmp  Exit              ;bye

Get_Other_Char:
    Cmp  AH,75             ;is it an Left arrow?
    Jne  Right_Arrow       ;no, go to next test
    Mov  AL,Current_Color  ;make copy of current color
    Sub  Current_Color,16  ;subtract 16 to go over one column
    Cmp  AL,16             ;if last color was less than 16
    Jb   Check_Up          ;handle specially
    Jmp  Short Get_Char    ;otherwise leave -16

Check_Up:
    Or   AL,AL             ;was last color at 0?
    Jnz  Slide_Over        ;  no skip
    Add  AL,127            ;yes, make color 127
    Mov  Current_Color,AL  ;and update current color value
    Jmp  Short Get_Char

Slide_Over:
    Add  AL,111            ;add 111 to original number in AL
    Mov  Current_Color,Al  ;put it back
    Jmp  Short Get_Char    ;go again

Right_Arrow:
    Cmp  AH,77             ;is it a Right Arrow?
    Jne  Up_arrow          ;no, go to next test
    Mov  AL,Current_Color  ;make copy of current color
    Add  Current_Color,16  ;add 16 to it for over one column
    Cmp  AL,112            ;did we go too far?
    Jb   Leave_Keys        ;no, go back for more
    Cmp  AL,127            ;was last color a 127?
    Jz   Fix127            ;yes, jump again
    Sub  Current_Color,127 ;no, adjust to wrap around
    Jmp  Get_Char

Fix127:
    Mov  Current_Color,0   ;go right to 0
    Jmp  Get_Char

Up_Arrow:
    Cmp  AH,72             ;is it an Up arrow?
    Jne  Down_Arrow        ;no, go to next test
    Dec  Current_Color     ;back up one
    Cmp  Current_Color,-1  ;check if we went back too far
    Jne  NotTooLow
    Mov  Current_Color,127 ;retread to the max

NotTooLow:
    Jmp  Get_Char

Down_Arrow:
    Cmp  AH,80             ;is it a Down arrow?
    Jne  Home              ;no, go to next test
    Inc  Current_Color     ;advance one
    Cmp  Current_Color,127 ;oops, did we go too far?
    Jbe  NotOver           ;nope
    Mov  Current_Color,0   ;yes, reset to start

NotOver:
    Jmp  Get_Char

Leave_keys:
    Jmp  Get_Char

Home:
    Cmp  AH,71             ;is it the Home key?
    Jne  End_Key           ;no, go to next test
    Mov  Current_Color,0   ;yes, go to start
    Jmp  Get_Char

End_Key:
    Cmp  AH,79             ;is it the End key?
    Jne  Page_Down         ;no, go to next test
    Mov  Current_Color,127 ;yes, go to end
    Jmp  Get_Char

Page_Down:                 ;takes cursor to bottom of a row
    Cmp  AH,81
    Jne  Page_Up
    Mov  AH,Current_Color  ;get current_color
    Mov  CL,4              ;divide by 16 for horizontal position
    Shr  AX,CL             ;divide
    Shr  AL,CL             ;get remainder
    Mov  AH,15             ;put 15 into AH to calculate offset
    Sub  AH,AL             ;get offset to end of column
    Add  Current_Color,AH  ;add to current color
    Jmp  Get_Char

Page_Up:
    Cmp  AH,73
    Jne  Go_For_More
    Mov  AH,Current_Color  ;get Current_Color
    Mov  CL,4              ;divide by 16 for horizontal position
    Shr  AX,CL             ;divide
    Shr  AL,CL             ;get remainder
    Sub  Current_Color,AL  ;subtract from current color to get to top
    Jmp  Get_Char

Go_For_More:
    Jmp  Get_Char

Exit:                      ;End of main program
    Ret

;Datastuff

    Color1           DB  ? ;normal color
    Start_Cursor     DW  ? ;save the upper left cursor position
    Current_Cursor   DW  ? ;where we are now
    Current_Color    DB  ? ;current color value to be passed back
    Last_Location    DW  ? ;the last place where cursor was
    Scratch          DW  ? ;misc. stuff
    Exit_Code        DB  ? ;hold exit code
    Top              DB  "ษออออออออออออออออออออออออออออออออป"
    Middle           DB  "บ   ฑ   ฑ   ฑ   ฑ   ฑ   ฑ   ฑ   ฑบ"
    Bottom           DB  "ศออออออออออออออออออออออออออออออออผ"
    Last_Color       DB  ? ;last color variable

ColorPick EndP

;================================================= Get a key
GetaKeyC      Proc    Near
NoInput:
    Mov  AH,1              ;check keyboard buffer
    Int  16h               ;using BIOS for compatability
    Jz   NoInput           ;if no key waiting, then keep checking
    Xor  AH,AH             ;use BIOS call
    Int  16h               ; to get key in AL/AH
    Ret

GetaKeyC      Endp

;============================================================

HiLiteC    Proc    Near
    Cld                    ;string moves in forward direction
    Mov  AH,Current_Color  ;get current color
    Mov  DI,Start_Cursor   ;use starting cursor + offset to highlight
;figure horzontal position
    Mov  CL,4              ;divide by 16 for horizontal position
    Shr  AX,CL             ;divide
    Shr  AL,CL             ;get remainder
    Xor  AH,AH             ;clear high stuff
    Mov  DX,AX             ;save it in DX for figuring
    Mov  AX,160            ;load with line offset (160 bytes per line)
    Mul  DX                ;get proper location
    Add  DI,AX             ;store horizontal location (Col)

;vertical position
    Mov  AH,Current_Color  ;get current color value
    Shr  AH,CL             ;get vertical location (Row)
    Shl  CL,1              ;double CX for a shift by 8
    Shr  AX,CL
    Shl  AL,1              ;multiply by 2 since we skip a space
    Shl  AL,1              ;multiply again for 4
    Shl  Al,1              ;and another 2 since we are in words

    Add  DI,AX             ;put it in DI
    Mov  Current_Cursor,DI ;retread current cursor
    Mov  AL,Current_Color  ;get current color
    Mov  AH,AL             ;get color
    Or   AH,128            ;flash it (Color OR 128 = flashing)
    Call Print_Color       ;print it
    Mov  DI,Current_Cursor ;get cursor location again
    Add  DI,6              ;slip over the color we just printed
    Mov  AL,17             ;put a pointer character
    Mov  AH,112            ;use white for clarity
    Call Print_CharC       ;print it
    Ret

HiLiteC    EndP

UnHiLiteC  Proc     Near
    Push AX                 ;save AX
    Mov  DI, Current_Cursor ;point DI to current location
    Mov  AH,Last_Color      ;get color of last one
    Mov  AL,AH              ;and number to print
    Call Print_Color        ;print it
    Mov  DI, Current_Cursor ;move current cursor to DI
    Add  DI,6               ;slide over 6 bytes (color)
    Mov  AL,177             ;load a texture character
    Mov  AH,Color1          ; in normal background color
    Call Print_CharC        ;print it
    Pop  AX
    Ret

UnHiLiteC    EndP

Print_CharC      Proc    Near
    Push AX
    Push BX
    Mov  BX,AX             ;save our stuff
    Or   DL,DL             ;are we doing monochrome or EGA?
    Jz   Mono_Ega          ;yes, go do it

No_Retrace:
    In   AL,DX             ;get the video status byte
    Test AL,1              ;test just the horizontal retrace bit
    Jnz  No_Retrace        ;if doing a retrace, wait until it's not
    Cli                    ;disable interrupts until done writing to screen

Retrace:
    In   AL,DX             ;get the status byte again
    Test AL,1              ;are we currently doing a retrace?
    Jz   Retrace           ;no, wait until we are

Mono_EGA:
    Mov  AX,BX
    Stosw                  ;store character and attribute into screen memory
    Sti                    ;re-enable interrupts
    Pop  BX                ;put registers back to original
    Pop  AX
    Ret

Print_CharC    EndP

DoBocC         Proc   Near
    Mov  AH,Color1         ;get color for Box & Background
    Mov  DI,Start_Cursor   ;get start cursor
    Mov  BX,DI             ;save starting location
    Mov  SI,Offset Top     ;get address of box top data
    Mov  CX,34             ;set CX to length of data

DoTop:
    LodSb                  ;get a byte of data
    Call Print_CharC       ;print it
    Loop DoTop             ;go back for more
    Add  BX,160            ;move to beginning of next line
    Mov  DI,BX             ;point DI to it
    Mov  CX,34             ;set length of data again
    Mov  Scratch,16        ;make a counter
    Mov  SI,Offset Middle  ;point SI to middle data

DoMid:
    LodSB                  ;get a byte of data
    Call Print_CharC       ;print it
    Loop DoMid             ;continue
    Mov  SI, Offset Middle ;reset SI to start of data
    Add  BX,160            ;move to next line on screen
    Mov  DI,BX             ;point DI to it
    Mov  CX,34             ;again do 34 characters
    Dec  Scratch           ;decrement our counter
    Jnz  DoMid             ;keep printing if counter isn't 0
    Mov  SI,Offset Bottom  ;point SI to Bottom data
    Mov  DI,BX             ;point DI to next line
    Mov  CL,34             ;set CL to length of data

DoBottom:
    LodSb                  ;get a byte of data
    Call Print_CharC       ;print it
    Loop DoBottom          ;go back for more
    Mov  AX,Start_Cursor   ;get starting cursor
    Add  AX,2              ;slide over one space
    Add  AX,160            ;drop down one line
    Mov  Start_Cursor, AX  ;reset start cursor to new position
    Mov  Current_Cursor, AX;ditto for current cursor
    Mov  Last_Location, AX ;ditto for last location
    Mov  DI,AX             ;point DI at current cursor

BoxOut:
    Ret
DoBocC         EndP

Print_Color     Proc     Near
    Push AX                ;save registers used
    Push BX
    Push CX
    Mov  BL,AH             ;save color attribute for now
    Add  DI,4              ;slide over message to clear area
    Mov  CL,3              ;allow 3 digits to be printed
    Std                    ;and do it backward
    Jmp  Divide_upCol      ;print it

Next_Digit:
    Mov  AH," "            ;print a space
    Or   AL,AL             ;is AL a 0?
    Jz   DisplayNum        ;yes

Divide_upCol:
    Mov  BH,10             ;divisor of 10
    Xor  AH,AH             ;clear high byte
    Div  BH                ;divide AL by 10
    Add  AH,"0"            ;convert it to ASCII (ie 1 + "0" = ASCII 49 = "1")

DisplayNum:
    Mov  Scratch,AX        ;save number for a moment
    Xchg AL,AH             ;put ASCII number into AL
    Mov  AH,BL             ;and it is normal color
    Call Print_CharC       ;print it
    Xchg AX,Scratch        ;put AL back in AH
    Loop Next_Digit        ;do it again
    Cld                    ;reset direction
    Pop  CX
    Pop  BX
    Pop  AX
    Ret

Print_Color   EndP

End                        ;th, th, th, that's all folks. . .
