;********** Extents.Asm

;Extents finds the upper and lower active bounds of the screen

;Copyright (c) 1988 by Ethan Winer

;Syntax - CALL Extents(ULRow%, ULCol%, LRRow%, LRCol%)
;         IF ULRow% = 0 THEN     'the screen is completely blank


.Model Medium,BASIC
.Code

Extents Proc Uses ES SI DI, ULRow:Ptr, ULCol:Ptr, LRRow:Ptr, LRCol:Ptr

    Xor  AX,AX                    ;look at the monitor type in low memory
    Mov  ES,AX                    ;through ES
    Mov  BX,25                    ;assume 25 lines (save this in BX)
    Xor  DX,DX                    ;assume no CGA retrace needed
    Mov  CX,0B000h                ;assume a monochrome screen segment
    Cmp  Byte Ptr ES:[463h],0B4h  ;is it a monochrome screen?
    Jz   DoExtents                ;yes, don't bother to check for EGA/VGA

    Mov  AH,12h           ;ask for EGA info to see if it's an EGA or VGA
    Mov  BL,10h
    Push BP
    Int  10h
    Pop  BP
    Cmp  BL,10h           ;BL will still hold 10h if it's not an EGA
    Mov  BX,25            ;assume 25 lines
    Mov  DX,3DAh          ;assume CGA retrace checking
    Mov  CX,0B800h        ;we'll be using a color screen
    Jz   DoExtents        ;not an EGA, we're outa' here

    Mov  BL,ES:[484h]     ;this bytes tells all
    Inc  BL               ;adjust 24, 42, or 49 up to 25, 43, or 50
    Xor  DX,DX            ;no retrace checking needed

DoExtents:
    Mov  ES,CX            ;put the correct video segment into ES
    Mov  CX,1             ;initialize the upper left corner variables to 1
    Mov  SI,ULCol
    Mov  [SI],CX
    Mov  SI,ULRow         ;do ULRow% last because we need SI pointing to it
    Mov  Word Ptr [SI],CX
    Xor  DI,DI            ;start looking at upper left corner of the screen

Next_Row1:
    Mov  CX,80            ;use 80 characters per line

Row_Loop1:
    Call Read_Screen      ;see if the current character is a blank
    Jnz  Work_Back        ;it's not, now work from the bottom up
    Inc  DI               ;adjust DI to the next screen position
    Inc  DI               ;once more for the attribute byte
    Loop Row_Loop1        ;it is blank, keep checking
    Cmp  [SI],BX          ;did we hit the bottom yet?
    Je   Blank            ;yes, and there's nothing there!
    Inc  Word Ptr [SI]    ;show that we did another row
    Jmp  Short Next_Row1  ;and go do it all over again

Work_Back:
    Mov  SI,LRRow         ;get the address for LRRow%
    Mov  [SI],BX          ;assign LRRow% = BX (the current number of rows)
    Mov  AL,BL            ;put it into AL to multiply for the actual address

    Mov  CL,160           ;calculate the address of the last screen position
    Mul  CL               ;and now the answer is in AX
    Mov  DI,AX            ;but we need it in DI
    Dec  DI               ;point DI to the last char/attrib pair
    Dec  DI

Next_Row2:
    Mov  CX,80            ;use 80 characters per line

Row_Loop2:
    Call Read_Screen      ;see if the current character is a blank
    Jnz  Do_Left          ;it's not, now do the left column
    Dec  DI               ;adjust DI to the previous screen position
    Dec  DI               ;once more for the attribute byte
    Loop Row_Loop2        ;keep checking this row
    Dec  Word Ptr [SI]    ;show that we did another row
    Jmp  Short Next_Row2  ;and go do it

Do_Left:
    Mov  SI,ULCol         ;now work from left to right

Next_Col1:
    Mov  CX,BX            ;do BX rows
    Mov  DI,[SI]          ;find which column we need to do next
    Dec  DI               ;adjust 1-80 to 0-79
    Shl  DI,1             ;times 2 to skip over the attribute byte

Left_Loop:
    Call Read_Screen      ;see if the current character is blank
    Jnz  Do_Right         ;it's not, go on to the right edge
    Add  DI,160           ;consider the next row down
    Loop Left_Loop        ;keep checking this column
    Inc  Word Ptr [SI]    ;show that we did another column
    Jmp  Short Next_Col1  ;do the next column

Do_Right:
    Mov  SI,LRCol         ;now work from right to left
    Mov  Word Ptr [SI],80 ;initialize LRCol% to 80

Next_Col2:
    Mov  CX,BX            ;do BX rows
    Mov  DI,[SI]          ;find which column we need to do next
    Dec  DI               ;adjust 1-80 to 0-79
    Shl  DI,1             ;times 2 to skip the attribute byte

Right_Loop:
    Call Read_Screen      ;see if the current character is blank
    Jnz  Exit             ;it's not, we're all done
    Add  DI,160           ;consider the next row down
    Loop Right_Loop       ;keep checking this column
    Dec  Word Ptr [SI]    ;show that we did another column
    Jmp  Short Next_Col2  ;do the next column

Exit:
    Ret

Blank:
    Mov  Word Ptr [SI],0  ;the screen is completely blank, set ULRow% to 0
    Jmp  Short Exit       ;now exit


Read_Screen:

    Or   DX,DX            ;do we need to check CGA retrace?
    Jz   Read_It          ;no, skip over that code

Do_CGA:
    In   AL,DX            ;wait until not doing a horizontal retrace
    Test AL,1
    Jnz  Do_CGA
    Cli                   ;disable interrupts until we're finished

Do_CGA2:
    In   AL,DX            ;now wait until a retrace just begins
    Test AL,1             ;to avoid snow on a CGA screen
    Jz   Do_CGA2

Read_It:
    Cmp  Word Ptr ES:[DI],0720h  ;see if it's a blank
    Sti                   ;re-enable interrupts
    Retn                  ;let the caller decide what to do


Extents Endp
End
