'********** QEDIT.BAS - this version is for QuickBASIC 4.0

'Copyright (c) 1988-1990 Crescent Software
'by Don Malin


DEFINT A-Z

'$INCLUDE: 'QEDITYPE.BI'

TYPE BlkCoords                                  'Type for Block coordinates
    B AS INTEGER                                'Block coordinates
    PB AS INTEGER                               'Previous block coordinates
    P AS INTEGER                                'Paint coordinates
    PP AS INTEGER                               'Previous paint coordinates
END TYPE


'----- assembler calls
DECLARE SUB APrint0 (BYVAL X, NumEls, StartChar, NumChars, Colr)
DECLARE SUB APrintT0 (BYVAL Segment, BYVAL Address, StrLen, NumEls, FirstChar, NumChars, Clr)
DECLARE SUB ButtonPress (Button, Status, Count, X, Y)
DECLARE SUB DeleteStr (BYVAL Address, NumEls)
DECLARE SUB Get1Str (Work$, SEG Element, StrNumber)
DECLARE SUB GetCursor (X, Y, Button)
DECLARE SUB GetVMode (Mode, Page, PageSize, Rows, Columns)
DECLARE SUB HideCursor ()
DECLARE SUB InsertStr (BYVAL Address, Inserted$, NumEls)
DECLARE SUB LoadHelp (BYVAL Segment, BYVAL Address)
DECLARE SUB MidStrSave (BYVAL Address, NumEls, FirstChar, NumChars, SEG Storage)
DECLARE SUB MidStrRest (Buffer$, StrNumber, SEG Storage)
DECLARE SUB MouseTrap (UlRow, UlCol, LrRow, LrCol)
DECLARE SUB MPaintBox (UlRow, UlCol, LrRow, LrCol, Colr)
DECLARE SUB MPRestore (UlRow, UlCol, LrRow, LrCol, OrigWidth, SEG ArrayEl)
DECLARE SUB MQPrint (X$, Colr)
DECLARE SUB MScrnSave (UlRow, UlCol, BRRow, BRCol, SEG Address)
DECLARE SUB MScrnRest (UlRow, UlCol, BRRow, BRCol, SEG Address)
DECLARE SUB Pause (Eighteenth)
DECLARE SUB QPrintRC (X$, Row, Col, Clr)
DECLARE SUB ScrollD (UlRow, UlCol, BRRow, BRCol, Rows, Page)
DECLARE SUB ScrollL (UlRow, UlCol, BRRow, BRCol, Cols, Page)
DECLARE SUB ScrollR (UlRow, UlCol, BRRow, BRCol, Cols, Page)
DECLARE SUB ScrollU (UlRow, UlCol, BRRow, BRCol, Rows, Page)
DECLARE SUB ShowCursor ()
DECLARE SUB SplitColor (AColor, Fg, Bg)
DECLARE SUB StringSave (BYVAL Address, SEG Element, NumEls)


'----- ASM Functions
DECLARE FUNCTION ArraySize% (UlRow, UlCol, BRRow, BRCol)
DECLARE FUNCTION ASCII% (Ky$)
DECLARE FUNCTION Blanks% (Text$)
DECLARE FUNCTION DOSVer% ()
DECLARE FUNCTION FindLast% (BYVAL Address, Size)
DECLARE FUNCTION MaxInt% (Num1, Num2)
DECLARE FUNCTION MinInt% (Num1, Num2)
DECLARE FUNCTION Monitor% ()
DECLARE FUNCTION Null% (Text$)
DECLARE FUNCTION PeekBuf% ()
DECLARE FUNCTION QInstrB% (Start, Text$, Search$)
DECLARE FUNCTION QPLen% (Text$)
DECLARE FUNCTION ShiftKey% ()
DECLARE FUNCTION StringSize& (BYVAL Address, NumEls)
DECLARE FUNCTION StrLength% (SEG Element, NumBytes AS ANY, StrNumber)

CONST NumPad$ = "12346789"                      'Shifted arrow keys
CONST NumPad2$ = "stOPQKMGHK"                   'Unshifted arrow keys
CONST SkipTbl$ = " ^*()[]-=+,.<>/\"             'Word delimiters


'----- Returns the number of columns to advance at the end of a line
DEF FnSpaces2Pad% (Text$)
    STATIC Temp
    SELECT CASE ASCII%(RIGHT$(Text$, 1))
       CASE 46, 33, 63          '".", "!", "?"
          Temp = 2
       CASE 32, -1              'Space
          Temp = 0
       CASE ELSE
          Temp = 1
    END SELECT
    FnSpaces2Pad% = Temp
END DEF

