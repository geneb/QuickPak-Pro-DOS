;********** EdHelp7.Asm - dedicated routine to process load text in QEdit7

;Copyright (c) 1988 Ethan Winer


;This routine stores the help screen for QEdit7 in the code segment to
;avoid taking string space from a BASIC program.  Besides storing the
;help messages, it also loads the text into a string array.  Understand
;this is NOT a general purpose routine to be added to your programs,
;though the technique is certainly useful in this type of situation.

;calling syntax - REDIM Help(34) AS STRING * 57
;       CALL LoadHelp7(BYVAL VARSEG(Help(1)), BYVAL VARPTR(Help(1)))


.Model Medium,BASIC
.Code

NumLines   Equ 34         ;the help text is fifteen lines
LineLength Equ 57         ;and each help line is 57 characters

LoadHelp7 Proc Uses DS ES SI DI, ArrayAdr:DWord

    Les  DI,ArrayAdr      ;point ES:DI to the Help() array
    Push CS               ;put CS into DS for Movsb below
    Pop  DS
    Mov  SI,Offset Help   ;now DS:SI points to the start of the help text
    Cld                   ;insure that the string moves below are forward
    Mov  CX,NumLines * LineLength    ;calculate how many characters to copy
    Rep  Movsb            ;copy the data from the code segment into Help()
    Ret                   ;return to BASIC

LoadHelp7 Endp


Help DB "ษอออออออออออออออออออออออต Help ฦออออออออออออออออออออออออป"
     DB "บ Home/End        - Move cursor to start/end of line    บ"
     DB "บ Ctrl-Home/End   - Move cursor to top/bottom of screen บ"
     DB "บ PgUp/PgDn       - Display previous/next page          บ"
     DB "บ Ctrl-PgUp/PgDn  - Display first/last page             บ"
     DB "บ Ctrl-Left/Right - Move cursor by whole words          บ"
     DB "บ Ctrl-Y          - Delete the current line             บ"
     DB "บ Ctrl-N          - Insert a new line above             บ"
     DB "บ Escape          - Exit edit window                    "
     DB "ศอออออออออออออต Press Escape to exit help ฦอออออออออออออผ"

     DB "บ                                                       บ"
     DB "บ Use the Shift-Cursor keys to begin a block operation. บ"
     DB "บ To mark a column use Shift-Right and then Shift-Down. บ"
     DB "บ Once a block has been marked, pressing Ctrl Ins will  บ"
     DB "บ capture it into the Paste buffer.  If Shift Delete is บ"
     DB "บ pressed, the block will be captured and then deleted. บ"
     DB "บ Use Shift-Ins to paste the block at a new location.   บ"
     DB "บ                                                       "

     DB "บ                                                       บ"
     DB "บ To mark a block with the mouse, simply position the   บ"
     DB "บ mouse cursor at the beginning of the block and press  บ"
     DB "บ the left button.  While the button is down the cursor บ"
     DB "บ may be moved in any direction.  If the mouse is first บ"
     DB 'บ moved up or down, marking is in "sentence" mode.  To  บ'
     DB "บ mark a block in column mode move left or right first. บ"
     DB "บ                                                       "

     DB "บ The text may be scrolled either by sliding the scroll บ"
     DB "บ bar diamonds at the bottom and right, or by pressing  บ"
     DB "บ on the arrow icons near the bottom right corner.  The บ"
     DB "บ window may be resized by pressing on the lower right  บ"
     DB "บ or top left corners, and then moving the mouse.  The  บ"
     DB "บ right margin may be changed by pressing on the right  บ"
     DB "บ margin icon at the top of the screen, and then moving บ"
     DB "บ it to the desired new position.                       "

End
