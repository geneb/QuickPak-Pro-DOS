;********** ClearSc0.Asm - like ClearScr, but always clears page zero

;Copyright (c) 1988 Ethan Winer

;CALL ClearScr0(ULRow%, ULCol%, LRRow%, LRCol%, Colr%)
;      range:    1-25    1-80    1-25    1-80   0-255
;
;where Colr% is the color to clear to (-1 to leave current color)


.Model Medium,BASIC
.Data

    Wide DW ?          ;holds the screen width (40 or 80)
    Extrn MonSeg: Word ;these are in Monitor.Asm
    Extrn CGAPort:Word

.Code
Extrn Monitor: Proc    ;so we can access the monitor type

ClearScr0 Proc Uses SI DI ES DS, ULRow:Ptr, ULCol:Ptr, LRRow:Ptr, LRCol:Ptr, Colr:Ptr

    Cmp  MonSeg,0      ;has Monitor been used yet?
    Jnz  MonOkay       ;yes, skip ahead
    Call Monitor       ;no, call it to set the segment and retrace words

MonOkay:
    Mov  AH,0Fh        ;get the video mode through BIOS
    Push BP            ;some old PC BIOS's trash BP during an Int 10h
    Int  10h           ;returns current page in BH, columns in AH
    Pop  BP
    Shl  AH,1          ;double the width for the calculations below
    Mov  AL,AH         ;get the width into AX
    Xor  AH,AH
    Mov  Wide,AX       ;and save it internally
    Mov  BL,AL         ;we'll also need it in a moment in BL

    Mov  SI,ULRow      ;put address of ULRow% into SI
    Mov  AL,[SI]       ;put ULRow% into AL
    Dec  AL            ;adjust 1-25 to 0-24 for calculations below
    Mul  BL            ;now AX holds beginning address of upper row on screen

    Mov  SI,ULCol      ;put address of ULCol% into SI
    Mov  BX,[SI]       ;put ULCol% into BX
    Dec  BX            ;adjust for addition below
    Add  AX,BX         ;add column offset to AX for actual start address
    Add  AX,BX         ;once more to include the attribute bytes
    Mov  BX,AX         ;now BX holds the destination address

    Mov  SI,LRRow      ;put address of LRRow% into SI
    Mov  CH,[SI]       ;put LRRow% into CH
    Mov  SI,ULRow      ;get address for ULRow%
    Sub  CH,[SI]       ;subtract from CH to get the number of rows to process
    Inc  CH            ;add 1 because number of rows = (LRRow% - ULRow%) + 1

    Mov  SI,LRCol      ;put address of LRCol% into SI
    Mov  CL,[SI]       ;put LRCol% into CL
    Mov  SI,ULCol      ;get address for ULCol%
    Sub  CL,[SI]       ;subtract to get number of columns to do for each row
    Inc  CL            ;add 1 because columns = (LRCol% - ULCol%) + 1

    Mov  ES,MonSeg     ;set ES to point at screen memory
    Mov  DX,CGAPort

    Mov  SI,Colr       ;get address for Colr%
    Mov  AH,[SI]       ;put the color into AH
    Mov  BP,BX         ;BP will hold the beginning destination addresses
    Mov  BL,CL         ;save column counter in BL
    Cld                ;so all Stosb operations will be forward

Next_Row:
    Mov  CL,BL         ;retrieve column counter
    Mov  DI,BP         ;point Destination Index to screen

Next_Col:
    Cmp  AH,-1         ;are we honoring the default colors already there?
    Jz   No_Color      ;yes, skip over
    Or   DL,DL         ;are we doing a mono or EGA screen?
    Jz   Mono_EGA      ;yes, skip over retrace stuff

R1:
    In   AL,DX         ;wait until not doing a retrace
    Test AL,1
    Jnz  R1
    Cli                ;disable interrupts until we're finished
R2:
    In   AL,DX         ;wait until retrace has just begun
    Test AL,1
    Jz   R2

Mono_EGA:
    Mov  AL,32         ;load AL with a blank space
    Stosw              ;put the space and its color on the screen
    Sti                ;re-enable interrupts
    Jmp Short More     ;don't fall into the No_Color stuff

No_Color:
    Or   DL,DL         ;are we doing a mono or EGA screen?
    Jz   Mono_EGA2     ;yes, skip over

R3:
    In   AL,DX         ;wait until not doing a retrace
    Test AL,1
    Jnz  R3
    Cli                ;disable interrupts until we're finished
R4:
    In   AL,DX         ;wait until retrace has just begun
    Test AL,1
    Jz   R4

Mono_EGA2:
    Mov  AL,32         ;put a blank space into AL
    Stosb              ;clear the current screen character
    Sti                ;re-enable interrupts
    Inc  DI            ;skip over the attribute byte

More:
    Dec  CL            ;show that we just did another column
    Jnz  Next_Col      ;still more to do

    Add  BP,Wide       ;consider the next row down
    Dec  CH            ;show that we just did another row
    Jnz  Next_Row      ;still more
    Ret                ;return to BASIC

ClearScr0 Endp
End