'****************************************************************************
'  Title: QEdit - Full featured text editing sub-program
'     by: Don Malin  10/21/88
'
'Purpose: Displays a word processing window and allows the user to edit text.
'         Horizontal and vertical scrolling can be used to edit a string
'         array passed to the routine.  Margins and word wrap are supported
'         along with full block operations and mouse support.
'
' Syntax: CALL QEdit(Arg1$(), Arg2$, Arg3%, Arg4 as EditInfo)
'
' Inputs: Arg1$(1) - Text array to be edited.  Must be a conventional
'                    (not fixed-length) string array.
'         Arg2$    - Last Key pressed
'         Arg3%    - Action flag  (0 = Take full control, return only on Esc
'                                 (1 = Init window, save underlying screen)
'                                 (2 = Re-display but don't save window)
'                                 (3 = Just check keyboard and return
'                                 (5 = Restore underlying screen)
'         Arg4     - Structure defined in QEdit.Bas MAIN and the Caller's
'                    MAIN (see $INCLUDE file - QEditype.BI)
'
'  Notes: It is up to you to determine the probable amount of string space
'         required for your text array.
'
'         If you don't want to support block operations, the code used to
'         perform them is contained in a single block which can be deleted.
'         Search for "Block Operations".  The same is true for mouse handling
'         code.  Search for "Mouse Handling".
'****************************************************************************
'
SUB QEdit (Array$(), X$, Action%, Ed AS EditInfo) STATIC

    Ed.MErr = 0                         'No errors yet
    Zero$ = CHR$(0)                     'invoke CHR$() only once
    One$ = CHR$(1)

    DIM Bl(3) AS BlkCoords

    '----- Action of 0 or 1 - Save the underlying screen
    IF Action < 2 THEN
       WrapWas = Ed.Wrap
       Ed.HTab = MaxInt%(Ed.HTab, 1)            'Horizontal Tab spaces
       TMarg = 1
       BMarg = 1
       Insrt = Ed.InsStat
       IF Insrt = 0 THEN Insrt = -1             'Insert mode set to ON
                                                'make 1 to default to OT
       CtrlP = 32

       CurLine$ = SPACE$(4)                     'Used to display Cursor Pos.
       CurCol$ = SPACE$(3)

       MouseKey$ = Zero$ + CHR$(3)              'Dummy key for mouse actions
       MouseKey2$ = Zero$ + CHR$(4)
      
       '----- Compose the Ruler line string
       REDIM Ruler(0 TO 1) AS STRING * 260      'Put it out in far memory

       FOR N = 0 TO 250 STEP 10                 'Compose Ruler line
           MID$(Ruler(0), N + 1) = MID$(STR$(N MOD 100), 2, 1)
           FOR X = 1 TO 9
               IF X = 5 THEN
                  MID$(Ruler(0), N + X + 1) = "Å"
               ELSE
                  MID$(Ruler(0), N + X + 1) = "Â"
               END IF
           NEXT
       NEXT

    
       MouseThere = 0                           'Assume Mouse code absent
       BlocksThere = 0                          'Assume Block code absent


       '----- Determine bottom cursor scan line.
       SELECT CASE Monitor%                     'Determine the monitor type
          CASE 3, 5, 10                         'CGA, EGA monitors
             BScan = 7                          'Set bottom scan line
          CASE ELSE                             'All other monitors
             BScan = 12
       END SELECT
       LOCATE , , 0, BScan - 1, BScan

       NPixLines = 8
       CALL GetVMode(0, 0, 0, ScrRows, 80)      'Get current line mode
                                                'Fix for OS2 DOS
       IF ScrRows = 50 AND DOSVer% = 1000 THEN NPixLines = 7

       Ed.TSRow = CSRLIN - (Ed.Frame <> 0)      'Calc the top line of window
       Ed.LSCol = POS(0) - (Ed.Frame <> 0)      'Calc Left margin of window
                                                'Both are to inside of frame
       Ed.Rows = MinInt%(MaxInt%(Ed.Rows, 3), (ScrRows + ((Ed.Frame <> 0) * 2)) - CSRLIN + 1)
       Ed.Wide = MinInt%(MaxInt%(Ed.Wide, 11), (80 + ((Ed.Frame <> 0) * 2)) - POS(0) + 1)

       '----- Save current window coordinates for later resizing
       DIM WC(3, 1)
       WC(0, 1) = Ed.TSRow + (Ed.Frame <> 0)    'Top line
       WC(1, 1) = Ed.LSCol + (Ed.Frame <> 0)    'Left margin
       WC(2, 1) = WC(0, 1) + Ed.Rows + (2 * (Ed.Frame <> 0)) - 1'Bottom line of window
       WC(3, 1) = WC(1, 1) + Ed.Wide + (2 * (Ed.Frame <> 0)) - 1'Right margin of window
      
       '----- Dim array to hold the underlying screen and save it.
       REDIM ScrBuf(1 TO (ScrRows * 80) + 2)
       CALL MScrnSave(1, 1, ScrRows, 80, ScrBuf(1))
      
       IF Ed.LC <= 0 THEN Ed.LC = 1             'Set window column to 1
       IF Ed.CurCol <= 0 THEN Ed.CurCol = 1     'establish cursor column at 1
       IF Ed.TL <= 0 THEN Ed.TL = 1             'Top of window row number
       IF Ed.CurLine <= 0 THEN Ed.CurLine = 1   'make top line the cursor col.
       GOSUB WindowLimits

    END IF

    '----- Action of 5 - Restore the underlying screen
    IF Action = 5 THEN
       GOSUB CleanUp                            'Restore the screen
       Action = 1                               'Reset action to 1
       EXIT SUB                                 'Bail out
    END IF
   
    '----- Action of 0, 1, 2 - Display the edit window
    IF Action < 3 OR Action = 4 THEN

       '----- Find the last element being used in the text array
       ArrayEnd = UBOUND(Array$)
       Ed.LCount = FindLast%(VARPTR(Array$(ArrayEnd)), ArrayEnd)


       IF Ed.Wrap THEN     'If word wrap is on, use "" paragraph marker
          Par$ = CHR$(20)  '(you could use CHR$(255) for invisible marker)
          Ed.Wrap = MaxInt%(MinInt%(Ed.Wrap, 255), 10)
       ELSE                'Otherwise,
          Par$ = ""        '  use a null character
       END IF
  
       '----- If word wrap is on, format all the text.
       IF Ed.Wrap THEN
          WrapLine = 1
          IF Action < 3 THEN
             WrapLine = 1
             GOSUB WrapAll
          ELSE
             WrapLine = Ed.CurLine
             
             GOSUB WrapUp
             GOSUB WrapDown
          END IF
          WrapWas = Ed.Wrap
       END IF
      
                          
       '----- Insert margin markers in ruler line.
       Ruler(1) = Ruler(0)
       IF Ed.Wrap THEN
          MID$(Ruler(1), 2) = CHR$(16)
          MID$(Ruler(1), Ed.Wrap + 1) = CHR$(17)
       END IF

       HiClr = Ed.AColor                        'Determine high intensity Clr
       CALL SplitColor(Ed.AColor, X, Temp)      'Split color # into Fg & Bg
       IF X < 8 THEN HiClr = Ed.AColor + 8
       IF Ed.AColor = 112 THEN
          BlkClr = 7
       ELSE
          BlkClr = 112
       END IF

       GOSUB InitWindow                         'Display the window
       GOSUB CsrSize                            'Set the cursor size
      
    END IF

    

    '----- Main editing (key processing) loop
    DO

        '----- Position the cursor
        LOCATE Ed.TSRow + Ed.CurLine - Ed.TL, Ed.LSCol + (Ed.CurCol - Ed.LC), 1
       
        Ed.UnKnownKey = 0
        LineWas = Ed.CurLine

        '----- Handle regular keys
        IF QPLen%(X$) = 1 THEN
    
           SELECT CASE ASCII%(X$)

              '----- All Non Control Characters
              CASE IS >= CtrlP

                 X = QPLen%(Array$(Ed.CurLine)) 'See if line is long enough
                 IF X < 256 AND Ed.CurCol < 256 THEN
                    IF Ed.CurLine < ArrayEnd OR Ed.Wrap = 0 OR X < Ed.Wrap THEN
                       IF Ed.CurCol > X THEN    'Make space for new character
                          Array$(Ed.CurLine) = Array$(Ed.CurLine) + SPACE$(Ed.CurCol - X)
                       END IF
                                                'Update line count if past
                       Ed.LCount = MaxInt%(Ed.LCount, Ed.CurLine) ' end
                                                'Insert character in line
                       IF Insrt = -1 AND Ed.CurCol <= X THEN
                          Array$(Ed.CurLine) = LEFT$(Array$(Ed.CurLine), Ed.CurCol - 1) + X$ + MID$(Array$(Ed.CurLine), Ed.CurCol)
                          CALL MQPrint(MID$(Array$(Ed.CurLine), Ed.CurCol, Ed.Wide - (Ed.CurCol - Ed.LC)), Ed.AColor)
                          IF Ed.Wrap THEN
                             WrapLine = Ed.CurLine
                             GOSUB WrapDown
                          END IF
                       ELSE                     'Concat character to end
                          MID$(Array$(Ed.CurLine), Ed.CurCol, 1) = X$
                          CALL MQPrint(X$, Ed.AColor)  'Print the character
                          IF Ed.Wrap AND Ed.CurCol > Ed.Wrap THEN
                             WrapLine = Ed.CurLine
                             GOSUB WrapDown
                          END IF
                       END IF

                       Ed.CurCol = Ed.CurCol + 1'Update the current column
                       GOSUB WindowLimits
                       Ed.Changed = -1          'We just changed the text
                       LineEd = -1
                    END IF
                 END IF

                 CtrlP = 32


              '----- Back Space
              CASE 8
                 IF Ed.CurCol > 1 THEN          'If not at column 1,
                    Ed.CurCol = Ed.CurCol - 1   '  decrement the cursor posit.
                    IF Insrt = -1 THEN          'If in Insert mode, drag the
                                                '  line 1 char. left
                       Array$(Ed.CurLine) = LEFT$(Array$(Ed.CurLine), Ed.CurCol - 1) + MID$(Array$(Ed.CurLine), Ed.CurCol + 1)
                       IF LEN(Array$(Ed.CurLine)) THEN Ed.Changed = -1
                       IF Ed.Wrap THEN
                          WrapLine = Ed.CurLine
                          GOSUB WrapUp          'Wrap words up
                       END IF
                                                'Not in Insert mode, blank char
                    ELSEIF Ed.CurCol = QPLen%(Array$(Ed.CurLine)) THEN
                       Array$(Ed.CurLine) = LEFT$(Array$(Ed.CurLine), Ed.CurCol - 1)
                       Ed.Changed = -1
                    ELSEIF Ed.CurCol < QPLen%(Array$(Ed.CurLine)) THEN
                       MID$(Array$(Ed.CurLine), Ed.CurCol, 1) = " "
                       Ed.Changed = -1
                       LineEd = -1
                    END IF                      'Put edited line in a buffer
                    IF Ed.CurCol < Ed.LC THEN  'If we're at left window col,
                       Ed.LC = Ed.LC - 1        '  decrement window column
                       RePrint = -1
                    ELSE
                       LSET LineBuf$ = MID$(Array$(Ed.CurLine), Ed.LC)
                       LOCATE , Ed.LSCol, 0        'Print the edited line
                       CALL MQPrint(LineBuf$, Ed.AColor)
                    END IF
                                                'If in Insert mode, go up
                 ELSEIF Ed.CurLine > 1 THEN
                                                
                    Temp = FnSpaces2Pad%(Array$(Ed.CurLine - 1))
                                                'Copy line to line above
                    Ed.CurCol = QPLen%(Array$(Ed.CurLine - 1)) + Temp + 1
                    Array$(Ed.CurLine - 1) = Array$(Ed.CurLine - 1) + SPACE$(Temp) + Array$(Ed.CurLine)
                                                'Update window column
                    Ed.LC = MaxInt%(Ed.CurCol - Ed.Wide + 1, Ed.LC)

                    Temp = Ed.CurLine           'Delete the current line
                    GOSUB DeleteLine
                   
                    Ed.CurLine = Ed.CurLine - 1
                    GOSUB CursorUp              'Back up a line
                    RePrint = -1                'Set flag to re-print window
                    IF Ed.Wrap THEN
                       WrapLine = Ed.CurLine
                       GOSUB WrapDown           'Wrap words down
                    END IF
                    Ed.Changed = -1
                 END IF
                  
              '----- Enter
              CASE 13
                 IF Ed.CurLine < ArrayEnd THEN

                    X = Blanks%(Array$(Ed.CurLine)) + 1
                                                'If in Insert mode, insert a
                    IF Insrt = -1 THEN
                                                '  new line below.
                       IF Ed.LCount < ArrayEnd THEN
                                                'New line is right of cursor
                          Temp$ = SPACE$(MinInt%(X, Ed.CurCol) - 1) + RTRIM$(MID$(Array$(Ed.CurLine), Ed.CurCol))
                          Temp = Ed.CurLine + 1
                          GOSUB InsertLine
                                                'Current line is left of
                                                '  cursor & paragraph marker
                          Array$(Ed.CurLine) = RTRIM$(LEFT$(Array$(Ed.CurLine), Ed.CurCol - 1))
                          Ed.Changed = -1
                       END IF
                    END IF
                     
                    IF X > 1 OR QPLen%(Array$(Ed.CurLine)) THEN Ed.CurCol = X
                    Ed.CurLine = MinInt%(Ed.CurLine + 1, ArrayEnd)
                    GOSUB WindowLimits

                    RePrint = -1                'Set flag to re-print window
                 END IF

              '----- TAB
              CASE 9
                                                'Make current column "Ed.HTab"
                                                '  to the right
                 N = ((Ed.CurCol + Ed.HTab - 1) \ Ed.HTab) * Ed.HTab + 1
                 N = MinInt%(N, 255 - Ed.HTab)
                 IF N <= Ed.Wrap OR Ed.Wrap = 0 THEN
                                                'If in Insert mode
                    IF Insrt = -1 AND Ed.CurCol < QPLen%(Array$(Ed.CurLine)) THEN
                                                '  insert "Ed.HTab" spaces
                       Array$(Ed.CurLine) = LEFT$(Array$(Ed.CurLine), Ed.CurCol - 1) + SPACE$(N - Ed.CurCol) + MID$(Array$(Ed.CurLine), Ed.CurCol)
                       IF Ed.Wrap THEN
                          WrapLine = Ed.CurLine
                          GOSUB WrapDown        'Wrap words down
                       END IF
                       Ed.Changed = -1
                    END IF
                                               
                    Ed.CurCol = N
                                                'Is it off the right of window?
                    IF Ed.CurCol > Ed.LC + Ed.Wide - 1 THEN
                       Ed.LC = Ed.LC + Ed.HTab  'Make it "Ed.HTab" to the right
                       RePrint = -1             'Set flag to re-print window
                    ELSE                        'Move to the left margin
                       LOCATE , Ed.LSCol, 0
                                                'Put new line in buffer
                       LSET LineBuf$ = MID$(Array$(Ed.CurLine), Ed.LC)
                                                'Print the buffer
                       CALL MQPrint(LineBuf$, Ed.AColor)
                    END IF
                 END IF

              '----- Escape
              CASE 27
                 IF Action = 0 THEN             'If not using Action flag,
                    GOSUB CleanUp               '  restore the screen and
                                                'Clean up memory
                    EXIT DO                     'see ya later oscillator
                 ELSE
                    Ed.UnKnownKey = -1
                 END IF
                 

              '----- Ctrl Y - Delete a Line
              CASE 25
                 IF Ed.CurLine <= Ed.LCount THEN 'Disallow if we're past the last line
                                                'Calc the screen line number
                    X = Ed.TSRow + Ed.CurLine - Ed.TL
                                                'Paint the line before we delete it
                                                '  just for effect
                    CALL MPaintBox(X, Ed.LSCol, X, Ed.LSCol + Ed.Wide - 1, BlkClr)

                    Temp = Ed.CurLine           'Delete the current line
                    GOSUB DeleteLine

                    Pause 1                     'Wait an 1/18 of a second
                    RePrint = -1                'Set flag to re-print window
                    IF Ed.LCount THEN Ed.Changed = -1
                 END IF
                
            
              '----- Ctrl N - Insert a Line
              CASE 14
                 Temp = Ed.CurLine
                 Temp$ = ""
                 GOSUB InsertLine
                 RePrint = -1                   'Set flag to re-print window
                 IF Ed.LCount THEN Ed.Changed = -1


              '----- Ctrl P - Imbed characters
              CASE 16
                 CtrlP = 0
                 LineEd = -1

              CASE ELSE
                 Ed.UnKnownKey = -1

           END SELECT

           
           X& = FRE("")
           IF X& < 1280 THEN
              BEEP
              Ed.MErr = 1                       'Set error flag
           END IF


        '----- Handle Extended (2 Char) key codes
        ELSEIF QPLen%(X$) = 2 THEN

           SELECT CASE ASCII%(RIGHT$(X$, 1))    'Get ASCII value of right 1

              '----- HELP key pressed
              CASE 59
                                                'Make array for underlying Scr
                 REDIM HelpScr(ArraySize%(2, 80 - 57 - 1, 12, 80))
                                                'Save underlying screen
                 CALL MScrnSave(2, 80 - 57 - 1, 12, 80, HelpScr(1))

                 REDIM Help(35) AS STRING * 57
                                                'Load array with Help text
                 CALL LoadHelp(VARSEG(Help(1)), VARPTR(Help(1)))

                 LOCATE 2, 80 - 57 - 1, 0       'Locate the cursor
                                               
                 CALL HideCursor                'Print the help screen
                 CALL APrintT0(VARSEG(Help(1)), VARPTR(Help(1)), 57, 10, 1, 57, 112)
                 CALL ShowCursor
                                                'Paint Shadows
                 CALL MPaintBox(3, 79, 11, 80, 8)
                 CALL MPaintBox(12, 80 - 57 + 1, 12, 80, 8)
                 LOCATE 10, 78
                 IF NOT MouseThere AND NOT BlocksThere THEN
                    CALL MQPrint("º", 79)
                 ELSE
                    CALL MQPrint(CHR$(18), 240)
                 END IF

                 LOCATE 3, 80 - 57 - 1          'Locate the cursor
                 I = 2
                 DO                             'Wait for a key press
                    Temp = PeekBuf%
                    SELECT CASE Temp            'Get key but don't remove it
                       CASE -72, -73            'Up arrow or PgUp
                          SELECT CASE I         'Set pointer based on last one
                             CASE 27
                                IF BlocksThere THEN
                                   I = 19
                                ELSE
                                   I = 2
                                END IF
                             CASE 19
                                I = 11
                             CASE 11
                                I = 2
                             CASE 2
                                IF MouseThere THEN
                                   I = 27
                                ELSEIF BlocksThere THEN
                                   I = 11
                                END IF
                          END SELECT
                       CASE -80, -81            'Down arrow or PgDn
                          SELECT CASE I         'Set pointer based on last one
                             CASE 2
                                IF BlocksThere THEN
                                   I = 11
                                ELSEIF MouseThere THEN
                                   I = 27
                                END IF
                             CASE 11
                                IF MouseThere THEN
                                   I = 19
                                ELSE
                                   I = 2
                                END IF
                             CASE 19
                                I = 27
                             CASE 27
                                I = 2
                          END SELECT

                       CASE 27                  'Escape key
                          Temp$ = INKEY$        'Take key out of buffer
                          EXIT DO               'Bail out
                       CASE 0
                       CASE ELSE                'Bail out if any other key
                          EXIT DO
                    END SELECT

                    IF Temp THEN
                       Temp$ = INKEY$           'Now extract key from buffer
                       CALL HideCursor          'Display new page of help
                       CALL APrintT0(VARSEG(Help(I)), VARPTR(Help(I)), 57, 8, 1, 56, 112)
                       CALL ShowCursor
                    END IF
                                                'Bail out if mouse button pressed
                    CALL ButtonPress(1, 0, Ed.Presses, X, Y)
                 LOOP UNTIL Ed.Presses
                                                'Restore the screen
                 CALL MScrnRest(2, 80 - 57 - 1, 12, 80, HelpScr(1))
                 ERASE HelpScr, Help            'Clean up memory
                                           

              '----- Cursor UP
              CASE 72
                 IF PeekBuf% = -72 THEN
                    Ed.CurLine = Ed.CurLine - 2
                    X$ = INKEY$
                 ELSE
                    Ed.CurLine = Ed.CurLine - 1
                 END IF
                 GOSUB CursorUp                 'Go do it

              '----- Cursor DOWN
              CASE 80
                 IF PeekBuf% = -80 THEN
                    Ed.CurLine = Ed.CurLine + 2
                    X$ = INKEY$
                 ELSE
                    Ed.CurLine = Ed.CurLine + 1
                 END IF
                 GOSUB CursorDown               'Go do it

              '----- Cursor LEFT
              CASE 75
                 IF Ed.CurCol > 1 THEN
                    IF PeekBuf% = -75 THEN
                       Ed.CurCol = Ed.CurCol - 2
                       X$ = INKEY$
                    ELSE
                       Ed.CurCol = Ed.CurCol - 1
                    END IF
                    GOSUB CursorLeft
                                                'Are we in word wrap mode?
                 ELSEIF Ed.Wrap AND Ed.CurLine > 1 THEN
                    Ed.CurCol = Ed.Wrap         'Set column to right margin
                    Ed.LC = MaxInt%(Ed.Wrap - Ed.Wide + 1, 1)
                    Ed.CurLine = Ed.CurLine - 1
                    GOSUB CursorUp              'Let "CursorUp" handle it
                    RePrint = -1
                    ColBlock = 0
                 END IF

              '----- Cursor RIGHT
              CASE 77
                 IF Ed.CurCol < 256 THEN
                    IF PeekBuf% = -77 THEN
                       Ed.CurCol = Ed.CurCol + 2
                       X$ = INKEY$
                    ELSE
                       Ed.CurCol = Ed.CurCol + 1
                    END IF
                    GOSUB CursorRight
                                                'If at right margin
                    IF Ed.Wrap AND Ed.CurCol > Ed.Wrap THEN
                       Ed.CurCol = 1            'Set current column to 1
                       Ed.LC = 1                'Set window column to 1
                       Ed.CurLine = Ed.CurLine + 1
                       GOSUB CursorDown         'Let "CursorDown" move down
                                                '  a line
                       RePrint = -1
                       ColBlock = 0
                    END IF
                 END IF

              '----- Ctrl LEFT - move one word left
              CASE 115
                 DO
                    IF Ed.CurCol = 1 AND Ed.CurLine > 1 THEN
                       Ed.CurLine = Ed.CurLine - 1
                       Ed.CurCol = MaxInt%(QPLen%(Array$(Ed.CurLine)), 1)
                       ColBlock = 0
                    END IF
                      
                    X = -1
                    DO WHILE Ed.CurCol > 1
                       Ed.CurCol = Ed.CurCol - 1
                       IF X THEN
                          IF INSTR(SkipTbl$, MID$(Array$(Ed.CurLine), Ed.CurCol, 1)) = 0 THEN X = 0
                       ELSE
                          IF INSTR(SkipTbl$, MID$(Array$(Ed.CurLine), Ed.CurCol, 1)) THEN
                             Ed.CurCol = Ed.CurCol + 1
                             EXIT DO
                          END IF
                       END IF
                    LOOP
                 LOOP WHILE Ed.CurLine > 1 AND INSTR(SkipTbl$, MID$(Array$(Ed.CurLine), Ed.CurCol, 1))
                
                 GOSUB WindowLimits             'If off left of window, adjust

              '----- Ctrl RIGHT - move one word right
              CASE 116
                 DO
                    X = -1
                    DO WHILE Ed.CurCol <= QPLen%(Array$(Ed.CurLine))
                       Ed.CurCol = Ed.CurCol + 1 'Increment column position
                       IF X THEN
                          IF INSTR(SkipTbl$, MID$(Array$(Ed.CurLine), Ed.CurCol, 1)) THEN X = 0
                       ELSE
                          IF INSTR(SkipTbl$, MID$(Array$(Ed.CurLine), Ed.CurCol, 1)) = 0 THEN EXIT DO
                       END IF
                    LOOP
                                                'If past end of line,
                    IF Ed.CurCol > QPLen%(Array$(Ed.CurLine)) AND Ed.CurLine < Ed.LCount THEN
                       Ed.CurCol = 1            '  Set current column to 1
                       Ed.CurLine = Ed.CurLine + 1 'Increment line number
                       ColBlock = 0
                    ELSE
                       EXIT DO
                    END IF
                 LOOP WHILE INSTR(SkipTbl$, MID$(Array$(Ed.CurLine), Ed.CurCol, 1))
                                                'If off right of window, adjust
                 GOSUB WindowLimits

              '----- Cursor HOME
              CASE 71                           'Starting at column 1
                 X = Blanks%(Array$(Ed.CurLine)) + 1

                 IF X = Ed.CurCol THEN X = 1
                 Ed.CurCol = X

                 GOSUB WindowLimits
                                 

              '----- Cursor END
              CASE 79                           'Set current column to end +
                 Ed.CurCol = QPLen%(Array$(Ed.CurLine)) + FnSpaces2Pad%(Array$(Ed.CurLine)) + 1

                 GOSUB WindowLimits

              '----- Ctrl HOME
              CASE 119                          'Make current line top of screen
                 Ed.CurLine = Ed.CurLine - (CSRLIN - Ed.TSRow)

              '----- Ctrl END
              CASE 117                          'Make bottom current line
                 Ed.CurLine = Ed.CurLine + ((Ed.TSRow + Ed.Rows - 1) - CSRLIN)

              '----- PgUp
              CASE 73
                 IF Ed.TL > 1 THEN              'ignore if already at the top
                    X = Ed.TL                   'save Ed.TL for a moment
                    Ed.TL = MaxInt%(1, Ed.TL - Ed.Rows)
                    X = X - Ed.TL               'calc dif. between new and old
                    Ed.CurLine = Ed.CurLine - X 'don't move cursor unless we have to
                    RePrint = -1                'Set flag to re-print window
                 END IF

              '----- PgDn
              CASE 81                           'almost at end, work backwards
                 IF Ed.TL > ArrayEnd - Ed.Rows * 2 THEN
                    X = Ed.CurLine - Ed.TL      '  from end of array
                    Ed.TL = ArrayEnd - Ed.Rows + 1
                    Ed.CurLine = Ed.TL + X      'Calc new current line
                    RePrint = -1                'Set flag to re-print window
                 ELSE
                    Ed.TL = Ed.TL + Ed.Rows     'calc top line of next page
                    Ed.CurLine = Ed.CurLine + Ed.Rows 'update current line
                    RePrint = -1                'Set flag to re-print window
                 END IF

              '----- Ctrl PgUp
              CASE 132
                 Ed.CurCol = 1                  'Make column 1 current
                 Ed.CurLine = 1                 'ditto for the current line
                 Ed.TL = 1                      'Set current top of screen
                 Ed.LC = 1                      'Set current left of screen
                 RePrint = -1                   'Set flag to re-print window

              '----- Ctrl PgDn
              CASE 118                          'we're already there - ignore
                 IF Ed.TL <= ArrayEnd - Ed.Rows THEN
                    IF Ed.LCount > 0 THEN       'empty file - go to the top
                                                'Cursor past the end, but see
                       IF Ed.CurLine > Ed.LCount THEN '  exactly where we are
                          X = Ed.CurLine - Ed.LCount
                                                'Last line showing on screen
                          IF X < Ed.Rows AND Ed.TL <= Ed.LCount THEN
                                                '  make that the current line
                             Ed.CurLine = Ed.LCount
                             LOCATE CSRLIN - X  '  and put the cursor there
                          END IF                '  too
                       END IF

                       Ed.CurLine = Ed.LCount   'Make the last line current
                       X = Ed.CurLine - Ed.TL   'See where cursor is relative
                                                '  to end
                                                'Last line is on the screen,
                       IF X <= 0 OR X >= Ed.Rows THEN
                                                '  don't re-display, just move
                                                'establish top line to display
                          Ed.TL = Ed.CurLine - (Ed.Rows - 1)
                                                'Can't have negative line #
                          Ed.TL = MaxInt%(Ed.TL, 1)
                          RePrint = -1          'Set flag to re-print window
                       END IF
                                                'Locate at end of line
                       Ed.CurCol = QPLen%(Array$(Ed.CurLine)) + 1
                       IF Ed.CurCol < Ed.LC THEN
                          Ed.LC = MaxInt%(1, Ed.CurCol - Ed.Wide + 1)
                          RePrint = -1
                       ELSEIF Ed.CurCol > Ed.LC + Ed.Wide - 1 THEN
                          Ed.LC = Ed.CurCol - Ed.Wide + 1
                          RePrint = -1
                       END IF

                    END IF
                 END IF

              '----- Togle INSERT mode
              CASE 82
                 Insrt = Insrt * -1             'toggle insert on and off
                 GOSUB CsrSize                  'set cursor size accordingly

              '----- Delete
              CASE 83
                 IF Ed.CurCol > QPLen%(Array$(Ed.CurLine)) THEN
                    Array$(Ed.CurLine) = Array$(Ed.CurLine) + SPACE$(Ed.CurCol - QPLen%(Array$(Ed.CurLine)) - 1)

                    'if not on last line concatenate the next line to this one
                    IF Ed.CurLine < ArrayEnd THEN Array$(Ed.CurLine) = Array$(Ed.CurLine) + LTRIM$(Array$(Ed.CurLine + 1))

                    Temp = Ed.CurLine + 1
                    GOSUB DeleteLine

                    RePrint = -1                'Set flag to re-print window
                    IF Ed.Wrap THEN
                       WrapLine = Ed.CurLine
                       GOSUB WrapDown           'Wrap words down
                    END IF
                 ELSE                           'Within line, delete current
                                                '  character
                    Array$(Ed.CurLine) = LEFT$(Array$(Ed.CurLine), Ed.CurCol - 1) + MID$(Array$(Ed.CurLine), Ed.CurCol + 1)
                                                'Put new text in line buffer
                    LSET LineBuf$ = MID$(Array$(Ed.CurLine), Ed.LC)
                    LOCATE , Ed.LSCol, 0        'Print the line buffer
                    CALL MQPrint(LineBuf$, -1)
                 END IF
                 IF Ed.Wrap THEN
                    WrapLine = Ed.CurLine
                    GOSUB WrapUp                'Wrap words up
                 END IF
                 Ed.Changed = -1
                 LineEd = -1

                  
              '----- Back TAB
              CASE 15                           'Calc spaces to next stop
                 X = (((Ed.CurCol - Ed.HTab - 2) \ Ed.HTab) + 1) * Ed.HTab + 1
                 X = MaxInt%(X, 1)
                                                'If in Insert mode and not at
                                                '  end of line,
                 IF Insrt = -1 AND Ed.CurCol <= QPLen%(Array$(Ed.CurLine)) THEN
                                                'drag line to the left
                    Array$(Ed.CurLine) = LEFT$(Array$(Ed.CurLine), X - 1) + MID$(Array$(Ed.CurLine), Ed.CurCol)
                    IF Ed.Wrap THEN
                       WrapLine = Ed.CurLine
                       GOSUB WrapUp             'Wrap words up
                    END IF
                    Ed.Changed = -1
                 END IF

                 Ed.CurCol = X                  'Adjust current column posit.

                 IF Ed.CurCol < Ed.LC THEN      'If off left of window,
                    Ed.LC = Ed.CurCol           '  adjust current window col
                    RePrint = -1                'Set flag to re-print window
                 ELSE                           'Otherwise,
                    LOCATE , Ed.LSCol, 0 'locate at left margin
                                                'Put new text in line buffer
                    LSET LineBuf$ = MID$(Array$(Ed.CurLine), Ed.LC)
                    CALL MQPrint(LineBuf$, Ed.AColor)  'Print the line buffer
                 END IF
               
              CASE ELSE                         'Ignor all other keys
                 Ed.UnKnownKey = -1

           END SELECT

        END IF

       
        IF LineEd AND Ed.CurLine <> LineWas THEN
           Array$(LineWas) = RTRIM$(Array$(LineWas))
           LineEd = 0
        END IF


        '----- Re-display the window if flag set or block marking complete
        IF RePrint OR (Ed.WasMarked AND MarkBlock = 0) THEN
           LOCATE Ed.TSRow, Ed.LSCol, 0         'APrint the screen
           CALL HideCursor                      'Turn Mouse cursor off
           CALL APrint0(VARPTR(Array$(Ed.TL)), Ed.Rows, Ed.LC, Ed.Wide, Ed.AColor)
           CALL ShowCursor                      'Turn mouse cursor back on
           RePrint = 0                          'Turn Flag off
           IF MarkBlock = 0 THEN Ed.WasMarked = 0  'Turn hiliting off
        END IF
     

        '----- If we have a window frame
        IF Ed.Frame THEN
                                                'If line number has changed,
           IF Ed.CurLine <> LastCurLine OR RePrint THEN
              GOSUB DisplayLineNumber           '  display line # on status
              LastCurLine = Ed.CurLine          'Save line number
           END IF
                                                'If column number has changed,
           IF Ed.CurCol <> LastCurCol OR RePrint THEN
              GOSUB DisplayColNumber            '  display col. # on status
              LastCurCol = Ed.CurCol            'Save column number
           END IF

           IF Ed.LC <> LastC THEN               'If window column has changed,
              LOCATE Ed.TSRow - 1, Ed.LSCol, 0
              CALL MQPrint(MID$(Ruler(1), Ed.LC + 1, Ed.Wide), 112)
              LastC = Ed.LC                     'Save window column
           END IF
        END IF

       
        '----- Position the cursor
        LOCATE Ed.TSRow + Ed.CurLine - Ed.TL, Ed.LSCol + (Ed.CurCol - Ed.LC), 1
        '
        'IF Action = 1 OR Action = 2 OR Action = 4 THEN
        '   X$ = ""
        '   Action = 3
        '   EXIT DO
        'END IF
        '
        '----- Wait for a key press
        'DO
        '    X$ = INKEY$
        'LOOP UNTIL QPLen%(X$)
        '********************************************************************
        '* Block Operations code starts here.  If you don't want to use
        '* block operations, un-remark the lines above and delete the
        '* code from here to the remark - "End of Block Operations".
        '********************************************************************
        BlocksThere = -1

        '----- If in block marking mode, paint the marked block
        IF MarkBlock AND QPLen%(X$) THEN

           '----- If block marking key was just pressed
           IF FrstBlkKey THEN
              ColBlock = 0                      'Init flag to sentence mode
                                                'If still on same line, reset
                                                '  mode for column block
              IF Ed.CurLine = BlkRow THEN ColBlock = -1
              FrstBlkKey = 0                    'Reset first key flag
              Bl(0).PB = 60                     'Init history variables
              Bl(1).PB = 80
              Bl(2).PB = 0
              Bl(3).PB = 0
           END IF

           Bl(0).B = MinInt%(Ed.CurLine, BlkRow) 'Set top of block
           Bl(2).B = MaxInt%(Ed.CurLine, BlkRow) 'Set bottom of block
             
           '----- If in COLUMN BLOCK mode,
           IF ColBlock THEN
              '----- Set left and right columns
              Bl(1).B = MinInt%(Ed.CurCol, BlkCol)
              Bl(3).B = MaxInt%(Ed.CurCol - 1, BlkCol)
              '----- Set coordinates to paint
              Bl(0).P = MaxInt%(Bl(0).B, Ed.TL) - Ed.TL + Ed.TSRow
              Bl(1).P = MaxInt%(Bl(1).B, Ed.LC) - Ed.LC + Ed.LSCol
              Bl(2).P = MinInt%(Bl(2).B, Ed.TL + Ed.Rows - 1) - Ed.TL + Ed.TSRow
              Bl(3).P = MaxInt%(MinInt%(Bl(3).B, Ed.LC + Ed.Wide - 1) - Ed.LC + Ed.LSCol, Ed.LSCol)
              '----- Get previous paint coordinates
              Bl(0).PP = MaxInt%(Bl(0).PB, Ed.TL) - Ed.TL + Ed.TSRow
              Bl(1).PP = MaxInt%(Bl(1).PB, Ed.LC) - Ed.LC + Ed.LSCol
              Bl(2).PP = MinInt%(Bl(2).PB, Ed.TL + Ed.Rows - 1) - Ed.TL + Ed.TSRow
              Bl(3).PP = MinInt%(Bl(3).PB, Ed.LC + Ed.Wide - 1) - Ed.LC + Ed.LSCol
              '----- Un-paint old part of block
              IF Bl(3).PB >= Ed.LC AND Bl(2).PB >= Ed.TL THEN
                 IF Bl(0).PB < Bl(0).B THEN MPaintBox Bl(0).PP, MinInt%(Bl(1).PP, Bl(1).P), Bl(0).P - 1, MaxInt%(Bl(3).PP, Bl(3).P), Ed.AColor
                 IF Bl(2).PB > Bl(2).B THEN MPaintBox Bl(2).P + 1, MinInt%(Bl(1).PP, Bl(1).P), Bl(2).PP, MaxInt%(Bl(3).PP, Bl(3).P), Ed.AColor
                 IF Bl(1).PB < Bl(1).B THEN MPaintBox MinInt%(Bl(0).P, Bl(0).PP), Bl(1).PP, MaxInt%(Bl(2).P, Bl(2).PP), Bl(1).P, Ed.AColor
                 IF Bl(3).PB > Bl(3).B THEN MPaintBox MinInt%(Bl(0).P, Bl(0).PP), Bl(3).P, MaxInt%(Bl(2).P, Bl(2).PP), Bl(3).PP, Ed.AColor
              END IF
              '----- Paint the block
              IF Bl(3).B >= Ed.LC AND Bl(2).B >= Ed.TL THEN
              CALL MPaintBox(Bl(0).P, Bl(1).P, Bl(2).P, Bl(3).P, BlkClr)
              END IF

           '----- If in SENTENCE BLOCK mode
           ELSE
              '----- Set left and right columns
              IF Bl(0).B < BlkRow THEN
                 Bl(1).B = Ed.CurCol
                 Bl(3).B = BlkCol
              ELSE
                 Bl(1).B = BlkCol
                 Bl(3).B = Ed.CurCol - 1
              END IF
              '----- Set coordinates to paint
              Bl(0).P = MaxInt%(Bl(0).B, Ed.TL) - Ed.TL + Ed.TSRow
              Bl(1).P = MaxInt%(Bl(1).B, Ed.LC) - Ed.LC + Ed.LSCol
              Bl(2).P = MinInt%(Bl(2).B - Ed.TL + Ed.TSRow, Ed.TSRow + Ed.Rows - 1)
              Bl(3).P = MaxInt%(Ed.LSCol, MinInt%(Bl(3).B, Ed.LC + Ed.Wide - 1) - Ed.LC + Ed.LSCol)
              '----- Get previous paint coordinates
              Bl(0).PP = MaxInt%(Bl(0).PB, Ed.TL) - Ed.TL + Ed.TSRow
              Bl(1).PP = MaxInt%(Bl(1).PB, Ed.LC) - Ed.LC + Ed.LSCol
              Bl(2).PP = MinInt%(Bl(2).PB - Ed.TL + Ed.TSRow, Ed.TSRow + Ed.Rows - 1)
              Bl(3).PP = MaxInt%(Ed.LSCol, MinInt%(Bl(3).PB, Ed.LC + Ed.Wide - 1) - Ed.LC + Ed.LSCol)
              '----- Un-paint old part of block
              IF Bl(2).B < Bl(2).PB THEN MPaintBox Bl(2).P, Ed.LSCol, Bl(2).PP, Ed.LSCol + Ed.Wide - 1, Ed.AColor
              IF Bl(0).B > Bl(0).PB THEN MPaintBox Bl(0).PP, Ed.LSCol, Bl(0).P, Ed.LSCol + Ed.Wide - 1, Ed.AColor
              '----- Paint the new block
              IF Ed.CurLine <> BlkRow THEN              'If more than one line
                 '----- Paint top line if on screen
                 IF Bl(0).B >= Ed.TL THEN
                    IF Bl(1).B >= Bl(1).PB THEN MPaintBox Bl(0).P, Ed.LSCol, Bl(0).P, MaxInt%(Bl(1).P - 1, Ed.LSCol), Ed.AColor
                    CALL MPaintBox(Bl(0).P, Bl(1).P, Bl(0).P, Ed.LSCol + Ed.Wide - 1, BlkClr)
                 END IF
                 '----- Paint middle lines if on screen
                 FOR N = Bl(0).B + 1 TO Bl(2).B - 1
                     IF N >= Ed.TL AND N < Ed.TL + Ed.Rows THEN
                        Bl(0).P = N - Ed.TL + Ed.TSRow
                        CALL MPaintBox(Bl(0).P, Ed.LSCol, Bl(0).P, Ed.LSCol + Ed.Wide - 1, BlkClr)
                     END IF
                 NEXT
                 '----- Paint bottom line if on screen
                 IF Bl(2).B < Ed.TL + Ed.Rows THEN
                    IF Bl(3).B <= Bl(3).PB THEN MPaintBox Bl(2).P, Bl(3).P, Bl(2).P, Ed.LSCol + Ed.Wide - 1, Ed.AColor
                    IF Bl(3).B >= Ed.LC THEN MPaintBox Bl(2).P, Ed.LSCol, Bl(2).P, Bl(3).P, BlkClr
                 END IF
              ELSE                                      'Only one line
                 CALL MPaintBox(Bl(2).P, Ed.LSCol, Bl(2).P, Ed.LSCol + Ed.Wide - 1, Ed.AColor)
                 LPCol = MaxInt%(MinInt%(BlkCol, Ed.CurCol), Ed.LC) - Ed.LC + Ed.LSCol
                 RPCol = MaxInt%(MinInt%(MaxInt%(BlkCol, Ed.CurCol - 1), Ed.LC + Ed.Wide - 1) - Ed.LC + Ed.LSCol, Ed.LSCol)
                 CALL MPaintBox(Bl(2).P, LPCol, Bl(2).P, RPCol, BlkClr)
              END IF
           END IF
           '----- Save bottom corner coordinates
           Bl(0).PB = Bl(0).B
           Bl(1).PB = Bl(1).B
           Bl(2).PB = Bl(2).B
           Bl(3).PB = Bl(3).B
        END IF
      

        '----- If just displaying the window, bail out
        IF Action = 1 OR Action = 2 OR Action = 4 THEN
           X$ = ""
           Action = 3                           'Reset Action code to 3 (idle)
           EXIT DO
        END IF


        '----- Check for a key press or mouse action
        DO
           X$ = INKEY$                          'Get key press


           'MMMMMMMMMMMMMMMM Start of Mouse Handling Code MMMMMMMMMMMMMMMMMMM
           'MM   If you hate rodents, exterminate the code from here to    MM
           'MM   the next set of "MMM" comments.                           MM
           'MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
           '----- Get Mouse Coords. and Botton Info.
           MouseThere = -1                      'Mouse code is here

                                                'Check for button presses
           CALL ButtonPress(1, Temp, Ed.Presses, X, Y)
          
           '----- If User pressed a button
           IF Ed.Presses OR Temp THEN
              IF Ed.Presses = 0 THEN GetCursor X, Y, Temp
              Ed.MRow = (Y \ NPixLines) + 1     'Convert X, Y to Row and Col.
              Ed.MCol = (X \ 8) + 1

              '----- If Button just pressed
              IF Ed.Presses THEN
                 WasPressed = -1                'Set flag for "let go" proc.
                 Delay! = 0

                 '----- Are we within the ROW limit of the TEXT?
                 IF Ed.MRow >= Ed.TSRow AND Ed.MRow < Ed.TSRow + Ed.Rows THEN

                    '----- Are we within the COLUMN limit of the TEXT?
                    IF Ed.MCol >= Ed.LSCol AND Ed.MCol < Ed.LSCol + Ed.Wide THEN
                       MouseAct = 1             'Flag for TEXT operations
                                                'Limit mouse movement to window
                       CALL MouseTrap(Ed.TSRow + (Ed.Frame <> 0), Ed.LSCol + (Ed.Frame <> 0), Ed.TSRow + Ed.Rows + (Ed.Frame = 0), Ed.LSCol + Ed.Wide + (Ed.Frame = 0))
                                                'Set the cursor row and column
                       Ed.CurLine = Ed.MRow - Ed.TSRow + Ed.TL ' to the mouse location
                       Ed.CurCol = Ed.MCol - Ed.LSCol + Ed.LC

                       X$ = MouseKey$           'Set dummy key so we fall out
                                                '  of key loop
                       IF NOT MarkBlock THEN    'If it's a new block
                          BlkRow = Ed.CurLine   'Save upper left coordinates
                          BlkCol = Ed.CurCol
                          SaveT = Ed.TL         'Save window coordinates
                          SaveC = Ed.LC
                       ELSE
                          X$ = MouseKey2$
                       END IF
                       Ed.Presses = 0           'Clear presses
                 
                    '----- Are we on the VERTICAL scroll bar?
                    ELSEIF Ed.MCol = Ed.LSCol + Ed.Wide AND Ed.Frame THEN
                                                'On a Scroll Arrow?
                       IF Ed.MRow = Ed.TSRow OR Ed.MRow = Ed.TSRow + Ed.Rows - 1 THEN
                                                'Limit mouse movement to the
                                                '  Scroll Arrow
                          CALL MouseTrap(Ed.MRow, Ed.MCol, Ed.MRow, Ed.MCol)
                          MouseAct = 7
                         
                       '----- Are we on the scroll pointer?
                       ELSEIF Ed.MRow = OldVrtPtr + Ed.TSRow + 1 AND Ed.LCount > Ed.Rows THEN
                          MouseAct = 2          'Flag for vertical scroll pointer
                                                'Limit mouse to scroll bar
                          CALL MouseTrap(Ed.TSRow + 1, Ed.LSCol + Ed.Wide, Ed.TSRow + Ed.Rows - 2, Ed.LSCol + Ed.Wide)
                       END IF
                       Ed.Presses = 0           'Clear the press

                    ELSEIF Ed.MCol = Ed.LSCol - 1 AND Ed.Frame THEN
                       MouseAct = 8             'On left hand border, move window
                       CALL MouseTrap(Ed.MRow - Ed.TSRow + 2 + TMarg, 1, Ed.MRow + ScrRows - (Ed.TSRow + Ed.Rows) - BMarg, 79 - Ed.Wide)
                       Ed.Presses = 0              'Clear the press
                    END IF
                                                
                 '----- Are we on the HORIZONTAL scroll bar
                 ELSEIF Ed.MRow = Ed.TSRow + Ed.Rows AND Ed.Frame THEN
                    IF Ed.MCol >= Ed.LSCol - 1 AND Ed.MCol <= Ed.LSCol + Ed.Wide THEN
                                                'Where on the line?
                       SELECT CASE Ed.MCol
                          '----- On a scroll arrow?
                          CASE Ed.LSCol + 8, Ed.LSCol + Ed.Wide - 1
                                                'Limit mouse movement to the
                                                '  Scroll Arrow
                             CALL MouseTrap(Ed.MRow, Ed.MCol, Ed.MRow, Ed.MCol)
                            
                             MouseAct = 7
                          '----- On the scroll pointer?
                          CASE Ed.LSCol + 9 + OldHorPtr
                                                'Set flag for horizontal
                             MouseAct = 3       '   scroll pointer
                                                'Limit mouse to scroll bar
                             CALL MouseTrap(Ed.TSRow + Ed.Rows, Ed.LSCol + 9, Ed.TSRow + Ed.Rows, Ed.LSCol + Ed.Wide - 2)
                          '----- On Right Corner of Frame?
                          CASE Ed.LSCol + Ed.Wide
                             MouseAct = 4       'Flag for lower right corner
                                                'Limit movement to screen
                                                '  margins
                             CALL MouseTrap(TMarg + 1, 1, ScrRows - BMarg, 80)

                          CASE ELSE
                       END SELECT
                       Ed.Presses = 0           'Clear the mouse press
                    END IF

                 '----- Are we on the TOP line of the Frame
                 ELSEIF Ed.MRow = Ed.TSRow - 1 AND Ed.Frame THEN
                    IF Ed.MCol >= Ed.LSCol - 1 AND Ed.MCol <= Ed.LSCol + Ed.Wide THEN
                                                'On the TOP LEFT corner?
                       IF Ed.MCol = Ed.LSCol - 1 THEN
                          CALL MouseTrap(TMarg + 1, 1, ScrRows - BMarg, 80)
                          MouseAct = 5          'Flag for upper left corner

                       '----- Are we on the RIGHT MARGIN marker?
                       ELSEIF Ed.MCol = Ed.LSCol + Ed.Wrap - Ed.LC AND Ed.Wrap >= Ed.LC AND Ed.Wrap < Ed.LC + Ed.Wide THEN
                          MouseAct = 6          'Flag for margin marker
                                                'Limit mouse to ruler line
                          CALL MouseTrap(Ed.TSRow - 1, Ed.LSCol, Ed.TSRow - 1, Ed.LSCol + Ed.Wide - 1)

                       ELSEIF Ed.MCol < Ed.LSCol + Ed.Wide THEN
                          MouseAct = 8          'move window
                          CALL MouseTrap(TMarg + 1, Ed.MCol - Ed.LSCol + 2, Ed.MRow + ScrRows - (Ed.TSRow + Ed.Rows) - BMarg, Ed.MCol + (80 - Ed.Wide - Ed.LSCol))

                       ELSE
                          MouseAct = 9
                       END IF
                       Ed.Presses = 0           'Clear the mouse press
                    END IF
                 END IF

              '----- Button is DOWN but not just pressed
              ELSE
                 '----- DRAG actions
                 SELECT CASE MouseAct

                    '----- BLOCK marking operations
                    CASE 1
                       '----- Has the mouse been moved?
                       IF Ed.MRow <> LMRow OR Ed.MCol <> LMCol THEN
                          IF NOT MarkBlock THEN 'Beginning of block?
                             
                             FrstBlkKey = -1    'Set first key flag
                             MarkBlock = -1     'Set block marking flags
                             Ed.WasMarked = -1
                          END IF
                                                'Set cursors new location
                          Ed.CurLine = MinInt%(Ed.TL + Ed.Rows - 1, MaxInt%(Ed.TL, Ed.MRow - Ed.TSRow + Ed.TL))
                          Ed.CurCol = MinInt%(Ed.LC + Ed.Wide - 1, MaxInt%(Ed.LC, Ed.MCol - Ed.LSCol + Ed.LC))
                          X$ = MouseKey$        'Make dummy key so we fall out
                       END IF

                       '----- On TOP of frame?  Scroll UP
                       IF Ed.MRow = Ed.TSRow - 1 THEN
                                                'Check timer
                          IF TIMER > LMTime! + .05 OR TIMER < LMTime! THEN
                             Ed.CurLine = Ed.TL - 1'Set cursor to top of window
                             GOSUB CursorUp     'Move cursor up and scroll
                             X$ = MouseKey$     'Make dummy key
                             LMTime! = TIMER    'Reset timer for delay
                          END IF
                       END IF

                       '----- On BOTTOM of frame?  Scroll DOWN
                       IF Ed.MRow = Ed.TSRow + Ed.Rows THEN
                                                'Check timer
                          IF TIMER > LMTime! + .05 OR TIMER < LMTime! THEN
                             Ed.CurLine = Ed.TL + Ed.Rows
                             GOSUB CursorDown   'Move cursor down and scroll
                             X$ = MouseKey$     'Make dummy key
                             LMTime! = TIMER    'Reset timer
                          END IF
                       END IF

                       '----- On RIGHT side of frame?  Scroll right
                       IF Ed.MCol = Ed.LSCol + Ed.Wide THEN
                                                'Check timer
                          IF TIMER > LMTime! + .05 OR TIMER < LMTime! THEN
                             Ed.CurCol = Ed.LC + Ed.Wide
                             GOSUB CursorRight
                             X$ = MouseKey$     'Make dummy key
                             LMTime! = TIMER    'Reset timer
                          END IF
                       END IF

                       '----- On LEFT side of frame?  Scroll left
                       IF Ed.MCol = Ed.LSCol - 1 THEN
                                                'Cursor to left of window
                                                'Check timer
                          IF TIMER > LMTime! + .05 OR TIMER < LMTime! THEN
                             Ed.CurCol = Ed.LC - 1      'Decrement current column
                             GOSUB CursorLeft
                             X$ = MouseKey$     'Make dummy key
                             LMTime! = TIMER    'Reset timer
                          END IF
                       END IF

                    '----- Vertical Scroll Pointer operations
                    CASE 2
                       IF Ed.MRow <> LMRow THEN         'If the mouse moved
                                                        'Calc. % of bar
                                                        'Set line to %
                          Ed.CurLine = INT(((Ed.MRow - Ed.TSRow - 1&) * Ed.LCount) \ (Ed.Rows - 3)) + 1
                          Ed.CurLine = MinInt%(Ed.CurLine, Ed.LCount)
                          IF Ed.MRow > LMRow THEN       'Set top of window
                             Ed.TL = MaxInt%(MinInt%(MaxInt%(Ed.TL, Ed.CurLine), Ed.LCount - Ed.Rows + 2), 1)
                          ELSE
                             Ed.TL = MaxInt%(MinInt%(Ed.TL, Ed.CurLine - Ed.Rows + 1), 1)
                          END IF
                          X$ = MouseKey$                'Make dummy key
                          RePrint = -1                  'Set flag to reprint
                       END IF                           '  window
                      
                    '----- Horizontal Scroll Pointer operations
                    CASE 3
                       IF Ed.MCol <> LMCol THEN         'If the mouse moved
                          IF Ed.Wrap THEN               'If word wrap is on,
                             X = Ed.Wrap + 1            '  use right margin
                          ELSE                          '  as text width
                             X = 256                    '  otherwise use 256
                          END IF
                                                        'Set column to %
                          Ed.CurCol = INT(((Ed.MCol - Ed.LSCol - 9) * X) \ (Ed.Wide - 10)) + 1
                          IF Ed.MCol > LMCol THEN       'Set left column
                             Ed.LC = MaxInt%(MinInt%(MaxInt%(Ed.LC, Ed.CurCol), X - Ed.Wide), 1)
                          ELSE
                             Ed.LC = MaxInt%(MinInt%(Ed.LC, Ed.CurCol - Ed.Wide + 1), 1)
                          END IF
                          X$ = MouseKey$                'Make dummy key
                          RePrint = -1                  'Set flag to reprint
                       END IF                           '  window

                    '----- Lower Right Corner operations (ReSize window)
                    CASE 4                      'If the mouse has moved
                       IF Ed.MRow <> LMRow OR Ed.MCol <> LMCol THEN
                                                'Calc new location and size
                          Ed.Wide = MaxInt%(Ed.MCol - Ed.LSCol, 11)
                          Ed.LSCol = MaxInt%(Ed.MCol - Ed.Wide, 2)

                          Ed.Rows = MaxInt%(Ed.MRow - Ed.TSRow, 3)
                          Ed.TSRow = MaxInt%(Ed.MRow - Ed.Rows, TMarg + 2)
                                                
                          GOSUB InitWindow      'Let subroutine redraw window
                          X$ = MouseKey$        'Make dummy key
                       END IF
                      
                    '----- Upper Left Corner operations (ReSize window)
                    CASE 5                      'If the mouse has moved
                       IF Ed.MRow <> LMRow OR Ed.MCol <> LMCol THEN
                                                'Calc new location and size
                          WC(3, 0) = Ed.LSCol + Ed.Wide
                          WC(2, 0) = Ed.TSRow + Ed.Rows
                         
                          Ed.LSCol = MinInt%(Ed.MCol + 1, 80 - 11)
                          Ed.Wide = MaxInt%(WC(3, 0) - Ed.LSCol, 11)
                          
                          Ed.TSRow = MinInt%(Ed.MRow + 1, ScrRows - BMarg - 3)
                          Ed.Rows = MaxInt%(WC(2, 0) - Ed.TSRow, 3)

                          GOSUB InitWindow      'Let subroutine redraw window
                          X$ = MouseKey$        'Make dummy key
                       END IF

                    '----- Left boarder operation (Move window)
                    CASE 8                      'If the mouse has moved
                       IF Ed.MRow <> LMRow OR Ed.MCol <> LMCol THEN
                                                'Calc new location and size
                          Ed.LSCol = Ed.LSCol + Ed.MCol - LMCol
                          Ed.TSRow = Ed.TSRow + Ed.MRow - LMRow

                          GOSUB InitWindow      'Let subroutine redraw window
                          X$ = MouseKey$        'Make dummy key
                       END IF

                    '----- Zoom
                    CASE 9
                       Ed.LSCol = 2
                       Ed.Wide = 78
                         
                       Ed.TSRow = TMarg + 2
                       Ed.Rows = ScrRows - BMarg - Ed.TSRow
                             
                       GOSUB InitWindow      'Let subroutine redraw window
                       X$ = MouseKey$        'Make dummy key

                    '----- Move right margin operations
                    CASE 6
                       IF Ed.MCol <> LMCol THEN 'If the mouse has moved
                          Ruler(1) = Ruler(0)   'Reset the ruler$ to erase
                                                '  the old marker
                          MID$(Ruler(1), 2) = CHR$(16)
                                                'Calc the new right margin
                          Ed.Wrap = MaxInt%(Ed.MCol - Ed.LSCol + Ed.LC, 10)
                                                'Put margin icon in Ruler$
                          MID$(Ruler(1), Ed.Wrap + 1) = CHR$(17)
                          LOCATE Ed.TSRow - 1, Ed.LSCol, 0         '  re-display ruler line
                          CALL MQPrint(MID$(Ruler(1), Ed.LC + 1, Ed.Wide), 112) 'part to print
                         
                          WrapLine = 1          'Start wrapping at line 1
                          GOSUB WrapAll         'Go wrap all text
                          Ed.CurCol = MinInt%(Ed.CurCol, Ed.Wrap)

                          X$ = MouseKey$        'Make dummy key
                          RePrint = -1          'Set flag to redisplay text
                                                'Set "Changed" flag
                          IF Ed.LCount THEN Ed.Changed = -1
                       END IF

                    '----- Scroll bar operations (except scroll pointer)
                    CASE ELSE

                       '----- Wait for delay
                       IF (TIMER > LMTime! + Delay! OR TIMER < LMTime!) AND Ed.Frame THEN
                          IF MouseAct = 7 THEN
                             Delay! = .3
                             MouseAct = 0
                          ELSE
                             Delay! = .05
                          END IF
                          LMTime! = TIMER

                          '----- Vertical scroll bar operations
                          IF Ed.MCol = Ed.LSCol + Ed.Wide AND Ed.MRow >= Ed.TSRow AND Ed.MRow < Ed.TSRow + Ed.Rows THEN
                             ScrVrtPtr = VrtPtr + Ed.TSRow + 1
                             SELECT CASE Ed.MRow
                                       
                                '----- On Up Arrow icon
                                CASE IS = Ed.TSRow
                                   IF Ed.TL > 1 THEN
                                      Ed.TL = Ed.TL - 1
                                      Ed.CurLine = MinInt%(Ed.CurLine, Ed.TL + Ed.Rows - 1)
                                      X$ = MouseKey$
                                      RePrint = -1
                                   END IF
 
                                '----- On Down Arrow icon
                                CASE IS = Ed.TSRow + Ed.Rows - 1
                                   IF Ed.TL < ArrayEnd - Ed.Rows + 1 THEN
                                      Ed.TL = Ed.TL + 1
                                      Ed.CurLine = MaxInt%(Ed.CurLine, Ed.TL)
                                      X$ = MouseKey$
                                      RePrint = -1
                                   END IF

                                '----- Above Pointer
                                CASE IS < ScrVrtPtr
                                   X$ = Zero$ + CHR$(73)

                                '----- Below Pointer
                                CASE IS > ScrVrtPtr
                                   X$ = Zero$ + CHR$(81)

                                CASE ELSE
                             END SELECT
                          END IF

                          '----- Horizontal scroll bar operations
                          IF Ed.MRow = Ed.TSRow + Ed.Rows AND Ed.MCol >= Ed.LSCol AND Ed.MCol < Ed.LSCol + Ed.Wide THEN
                             ScrHorPtr = Ed.LSCol + 9 + HorPtr
                             SELECT CASE Ed.MCol

                                '----- On Left Arrow icon
                                CASE IS = Ed.LSCol + 8
                                   IF Ed.LC > 1 THEN
                                      Ed.LC = Ed.LC - 1
                                      Ed.CurCol = MinInt%(Ed.CurCol, Ed.LC + Ed.Wide - 1)
                                      X$ = MouseKey$
                                      RePrint = -1
                                   END IF

                                '----- On Right Arrow icon
                                CASE IS = Ed.LSCol + Ed.Wide - 1
                                   IF Ed.LC < 255 - Ed.Wide + 1 THEN
                                      Ed.LC = Ed.LC + 1
                                      Ed.CurCol = MaxInt%(Ed.CurCol, Ed.LC)
                                      X$ = MouseKey$
                                      RePrint = -1
                                   END IF
                              
                                '----- Left of Pointer
                                CASE IS < ScrHorPtr
                                   MTime! = MTime! - .05
                                   Ed.LC = MaxInt%(Ed.LC - Ed.Wide, 1)
                                   Ed.CurCol = MaxInt%(Ed.CurCol - Ed.Wide, 1)
                                   X$ = MouseKey$
                                   RePrint = -1

                                '----- Right of Pointer
                                CASE IS > ScrHorPtr
                                   MTime! = MTime! - .05
                                   IF Ed.Wrap THEN
                                      Temp = MaxInt%(1, Ed.Wrap - Ed.Wide)
                                   ELSE
                                      Temp = 256 - Ed.Wide
                                   END IF
                                   Ed.LC = MinInt%(Ed.LC + Ed.Wide, Temp)
                                   Ed.CurCol = MinInt%(Ed.CurCol + Ed.Wide, Temp)
                                   X$ = MouseKey$
                                   RePrint = -1

                                CASE ELSE
                             END SELECT
                          END IF
                          
                       END IF

                 END SELECT
              END IF

              LMRow = Ed.MRow           'Remember were we were so we
              LMCol = Ed.MCol           '  can detect movement.
             
           '----- No Mouse activity
           ELSEIF WasPressed THEN
              MouseAct = 0

              '----- Un-restrict Mouse cursor if button let go
              CALL MouseTrap(1, 1, ScrRows, 80)

              WasPressed = 0
           END IF
          
           'MMMMMMMMMMMMMMMMMMMMMM End of Mouse Code MMMMMMMMMMMMMMMMMMMMMMMM
          

        LOOP UNTIL QPLen%(X$) OR Action <> 0


        '----- If they pressed a shift cursor key,
        IF ShiftKey% AND ((QPLen%(X$) = 1 AND INSTR(NumPad$, X$)) OR (QPLen%(X$) = 2 AND INSTR(NumPad2$, RIGHT$(X$, 1)))) THEN
           IF NOT MarkBlock THEN        'If it's a new block
              FrstBlkKey = -1           'Set first key flag
              BlkRow = Ed.CurLine       'Save upper left coordinates
              BlkCol = Ed.CurCol
              SaveT = Ed.TL             'Save window coordinates
              SaveC = Ed.LC
              MarkBlock = -1            'Set block marking flag
              Ed.WasMarked = -1
           END IF

           '----- Reset the key codes to their un-shifted states for
           '      normal key processing
           SELECT CASE ASCII%(X$)
              CASE 49                           '1/End Key
                 X$ = Zero$ + CHR$(79)
              CASE 50                           '2/Down Key
                 X$ = Zero$ + CHR$(80)
              CASE 51                           '3/PgDn Key
                 X$ = Zero$ + CHR$(81)
              CASE 52                           '4/Left Key
                 X$ = Zero$ + CHR$(75)
              CASE 54                           '6/Right Key
                 X$ = Zero$ + CHR$(77)
              CASE 55                           '7/Home Key
                 X$ = Zero$ + CHR$(71)
              CASE 56                           '8/Up Key
                 X$ = Zero$ + CHR$(72)
              CASE 57                           '9/PgUp Key
                 X$ = Zero$ + CHR$(73)
              CASE ELSE
           END SELECT

        '----- If a block is marked and they didn't press a shifted cursor
        '----- key or they pressed "Ctrl Y", capture the Block to the
        '----- Clipboard array
        ELSEIF MarkBlock OR X$ = CHR$(25) OR Ed.DelBlock THEN
           IF X$ = CHR$(25) THEN                'If they pressed "Ctrl Y",
              Bl(0).B = Ed.CurLine               '  save current line coords.
              Bl(1).B = 1
              Bl(2).B = Ed.CurLine
              Bl(3).B = QPLen%(Array$(Ed.CurLine))
              ColBlock = -1                     'Not a column block.
           END IF
                                                'If key not Escape or F1-Help
           Ok = Ed.DelBlock OR QPLen%(X$) <> 0
           Ok = Ok AND X$ <> CHR$(27) AND X$ <> Zero$ + CHR$(59) AND X$ <> MouseKey$
           IF Ok THEN

              Ed.UlCRow = Bl(0).B               'Save top and bottom block
              Ed.UlCCol = Bl(1).B               '  coordinates.
              Ed.BrCRow = Bl(2).B
              Ed.BrCCol = Bl(3).B
              Ed.CBlock = ColBlock              'Save block type (mode) flag

              NumRows = Ed.BrCRow - Ed.UlCRow + 1
              
              IF Ed.CBlock THEN                 'Is this a column block?
                 BBytes& = 0                    'Init. bytes needed for block
                                                'Get width of block
                 NumCols = Ed.BrCCol - Ed.UlCCol + 1

                 FOR N = Bl(0).B TO Bl(2).B     'Calc. bytes needed for block
                     BBytes& = BBytes& + QPLen%(MID$(Array$(N), Bl(1).B, NumCols))
                 NEXT
                 '----- See if we have enough far memory
                 IF ((CLNG(NumRows) * NumCols)) + 50000 > FRE(-1) OR CLNG(NumRows) * NumCols > 65536 THEN
                    Ed.MErr = 1                 'Set error flag
                    Ed.UlCRow = 0               'Erase block marking flags
                    MarkBlock = 0
                    X$ = ""                     'Erase key so nothing more
                 ELSE                           '  happens
                                                'Save the block to far memory
                    REDIM ClipBd((CLNG(NumRows) * NumCols) \ 2 + 1)
                    CALL MidStrSave(VARPTR(Array$(Ed.UlCRow)), NumRows, Ed.UlCCol, NumCols, ClipBd(0))
                 END IF
              ELSE                              'Sentence block
                                                'Save top and bottom lines
                 ClipBd1$ = MID$(Array$(Ed.UlCRow), Ed.UlCCol)
                 ClipBd2$ = MID$(Array$(Ed.BrCRow), 1, Ed.BrCCol)

                 NumRows = NumRows - 2          'Calc number of rows
                                                'Init. bytes needed for block
                 BBytes& = QPLen%(ClipBd1$) + QPLen%(ClipBd2$)

                 IF NumRows > 0 THEN            'Calc bytes needed by rest of
                    FOR N = Bl(0).B TO Bl(2).B  '  block
                        BBytes& = BBytes& + QPLen%(Array$(N))
                    NEXT
                    '----- See if we have enough far memory
                    Temp& = StringSize&(VARPTR(Array$(Ed.UlCRow + 1)), NumRows)
                    IF Temp& + 40000 > FRE(-1) THEN
                       BEEP
                       Ed.MErr = 1              'Set error flag
                       Ed.UlCRow = 0            'Erase block marking flags
                       MarkBlock = 0
                       X$ = ""                  'Erase key so nothing more
                    ELSE                        '  happens
                                                'Save the block to far memory
                       REDIM ClipBd(Temp& \ 2 + (Temp& MOD 2))
                       CALL StringSave(VARPTR(Array$(Ed.UlCRow + 1)), ClipBd(0), NumRows)
                    END IF
                 ELSE
                    REDIM ClipBd(0)
                 END IF
              END IF


              '----- Delete block if they pressed "Shift Del" or just "Del"
              IF Ed.DelBlock OR (ShiftKey% AND X$ = ".") OR X$ = Zero$ + CHR$(83) THEN
                 Ed.DelBlock = 0                'If it's a column block,
                 IF Ed.BrCRow = Ed.UlCRow THEN
                    Array$(Ed.UlCRow) = LEFT$(Array$(Ed.UlCRow), Ed.UlCCol - 1) + MID$(Array$(Ed.BrCRow), Ed.BrCCol + 1)
                    Array$(Ed.UlCRow) = Array$(Ed.UlCRow) + SPACE$(FnSpaces2Pad%(Array$(Ed.BrCRow)))
                    IF ArrayEnd > Ed.UlCRow THEN       'EW 7-26-93
                      Array$(Ed.UlCRow) = Array$(Ed.UlCRow) + Array$(Ed.UlCRow + 1)
                    END IF
                    Temp = Ed.UlCRow + 1
                    GOSUB DeleteLine

                 ELSEIF Ed.CBlock THEN
                                                '  delete range of each row
                    FOR N = Ed.UlCRow TO Ed.BrCRow
                        Array$(N) = LEFT$(Array$(N), Ed.UlCCol - 1) + MID$(Array$(N), Ed.BrCCol + 1)
                        Array$(N) = RTRIM$(Array$(N))
                    NEXT
                 ELSE                           'Sentence block
                    Array$(Ed.UlCRow) = LEFT$(Array$(Ed.UlCRow), Ed.UlCCol - 1) + MID$(Array$(Ed.BrCRow), Ed.BrCCol + 1)
                                                'Delete range of each row
                    FOR N = Ed.UlCRow + 1 TO Ed.BrCRow
                        Temp = Ed.UlCRow + 1
                        GOSUB DeleteLine
                    NEXT
                 END IF
                 Ed.LCount = FindLast%(VARPTR(Array$(ArrayEnd)), ArrayEnd)
                 Ed.CurLine = Ed.UlCRow         'Re-establish current cursor
                 Ed.CurCol = Ed.UlCCol          '  and window coordinates.
                 Ed.TL = MinInt%(SaveT, Ed.CurLine)
                 Ed.LC = MinInt%(SaveC, Ed.CurCol)
                 IF Ed.Wrap THEN                'If word wrap is on, then
                    WrapLine = Ed.CurLine
                    GOSUB WrapUp                '  and then up
                    GOSUB WrapDown              '  wrap words down
                 END IF
                 X$ = Zero$ + One$              'Clear key press
                 Ed.Changed = -1
              END IF
              RePrint = -1                      'Set to reprint window

           ELSEIF X$ = CHR$(27) THEN            'User pressed Esc so clear it
              X$ = Zero$ + One$
           END IF
                                                'If User didn't press help,
                                                '  clear block marking flag
           IF X$ <> Zero$ + CHR$(59) AND X$ <> MouseKey$ AND QPLen%(X$) <> 0 THEN MarkBlock = 0

        '----- Shift Insert (Insert Clipboard contents)
        ELSEIF Ed.InsBlock OR (ShiftKey% AND (X$ = "0" OR X$ = Zero$ + CHR$(82))) THEN
           Ed.InsBlock = 0
           X& = FRE("")                         'If a block has been marked
                                                '  and there is enough string
                                                '  memory
           IF Ed.UlCRow AND BBytes& < X& - 1280 THEN

              IF Ed.CBlock THEN                 ' If its a column block,
                 Temp$ = SPACE$(NumCols)
                 IF NumRows > 1 THEN
                    FOR N = 1 TO NumRows        'Do each line of clipboard

                        Temp = Ed.CurLine + N - 1 'Calc text array element
                        IF Temp < ArrayEnd THEN
                                                'If it would be inside a line,
                                                '  insert a line
                           Ok = 0
                           IF Ed.CurCol <= QPLen%(Array$(Temp)) THEN
                              IF Blanks%(Array$(Temp)) < Ed.CurCol + NumCols - 1 THEN
                                 Temp$ = ""
                                 GOSUB InsertLine
                                 Temp$ = SPACE$(NumCols)
                              ELSE
                                 Ok = -1
                              END IF
                           END IF
                       
                           CALL MidStrRest(Temp$, N, ClipBd(0))

                           IF FRE("") < 1280& THEN
                              BEEP
                              Ed.MErr = 1       'Set error flag
                              EXIT FOR
                           END IF

                           IF NOT Null%(Temp$) THEN
                              IF Ok THEN
                                 MID$(Array$(Temp), Ed.CurCol) = Temp$
                              ELSE
                                                'Pad with spaces to the left
                                 Array$(Temp) = Array$(Temp) + SPACE$(Ed.CurCol - QPLen%(Array$(Temp)) - 1) + Temp$
                                 Array$(Temp) = RTRIM$(Array$(Temp))
                              END IF
                           END IF
                                                'Update line count
                           Ed.LCount = MaxInt%(Ed.LCount, Temp)
                        END IF
                    NEXT
                                                'Update number of lines
                    Ed.LCount = FindLast%(VARPTR(Array$(ArrayEnd)), ArrayEnd)

                 ELSE                           'Restore one line of text
                    IF Ed.CurCol > QPLen%(Array$(Ed.CurLine)) THEN Array$(Ed.CurLine) = Array$(Ed.CurLine) + SPACE$(Ed.CurCol - QPLen%(Array$(Ed.CurLine)) - 1)
                    CALL MidStrRest(Temp$, 1, ClipBd(0))
                    Array$(Ed.CurLine) = LEFT$(Array$(Ed.CurLine), Ed.CurCol - 1) + Temp$ + MID$(Array$(Ed.CurLine), Ed.CurCol)
                    Array$(Ed.CurLine) = RTRIM$(Array$(Ed.CurLine))
                                                'Wrap words down
                    Ed.LCount = MaxInt%(Ed.LCount, Ed.CurLine)
                    IF Ed.Wrap THEN
                       WrapLine = Ed.CurLine
                       GOSUB WrapDown
                    END IF
                 END IF
                 Temp$ = ""

              ELSE                              'Sentence block mode
              
                 ClipBytes& = UBOUND(ClipBd) * 2 + (ClipBd(UBOUND(ClipBd)) < 256)
                 IF Ed.Wrap THEN                'If in word wrap mode,
                                                'Compose top line of block
                    RightSide$ = MID$(Array$(Ed.CurLine), Ed.CurCol)
                    Array$(Ed.CurLine) = LEFT$(Array$(Ed.CurLine), Ed.CurCol - 1)

                    Temp = Ed.CurLine           'Save current line #
                    
                    FOR N = 0 TO NumRows        'Compose middle lines of block
                        IF N THEN
                                                'Make string to hold a line
                           Temp$ = SPACE$(StrLength%(ClipBd(0), ClipBytes&, N))
                                                'Get the next string
                           Get1Str Temp$, ClipBd(0), N
                        ELSE
                           Temp$ = ClipBd1$
                        END IF

                        Temp$ = Temp$ + SPACE$(FnSpaces2Pad%(Temp$))
                                                'If the string is nul,
                        IF QPLen%(Temp$) = 0 OR LEFT$(Temp$, 1) = " " THEN
                                                '  insert a new line
                           Temp = MinInt%(Temp + 1, ArrayEnd)
                           GOSUB InsertLine
                           IF QPLen%(Temp$) = 0 THEN
                              Temp = MinInt%(Temp + 1, ArrayEnd)
                              GOSUB InsertLine
                           END IF
                        ELSE                    'Insert text in current line
                           Array$(Temp) = Array$(Temp) + SPACE$(FnSpaces2Pad%(Temp$))
                           Array$(Temp) = Array$(Temp) + Temp$
                        END IF
                    NEXT                        'Insert last line
                    Array$(Temp) = RTRIM$(Array$(Temp) + ClipBd2$ + RightSide$)
                                                'Update last line number
                    Ed.LCount = FindLast%(VARPTR(Array$(ArrayEnd)), ArrayEnd)
                    Temp$ = ""                  'Erase the restore buffer

                    WrapLine = Ed.CurLine
                    GOSUB WrapAll               'Wrap words down

                 ELSE                           'Not in word wrap mode

                   
                    FOR N = 1 TO NumRows + 2    'For each row of the block
                        Temp = Ed.CurLine + N - 1 'Calc line number of text
                        IF Temp <= ArrayEnd THEN  'Don't go off the end of array
                          
                           Temp$ = ""           'Init buffer string
                           IF N = 1 THEN        'If it's the first line, use
                                                '  the "ClipBd1$"
                              Temp$ = SPACE$(Ed.UlCCol - 1) + ClipBd1$
                                                'If it's the last line use
                           ELSEIF N = NumRows + 2 THEN '  "ClipBd2$"
                              IF Ed.BrCCol > 0 THEN Temp$ = ClipBd2$

                           ELSE                 'For the body of the block,
                                                '  get lines from far mem.
                              Temp$ = SPACE$(StrLength%(ClipBd(0), ClipBytes&, N - 1))
                              CALL Get1Str(Temp$, ClipBd(0), N - 1)
                           END IF
                           Temp$ = RTRIM$(Temp$)
                           GOSUB InsertLine
                        END IF
                    NEXT
                    Temp$ = ""                  'Erase the restore buffer
                                                'Update last line number
                    Ed.LCount = FindLast%(VARPTR(Array$(ArrayEnd)), ArrayEnd)

                 END IF
              END IF
              RePrint = -1                      'Set flag to re-print window
              Ed.Changed = -1                   'Text has been changed

           ELSEIF BBytes& >= X& - 1280 THEN     'Wasn't enough string memory
              BEEP
              Ed.MErr = 1                       'Set error flag
           END IF
           X$ = Zero$ + One$                    'Clear key press
        END IF

        '********************************************************************
        '* End of Block Operations
        '********************************************************************


    LOOP WHILE Action = 0                       'Go back for another key if
                                                '  not in polling mode.

    Ed.InsStat = Insrt                           'Show the caller the Insert
                                                '  state

    EXIT SUB                                    'Bail out


