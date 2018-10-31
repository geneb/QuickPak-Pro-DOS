; BOX0 - Copyright (c) 1989 by Chris May           (3/1/1989)
; BC7 version
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Subroutine to draw a Box on screen (writes to page zero) ³
;³                                                          ³
;³ Call Box0(ULRow%, ULCol%, LRRow%, LRCol%, Char%, Colr%)  ³
;³                                                          ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

ULRow EQU [BP+16]    ;upper left row
ULCol EQU [BP+14]    ;upper left column
LRRow EQU [BP+12]    ;lower right row
LRCol EQU [BP+10]    ;lower right column
Char  EQU [BP+08]    ;character to use
                     ;  1 = single line                            
                     ;  2 = double line                           
                     ;  3 = double horiz line, single vert         
                     ;  4 = double vert line, single horiz         
                     ;  or ASCII code of character to use          
Colr  EQU [BP+06]    ;box color, or -1 to use default

.MODEL medium
.DATA

   VLine           DB    ?    ;vertical line character
   HLine           DB    ?    ;horizontal line character
   TLC             DB    ?    ;top left corner character
   TRC             DB    ?    ;top right corner character
   BLC             DB    ?    ;bottom left corner character
   BRC             DB    ?    ;bottom right corner character
   Vert_Length     DW    ?    ; = LRRow - ULRow - 1
   Horiz_Length    DW    ?    ; = LRCol - ULCol - 1
   TLC_POS         DW    ?    ; = (ULRow - 1) * LineSize + ULCol + ULCol
   BLC_POS         DW    ?    ; = (LRRow - 1) * LineSize + ULCol + ULCol
   LineSize        DW    ?    ;length of a line in the current screen mode

   Extrn MonSeg:   Word       ;these are in Monitor.Asm
   Extrn CGAPort:  Word

.CODE

   Extrn Monitor:  Proc       ;so we can access monitor type
   Extrn StosbSub: Proc
   Extrn StoswSub: Proc

Public Box0
Box0 Proc Far

   Push   BP
   Mov    BP,SP
   Push   SI
   Push   DI
   Push   ES
   Cmp    MonSeg,0            ;has Monitor been used yet?
   Jnz    MonOkay             ;yes, skip ahead
   Call   Monitor             ;no, call it to set segment and retrace words

MonOkay:

   Mov    AH,0Fh              ;get the video mode through BIOS
   Push   BP                  ;some old PC BIOS's trash BP during an Int10h
   Int    10h                 ;returns current page in BH, columns in AH
   Pop    BP                  ;restore BP
   Mov    AL,AH               ;but we need the columns to be in AL
   Add    AL,AL               ;double the width for the calculations below
   Xor    AH,AH               ;make it a word
   Mov    LineSize,AX         ;and remember it for later

   Mov    CX,MonSeg
   Mov    ES,CX               ;destination address in ES

   Mov    SI,Char             ;get character to use
   Mov    AH,[SI]
   Cmp    AH,1                ;see if single line
   Jne    Double_Line         ;no, see if double line
   Mov    HLine,196           ;single line horizontal
   Mov    VLine,179           ;single line vertical
   Mov    TLC,218             ;top left corner
   Mov    TRC,191             ;top right corner
   Mov    BLC,192             ;bottom left corner
   Mov    BRC,217             ;bottom right corner
   Jmp    Calculate_Box

Double_Line:

   Cmp    AH,2                ;see if double line
   Jne    DHSV_Line           ;no, see if double horiz, single vert
   Mov    HLine,205           ;double line horizontal
   Mov    VLine,186           ;double line vertical
   Mov    TLC,201             ;top left corner
   Mov    TRC,187             ;top right corner
   Mov    BLC,200             ;bottom left corner
   Mov    BRC,188             ;bottom right corner
   Jmp    Short Calculate_Box

DHSV_Line:

   Cmp    AH,3                ;see if double horiz line, single vert
   Jne    DVSH_Line           ;no, see if double vertical single horiz
   Mov    HLine,205           ;double line horizontal
   Mov    VLine,179           ;single line vertical
   Mov    TLC,213             ;top left corner
   Mov    TRC,184             ;top right corner
   Mov    BLC,212             ;bottom left corner
   Mov    BRC,190             ;bottom right corner
   Jmp    Short Calculate_Box

