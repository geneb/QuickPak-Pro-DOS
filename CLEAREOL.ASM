;----- ClearEOL.Asm - clears to the end of the current line on current page

;Copyright (c) 1988 Ethan Winer


;Syntax - LOCATE V, H: CALL ClearEOL(Colr%)

;where Colr% is the color to clear to, or use -1 to leave the current colors

.Model  Medium,BASIC
.Data
    Extrn MonSeg:Word     ;these are in Monitor.Asm
    Extrn CGAPort:Word

.Code
Extrn Monitor:Proc

ClearEOL Proc Uses ES DI SI, Color:Ptr

    Cmp  MonSeg,0      ;has Monitor been used yet?
    Jnz  MonOkay       ;yes, skip ahead
    Call Monitor

MonOkay:
    Xor  AX,AX         ;look at screen buffer size in low memory
    Mov  ES,AX         ;through ES
    Mov  DI,ES:44Ch    ;this is a word stored at &H44C
    Mov  CL,4          ;divide by 16 since we'll be manipulating
    Shr  DI,CL         ;a segment

    Mov  AH,0Fh        ;get the video mode through BIOS
    Push BP            ;save BP during Int 10h stuff
    Int  10h           ;returns current page in BH, columns in AH
    Pop  BP
    Shl  AH,1          ;multiply times 2 to consider the attribute bytes
    Push AX            ;save it on the stack for a moment

    Mov  AH,3          ;specify BIOS service to read the cursor position
    Push BP
    Int  10h           ;enter with BH = page number, returns with
    Pop  BP            ;  row/column in DH/DL

    Mov  CH,BH         ;put the page number into CH
    Mov  BX,MonSeg     ;set BX to the appropriate screen segment
    Or   CH,CH         ;are we in fact writing to page zero?
    Jz   DonePage      ;yes, skip ahead

Inc_Page:
    Add  BX,DI         ;no, adjust segment to point to next page
    Dec  CH            ;are we on the right page now?
    Jnz  Inc_Page      ;no, increment the page

DonePage:
    Mov  AL,DH         ;put the current row number into AL
    Pop  CX            ;retrieve the column width (was AX when pushed)
    Mul  CH            ;multiply it times the screen width to get the
                       ;  base address of the current row

    Xor  DH,DH         ;clear DH for Add below, we only want DL
    Add  AX,DX         ;once for the character byte
    Add  AX,DX         ;and once for the attribute byte
    Mov  DI,AX         ;DI now holds starting memory position on the screen

    Mov  SI,Color      ;get the color that was passed
    Mov  AH,[SI]       ;put it into AH for direct screen writing below
    Mov  BP,DX         ;transfer the current column into BP

    Mov  DX,CGAPort    ;DL is a flag to indicate if CGA snow check is needed
    Mov  ES,BX         ;set ES to point to the appropriate screen segment

    Mov  CL,CH         ;the columns are in CH, but we need them in CL below
    Xor  CH,CH         ;now clear CH so we can use all of CX
    Shr  CL,1          ;we had multiplied times 2 earlier, put it back
    Sub  CX,BP         ;number of columns - current column = number of blanks

    Cld                ;screen writing below will be forward
    Mov  BL,32         ;put a blank space into BL
    Or   DL,DL         ;are we doing monochrome or EGA?
    Jz   Mono          ;yes, go do it
    Cmp  AH,0FFh       ;are we leaving the current colors on the screen?
    Jz   NCNo_Retrace  ;yes, go to the "NoColor" code

CNo_Retrace:
    In   AL,DX         ;get the video status byte
    Test AL,1          ;test just the horizontal retrace bit
    Jnz  CNo_Retrace   ;if doing a retrace, wait until it's not
    Cli                ;disable interrupts until we're done writing to screen

CRetrace:
    In   AL,DX         ;get the status byte again
    Test AL,1          ;are we currently doing a retrace?
    Jz   CRetrace      ;no wait until we are

    Mov  AL,BL         ;put the blank into AL
    Stosw              ;store the blank and attribute into screen memory
    Sti                ;re-enable interrupts
    Loop CNo_Retrace   ;until done
    Jmp  Short Exit    ;skip over and get out


NCNo_Retrace:
    In   AL,DX         ;get the video status byte
    Test AL,1          ;test just the horizontal retrace bit
    Jnz  NCNo_Retrace  ;if doing a retrace, wait until it's not
    Cli                ;disable interrupts until we're done writing to screen

NCRetrace:
    In   AL,DX         ;get the status byte again
    Test AL,1          ;are we currently doing a retrace?
    Jz   NCRetrace     ;no wait until we are

    Mov  AL,BL         ;put the blank into AL
    Stosb              ;store the blank in AL onto the screen
    Sti                ;re-enable interrupts
    Inc  DI            ;skip over the attribute byte
    Loop NCNo_Retrace  ;until done
    Jmp  Short Exit    ;skip over and get out

Mono:
    Cmp  AH,0FFh       ;leave the colors on the screen alone?
    Jz   NCMono        ;yes, skip ahead

CMono:
    Mov  AL,BL         ;put the blank into AL
    Stosw              ;store the blank and attribute into screen memory
    Loop CMono         ;until done CX times
    Jmp  Short Exit    ;bye bye

NCMono:
    Mov  AL,BL         ;put the blank into AL
    Stosb              ;store the blank and attribute on the screen
    Inc  DI            ;skip over the attribute and leave the color alone
    Loop NCMono        ;until done

Exit:
    Ret

ClearEol EndP
End