'****************************************************************************
'*********************   Start of Subroutine code   *************************
'****************************************************************************



'----- Adjust the size depending on monitor type, and insert mode
CsrSize:
    IF Insrt = -1 THEN                          'If in insert mode,
       LOCATE , , , BScan \ 2, BScan            '  make large size cursor
    ELSE                                        'Overtype mode,
       LOCATE , , , BScan - 1, BScan            '  use 2 scan line cursor.
    END IF
RETURN


'----- Display the current line number on the status line
DisplayLineNumber:
    LOCATE , , 0                                'Turn the cursor off
    RSET CurLine$ = MID$(STR$(Ed.CurLine), 2)   'Put number in temp string
    CALL QPrintRC(CurLine$, Ed.TSRow + Ed.Rows, Ed.LSCol, 63)

    '----- Update the vertical scroll bar pointer
    IF Ed.LCount >= Ed.Rows THEN                'Calc the Vertical position %
       VrtPtr = MinInt%(Ed.CurLine * (Ed.Rows - 3&) \ Ed.LCount, Ed.Rows - 3)
    ELSE
       VrtPtr = 0
    END IF
                                                'Erase old pointer
    CALL QPrintRC(CHR$(176), Ed.TSRow + OldVrtPtr + 1, Ed.LSCol + Ed.Wide, 112)
                                                'Print the new one
    CALL QPrintRC(CHR$(8), Ed.TSRow + VrtPtr + 1, Ed.LSCol + Ed.Wide, 112)
    OldVrtPtr = VrtPtr                          'Save old pointer for later