DVSH_Line:

   Cmp    AH,4                ;see if double line
   Jne    Use_ASCII           ;no, use passed character
   Mov    HLine,196           ;single line horizontal
   Mov    VLine,186           ;double line vertical
   Mov    TLC,214             ;top left corner
   Mov    TRC,183             ;top right corner
   Mov    BLC,211             ;bottom left corner
   Mov    BRC,189             ;bottom right corner
   Jmp    Short Calculate_Box

Use_ASCII:

   Mov    HLine,AH            ;use ASCII value passed
   Mov    VLine,AH
   Mov    TLC,AH              ;upper left corner
   Mov    TRC,AH              ;upper right corner
   Mov    BLC,AH              ;bottom left corner
   Mov    BRC,AH              ;bottom right corner

Calculate_Box:

   Mov    SI,LRRow            ;point to lower right row
   Mov    AX,[SI]
   Dec    AX                  ;convert 1-25 into 0-24
   Mov    CX,AX               ;save for later determination of Vert_Length
   Mov    DX,LineSize         ;number of bytes per line
   Mul    DL                  ;convert row to offset
   Mov    BLC_POS,AX
   Mov    SI,ULRow            ;point to upper left row
   Mov    AX,[SI]
   Dec    AX                  ;convert 1-25 into 0-24
   Sub    CX,AX
   Dec    CX
   Mov    Vert_Length,CX      ;length of vertical line
   Mov    DX,LineSize         ;number of bytes per line
   Mul    DL                  ;convert row to offset
   Mov    TLC_POS,AX
   Mov    SI,LRCol            ;point to lower right column
   Mov    CX,[SI]
   Dec    CX                  ;convert 1-80 into 0-79
   Mov    SI,ULCol            ;point to upper left column
   Mov    BX,[SI]
   Sub    CX,BX
   Mov    Horiz_Length,CX     ;length of horizontal line
   Dec    BX                  ;convert 1-80 into 0-79
   Add    BX,BX
   Add    TLC_POS,BX
   Add    BLC_POS,BX

   Mov    SI,Colr             ;get color of box
   Mov    AH,[SI]             ;put in AH
   Mov    DI,TLC_POS          ;set to top left corner destination
   Mov    AL,TLC              ;load top left corner
   Cld                        ;operations in forward direction
   Call   Box0_Stosw          ;put it on screen

   Mov    AL,HLine            ;load horizontal line character
   Mov    CX,Horiz_Length     ;load length of line

Repeat1:

   Call   Box0_Stosw          ;put it on screen
   Loop   Repeat1             ;CX times

   Mov    AL,TRC              ;load top right corner
   Call   Box0_Stosw          ;put it on screen

   Mov    AL,VLine            ;load vertical line character
   Mov    DX,TLC_POS          ;set to top left destination again
   Mov    CX,Vert_Length      ;no. of rows to be done

Sides:

   Add    DX,LineSize         ;get next row
   Mov    DI,DX               ;load it
   Call   Box0_Stosw          ;put left side on screen
   Add    DI,Horiz_Length     ;once for character
   Add    DI,Horiz_Length     ;once for attribute
   Call   Box0_Stosw          ;put right side on screen
   Loop   Sides               ;do CX times

   Mov    AL,BLC              ;load bottom left corner
   Mov    DI,BLC_POS          ;load position of corner
   Call   Box0_Stosw          ;put it on screen

   Mov    AL,HLine            ;load horizontal line character
   Mov    CX,Horiz_Length     ;load length of line

Repeat2:

   Call   Box0_Stosw          ;put it on screen
   Loop   Repeat2             ;CX times

   Mov    AL,BRC              ;load top right corner
   Call   Box0_Stosw          ;put it on screen
   Pop    ES
   Pop    DI
   Pop    SI
   Pop    BP
   Ret    12

;----------------------------------------------------------------------------
Box0_Stosw Proc Near

   Push   DX                  ;save DX on stack
   Mov    DX,CGAPort          ;put port to check in DX
   Cmp    AH,0FFh             ;are we using the colors already on the screen?
   Jnz    DoColor             ;no, then do color

   Call   StosbSub            ;put byte on screen
   Inc    DI                  ;skip over the color byte
   Pop    DX                  ;restore contents of DX
   Ret

DoColor:

   Call   StoswSub            ;put word on screen
   Pop    DX
   Ret

Box0_Stosw EndP
;----------------------------------------------------------------------------
Box0 EndP
End