RETURN



'----- Display the current column number on the status line
DisplayColNumber:
    LOCATE , , 0                                'Turn the cursor off
    RSET CurCol$ = MID$(STR$(Ed.CurCol), 2)     'Put number in temp string
    CALL QPrintRC(CurCol$, Ed.TSRow + Ed.Rows, Ed.LSCol + 5, 63)

    '----- Update the horizontal scroll bar pointer
    IF Ed.Wrap THEN                             'Calc pointer position
       HorPtr = Ed.Wrap + 1
    ELSE
       HorPtr = 256
    END IF
    HorPtr = MinInt%(Ed.CurCol * (Ed.Wide - 10) \ HorPtr, Ed.Wide - 11)

    CALL QPrintRC(CHR$(176), Ed.TSRow + Ed.Rows, Ed.LSCol + 9 + OldHorPtr, 112)
    CALL QPrintRC(CHR$(8), Ed.TSRow + Ed.Rows, Ed.LSCol + 9 + HorPtr, 112)
    OldHorPtr = HorPtr                          'Save pointer for next pass
    
RETURN



WindowLimits:
    IF Ed.CurCol >= Ed.LC + Ed.Wide THEN
       Ed.LC = Ed.CurCol - Ed.Wide + 1
       RePrint = -1
    ELSEIF Ed.CurCol < Ed.LC THEN
       Ed.LC = MaxInt%(1, Ed.CurCol - Ed.Wide)
       RePrint = -1
    END IF

    IF Ed.CurLine >= Ed.TL + Ed.Rows THEN
       Ed.TL = Ed.CurLine - Ed.Rows + 1
       RePrint = -1
    ELSEIF Ed.CurLine < Ed.TL THEN
       Ed.TL = Ed.CurLine
       RePrint = -1
    END IF
RETURN



'----- Move the cursor down a line
CursorDown:
    IF Ed.CurLine >= ArrayEnd THEN Ed.CurLine = ArrayEnd
                                     'if we're at the bottom of the screen
    Temp = (Ed.CurLine - Ed.TL + 1) - Ed.Rows
    IF Temp > 0 THEN
       Ed.TL = Ed.TL + Temp          '  show the top line being one higher,
       X = Ed.TSRow + Ed.Rows - 1
       CALL HideCursor               'Scroll the window up
       CALL ScrollU(Ed.TSRow, Ed.LSCol, X, Ed.LSCol + Ed.Wide - 1, Temp, -1)
       FOR N = 1 TO Temp
           CALL QPrintRC(MID$(Array$(Ed.CurLine - N + 1), Ed.LC, Ed.Wide), X - N + 1, Ed.LSCol, -1)
       NEXT
       CALL ShowCursor
    END IF
RETURN



'----- Move the cursor up a line
CursorUp:
    IF Ed.CurLine < 1 THEN Ed.CurLine = 1 'ignore if already on first line

    Temp = Ed.TL - Ed.CurLine
    IF Temp > 0 THEN                    'if we're at the top of the screen
       Ed.TL = Ed.TL - Temp             '  show the top line being one less,
       CALL HideCursor                  'Scroll the window Down
       ScrollD Ed.TSRow, Ed.LSCol, Ed.TSRow + Ed.Rows - 1, Ed.LSCol + Ed.Wide - 1, Temp, -1
       FOR N = Temp TO 1 STEP -1
           CALL QPrintRC(MID$(Array$(Ed.CurLine + N - 1), Ed.LC, Ed.Wide), Ed.TSRow + N - 1, Ed.LSCol, Ed.AColor)
       NEXT
       CALL ShowCursor
    END IF
RETURN




'----- Move cursor left
CursorLeft:
    IF Ed.CurCol < 1 THEN Ed.CurCol = 1
      
    Temp = Ed.LC - Ed.CurCol
    IF Temp > 0 THEN                            'If off the left of screen
       Ed.LC = Ed.LC - Temp                     'Decrement window column
       CALL HideCursor
       CALL ScrollR(Ed.TSRow, Ed.LSCol, Ed.TSRow + Ed.Rows - 1, Ed.LSCol + Ed.Wide - 1, Temp, -1)
       LOCATE Ed.TSRow, Ed.LSCol
       CALL APrint0(VARPTR(Array$(Ed.TL)), Ed.Rows, Ed.LC, Temp, -1)
       CALL ShowCursor
    END IF
RETURN


      
'----- Move cursor right
CursorRight:
    IF Ed.CurCol > 255 THEN Ed.CurCol = 255
                                                'If off right of window,
    Temp = (Ed.CurCol - Ed.LC + 1) - Ed.Wide
    IF Temp > 0 THEN
       Ed.LC = Ed.LC + Temp                     '  increment window column
       CALL HideCursor
       CALL ScrollL(Ed.TSRow, Ed.LSCol, Ed.TSRow + Ed.Rows - 1, Ed.LSCol + Ed.Wide - 1, Temp, -1)
       LOCATE Ed.TSRow, Ed.LSCol + Ed.Wide - Temp
       CALL APrint0(VARPTR(Array$(Ed.TL)), Ed.Rows, Ed.LC + Ed.Wide - Temp, Temp, -1)
       CALL ShowCursor
    END IF
RETURN


      
'----- Wrap all text to current right margin
WrapAll:
    DO UNTIL WrapLine > Ed.LCount               'Stop at last used element
        IF QPLen%(Array$(WrapLine)) THEN        'If it's not a blank line,
           GOSUB WrapUp                         '  then up.
           GOSUB WrapDown                       '  wrap paragraph down and
           WrapLine = Lin + 1                   'Look at line past paragraph
        ELSE                                    '  "Lin" is set in "WrapUp"
           WrapLine = WrapLine + 1              'Line was blank, look at next
        END IF
    LOOP
RETURN




'----- Wrap words down to form a paragraph
WrapDown:
    Lin = WrapLine                              'Make temp copy of line #
    LinLen = QPLen%(Array$(Lin))                'Get the length of cur. line
    P = INSTR(Array$(Lin), Par$)                'Look for a paragraph marker
                                                'Do lines that are too long
    DO WHILE LinLen > Ed.Wrap

       IF P > 0 AND P <= Ed.Wrap + 1 THEN       'If marker is in range,
          B = P                                 '  set cutoff to marker
          Array$(Lin) = LEFT$(Array$(Lin), P - 1) + MID$(Array$(Lin), P + 1)
       ELSE                                     'Starting at the right margin,
                                                'look backwards for a blank
          I = QInstrB%(Ed.Wrap + 1, Array$(Lin), " ")
          IF I = 0 THEN I = Ed.Wrap + 1         'If no blanks, chop it off

          B = Blanks%(MID$(Array$(Lin), I)) + I 'Now look fwd. for non-blank
       END IF
       

       IF B <= LinLen THEN                      'If we didn't go past the end,
          Lin = Lin + 1                         '  increment the line number
          IF Lin > ArrayEnd THEN                'Past end?  Bail out
             Lin = Lin - 1
             Ed.MErr = 2
             EXIT DO
          END IF

          LinLen = QPLen%(Array$(Lin))          'Get the length of new line
                                                'If this is a blank line or
                                                '  starts with a space
          IF LinLen = 0 OR Blanks%(Array$(Lin)) OR ASCII%(Array$(Lin)) = 20 THEN
             Temp = Lin                         'Insert remainder of last line
             Temp$ = MID$(Array$(Lin - 1), B)   '  into a new line
             GOSUB InsertLine
          ELSE                                  'Add remainder of prev. line
                                                '  to this line
             Array$(Lin) = MID$(Array$(Lin - 1), B) + SPACE$(FnSpaces2Pad%(Array$(Lin - 1))) + Array$(Lin)
          END IF
                                                'If we just wrapped current
          IF Lin - 1 = Ed.CurLine THEN          '  line and the cursor was
             IF Ed.CurCol >= B THEN             '  within the wrapped words,
                Ed.CurCol = Ed.CurCol - B + 1   '  move the cursor to the new
                Ed.LC = ((Ed.CurCol \ Ed.Wide) * Ed.Wide) + 1'  line at the end of the
                Ed.CurLine = MinInt%(Lin, ArrayEnd)          '  wrapped words
                Ed.TL = MaxInt%(Ed.TL, Ed.CurLine - Ed.Rows + 1)
             END IF
          END IF

          LinLen = QPLen%(Array$(Lin))          'Get length of the new line
                                                'Trim the prev. line
          Array$(Lin - 1) = RTRIM$(LEFT$(Array$(Lin - 1), B - 1))
          RePrint = -1                          'Set flag to re-print window

       ELSE                                     'Words weren't found past wrap
          Lin = Lin + 1                         'Increment the line number
          IF Lin > ArrayEnd THEN
             Lin = Lin - 1
             Ed.MErr = 2
             EXIT DO                            'Past end?  Bail out
          END IF
          LinLen = QPLen%(Array$(Lin))          'Get its length
       END IF

       P = INSTR(Array$(Lin), Par$)             'Look for a paragraph marker

    LOOP                                        'Process the new line

    IF P THEN
       Array$(Lin) = LEFT$(Array$(Lin), P - 1) + MID$(Array$(Lin), P + 1)
    END IF

RETURN



'----- Wrap words Up to re-form a paragraph
WrapUp:
    Lin = WrapLine                              'Make temp copy of line #
    '----- If the line isn't nul and current line isn't past the end and the
    '----- current line doen't have a paragraph marker on the end.
    DO UNTIL Null%(Array$(Lin)) OR Lin >= Ed.LCount

        P = INSTR(Array$(Lin + 1), Par$)
        IF P THEN
           Array$(Lin + 1) = LEFT$(Array$(Lin + 1), P - 1) + MID$(Array$(Lin + 1), P + 1)
        END IF

        LinLen = QPLen%(Array$(Lin + 1))        'Get the length of next line
                                                'If it has Par marker or is
                                                '  blank, bail out
        IF Blanks%(Array$(Lin + 1)) THEN EXIT DO

        Temp = FnSpaces2Pad%(Array$(Lin))

        IF Lin = WrapLine AND Ed.Wrap > WrapWas THEN
           Extra = WrapWas - QPLen%(Array$(Lin)) - Temp + 1
           GOSUB GetWordPos
           IF I THEN                            'Words were found to fill so,
              IF INSTR(LEFT$(Array$(Lin + 1), I - 1), " ") THEN
                 EXIT DO
              END IF
           END IF
        END IF

        Extra = Ed.Wrap - QPLen%(Array$(Lin)) - Temp + 1

        GOSUB GetWordPos

        IF I THEN

           IF Lin = WrapLine AND Ed.Wrap <= WrapWas THEN
              IF INSTR(LEFT$(Array$(Lin + 1), I - 1), " ") THEN ' OR I = LinLen THEN
                 EXIT DO
              END IF
           END IF
                                                'Add words from next line
           Array$(Lin) = Array$(Lin) + SPACE$(Temp) + LEFT$(Array$(Lin + 1), I)
                                                'Now delete them from next
           Array$(Lin + 1) = LTRIM$(MID$(Array$(Lin + 1), I + 1))
           RePrint = -1                         'Set "RePrint" flag

           IF LEN(Array$(Lin + 1)) = 0 THEN     'If nothing is left of next
                                                '  line, delete it.
              Temp = Lin + 1
              GOSUB DeleteLine

              Lin = Lin - 1
              IF Lin + 1 > Ed.LCount THEN EXIT DO 'Off the end, bail out
           END IF
        END IF

        Lin = Lin + 1
    LOOP

RETURN



GetWordPos:
    IF Extra > 0 THEN                           'If there is extra space,
       IF Extra >= LinLen THEN
          I = LinLen
       ELSE
          B = Extra
          IF MID$(Array$(Lin + 1), B, 1) <> " " THEN
             B = QInstrB%(B, Array$(Lin + 1), " ")
          END IF

          FOR I = B TO 1 STEP -1
              IF MID$(Array$(Lin + 1), I, 1) <> " " THEN EXIT FOR
          NEXT
       END IF
    ELSE
       I = 0
    END IF
RETURN



'----- Insert an element into the text array at "Temp"
InsertLine:
    IF Temp <= Ed.LCount THEN
       Ed.LCount = MinInt%(Ed.LCount + 1, ArrayEnd)
       CALL InsertStr(VARPTR(Array$(Temp)), Temp$, Ed.LCount - Temp)
    ELSE
       Ed.LCount = Temp
       Array$(Temp) = Temp$
    END IF
RETURN

      

'----- Delete an element from the text array
DeleteLine:
    IF Temp <= Ed.LCount THEN
       IF Temp < Ed.LCount THEN
          CALL DeleteStr(VARPTR(Array$(Temp)), Ed.LCount - Temp)
       END IF
       Array$(Ed.LCount) = ""
       Ed.LCount = Ed.LCount - 1                'Update last line number
    END IF
RETURN
         


'----- Resize and Draw the window frame
InitWindow:
    '----- Calculate the bounds of the window
    WC(0, 0) = Ed.TSRow + (Ed.Frame <> 0)       'Top line of window
    WC(1, 0) = Ed.LSCol + (Ed.Frame <> 0)       'Left margin of window
    WC(2, 0) = WC(0, 0) + Ed.Rows - (2 * (Ed.Frame <> 0)) - 1  'Bottom line of window
    WC(3, 0) = WC(1, 0) + Ed.Wide - (2 * (Ed.Frame <> 0)) - 1  'Right margin of window
   
    'Did the Lower Right corner move Up?
    IF WC(2, 0) < WC(2, 1) THEN                 'Restore slice
       CALL MPRestore(WC(2, 0) + 1, WC(1, 1), WC(2, 1), WC(3, 1), 80, ScrBuf((WC(2, 0) * 80) + WC(1, 1)))
    END IF

    'Did the Lower Right corner move Left?
    IF WC(3, 0) < WC(3, 1) THEN                 'Restore slice
       CALL MPRestore(WC(0, 1), WC(3, 0) + 1, WC(2, 1), WC(3, 1), 80, ScrBuf((WC(0, 1) - 1) * 80 + WC(3, 0) + 1))
    END IF

    'Did the Upper Left corner move Down?
    IF WC(0, 0) > WC(0, 1) THEN                 'Restore slice
       CALL MPRestore(WC(0, 1), WC(1, 1), WC(0, 0) - 1, WC(3, 1), 80, ScrBuf((WC(0, 1) - 1) * 80 + WC(1, 1)))
    END IF
    
    'Did the Upper Left corner move Right?
    IF WC(1, 0) > WC(1, 1) THEN                 'Restore slice
       CALL MPRestore(WC(0, 1), WC(1, 1), WC(2, 1), WC(1, 0) - 1, 80, ScrBuf((WC(0, 1) - 1) * 80 + WC(1, 1)))
    END IF
                       
    WC(0, 1) = WC(0, 0)
    WC(1, 1) = WC(1, 0)                         'Save new bounds for next time
    WC(2, 1) = WC(2, 0)
    WC(3, 1) = WC(3, 0)
                                                
    LineBuf$ = SPACE$(Ed.Wide)                  'Temp buffer used for printing
    

    '----- If Frame flag set, draw the frame and scroll bars
    IF Ed.Frame THEN
       CALL HideCursor                          'Shut the mouse cursor off
       '----- Print the top line
       CALL QPrintRC(CHR$(4), Ed.TSRow - 1, Ed.LSCol - 1, HiClr)
       CALL QPrintRC(MID$(Ruler(1), Ed.LC + 1, Ed.Wide), Ed.TSRow - 1, Ed.LSCol, 112)
       CALL QPrintRC(CHR$(18), Ed.TSRow - 1, WC(3, 0), HiClr)
       '----- Print the middle lines
       X = Ed.TL
       FOR N = Ed.TSRow TO Ed.TSRow + Ed.Rows - 1
           CALL QPrintRC("³", N, Ed.LSCol - 1, HiClr)
           IF X <= ArrayEnd THEN
              LSET LineBuf$ = MID$(Array$(X), Ed.LC)
           ELSE
              LSET LineBuf$ = ""
           END IF
           X = X + 1
           CALL QPrintRC(LineBuf$, N, Ed.LSCol, Ed.AColor)
           CALL QPrintRC("°", N, WC(3, 0), 112)
       NEXT

       '----- Print the up and down arrows
       CALL QPrintRC(CHR$(24), Ed.TSRow, WC(3, 0), 112)
       CALL QPrintRC(CHR$(25), N - 1, WC(3, 0), 112)
       '----- Print the status spaces on bottom of window
       CALL QPrintRC("À", Ed.TSRow + Ed.Rows, Ed.LSCol - 1, HiClr)
       CALL QPrintRC(":", Ed.TSRow + Ed.Rows, Ed.LSCol + 4, 48)
       '----- Print the horizontal scroll bar
       CALL QPrintRC(CHR$(27) + STRING$(Ed.Wide - 10, "°") + CHR$(26), Ed.TSRow + Ed.Rows, Ed.LSCol + 8, 112)
       CALL QPrintRC(CHR$(4), Ed.TSRow + Ed.Rows, WC(3, 0), HiClr)

       CALL ShowCursor                          'Turn the mouse cursor back on
       LastCurLine = 0                          'Save cursor location so we
       LastCurCol = 0                           '  know when to reprint status
    ELSE
       RePrint = -1                             'Set flag to print the window
    END IF
                                                'Make sure the cursor stays in
                                                '  the window
    Ed.CurLine = MinInt%(Ed.CurLine, Ed.TL + Ed.Rows - 1)
    Ed.CurCol = MinInt%(Ed.CurCol, Ed.LC + Ed.Wide - 1)
    OldVrtPtr = 0                               'Init scroll pointers
    OldHorPtr = 0

RETURN
      


'----- Restore the screen and free up memory
CleanUp:
    CALL MScrnRest(1, 1, ScrRows, 80, ScrBuf(1))'Restore the screen
    ERASE ScrBuf, Ruler                         'Clean up memory
    LineBuf$ = ""
    LOCATE , , , BScan - 1, BScan
RETURN


END SUB          'That's all folks.  And you thought editing was easy?

