'********** QEdit7.Bas ******************************************************
'Windowed text editing module with word wrap and block operations.  This
'version of the editor has been made as granular as possible inorder to
'allow QBX to move it into expanded memory.  This version is functionally
'identical to "QEdit.Bas" except for the following:
'
'  Previous versions would capture a marked block whenever a non block
'  marking key was pressed.  This version will capture blocks only when
'  Ctrl+Ins is pressed (same as QB, QBX, PBW).  This is possible only when
'  compiling with BASIC 7+.  In previous versions of BASIC, Ctrl+Ins is not
'  returned by INKEY$.  If you do not have BASIC 7, you will need to change
'  the code contained in "QECheckBlockOps" that is shown under 'BC7ONLY.
'
'Copyright (c) 1988 - 1990 Crescent Software
'by Don Malin
'
'07-31-1990 Fixed problem marking blocks with the mouse. (MouseKey$ was not
'           Shared with QECheckBlockOps).  Fixed problem where expanding the
'           window when the last element of the array was displayed caused
'           "Subscript out of range".
'08-09-1990 Fixed problem with TAB at last character on a line.  Made Back-
'           Tab go to column 1 properly.
'08-17-1990 Made pasting of multi paragraph sentence blocks retain paragraphs
'
'The main procedure is "QEdit"
'
'****************************************************************************

DEFINT A-Z

'----- Internal BASIC Procedures
DECLARE SUB QEBackSpace (Array$(), Ed AS ANY)
DECLARE SUB QEBackTab (Array$(), Ed AS ANY)
DECLARE SUB QECaptureBlock (Array$(), Ed AS ANY)
DECLARE SUB QECheckBlockOps (X$, Array$(), Ed AS ANY)
DECLARE SUB QECheckMouseOps (Array$(), Ed AS ANY, X$)
DECLARE SUB QECheckWindowLimits (Ed AS ANY)
DECLARE SUB QECtrlLeft (Array$(), Ed AS ANY)
DECLARE SUB QECtrlPgDn (Array$(), Ed AS ANY)
DECLARE SUB QECtrlRight (Array$(), Ed AS ANY)
DECLARE SUB QECursorDown (Array$(), Ed AS ANY)
DECLARE SUB QECursorLeft (Array$(), Ed AS ANY)
DECLARE SUB QECursorRight (Array$(), Ed AS ANY)
DECLARE SUB QECursorUp (Array$(), Ed AS ANY)
DECLARE SUB QEDeleteBlock (Array$(), Ed AS ANY)
DECLARE SUB QEDeleteKey (Array$(), Ed AS ANY)
DECLARE SUB QEDeleteLine (AtLine%, Ed AS ANY, Array$())
DECLARE SUB QEDisplayColumn (Ed AS ANY)
DECLARE SUB QEDisplayLineNo (Ed AS ANY)
DECLARE SUB QEDisplayWindow (Action%, Array$(), Ed AS ANY)
DECLARE SUB QEEnterKey (Array$(), Ed AS ANY)
DECLARE SUB QEInitialize (Ed AS ANY)
DECLARE SUB QEInitWindow (Ed AS ANY, Array$())
DECLARE SUB QEInsertLine (NewLine$, AtLine%, Ed AS ANY, Array$())
DECLARE SUB QEMouseDrag (X$, Array$(), Ed AS ANY)
DECLARE SUB QEMousePress (X$, Ed AS ANY)
DECLARE SUB QEPaintBlock (Ed AS ANY)
DECLARE SUB QEPasteColBlock (Array$(), Ed AS ANY)
DECLARE SUB QEPasteSentBlock (Array$(), Ed AS ANY)
DECLARE SUB QEShowHelp (Ed AS ANY)
DECLARE SUB QETabKey (Array$(), Ed AS ANY)
DECLARE SUB QETextKeys (X$, Array$(), Ed AS ANY)
DECLARE SUB QEWrapAll (WrapLine%, Array$(), Ed AS ANY)
DECLARE FUNCTION QEWrapDown% (WrapLine%, Array$(), Ed AS ANY)
DECLARE FUNCTION QEWrapUp% (WrapLine%, Array$(), Ed AS ANY)


'----- Assembler SUBs
DECLARE SUB APrint0 (BYVAL X, NumEls, StartChar, NumChars, Colr)
DECLARE SUB APrintT0 (BYVAL Segment%, BYVAL Address%, StrLen%, NumEls%, FirstChar%, NumChars%, Clr%)
DECLARE SUB ButtonPress (Button, Status, Count, X, Y)
DECLARE SUB DeleteStr (BYVAL Address, NumEls)
DECLARE SUB Get1Str (Work$, SEG Element, StrNumber)
DECLARE SUB GetCursor (X, Y, Button)
DECLARE SUB GetVMode (Mode, Page, PageSize, Rows, Columns)
DECLARE SUB HideCursor ()
DECLARE SUB InsertStr (BYVAL Address, Inserted$, NumEls)
DECLARE SUB LoadHelp7 (BYVAL Segment%, BYVAL Address%)
DECLARE SUB MidStrSave (BYVAL Address, NumEls, FirstChar, NumChars, SEG Storage)
DECLARE SUB MidStrRest (Buffer$, StrNumber, SEG Storage)
DECLARE SUB MouseTrap (UlRow, UlCol, LrRow, LrCol)
DECLARE SUB MPaintBox (UlRow, UlCol, LrRow, LrCol, Colr)
DECLARE SUB MPRestore (UlRow%, UlCol%, LrRow%, LrCol%, OrigWidth%, SEG ArrayEl%)
DECLARE SUB MQPrint (X$, Colr)
DECLARE SUB MScrnSave (UlRow, UlCol, BRRow, BRCol, SEG Address)
DECLARE SUB MScrnRest (UlRow, UlCol, BRRow, BRCol, SEG Address)
DECLARE SUB Pause (Eighteenth)
DECLARE SUB QPrintRC (X$, Row%, Col%, Clr%)
DECLARE SUB ScrollD (UlRow%, UlCol%, BRRow%, BRCol%, Rows%, Page%)
DECLARE SUB ScrollL (UlRow%, UlCol%, BRRow%, BRCol%, Cols%, Page%)
DECLARE SUB ScrollR (UlRow%, UlCol%, BRRow%, BRCol%, Cols%, Page%)
DECLARE SUB ScrollU (UlRow%, UlCol%, BRRow%, BRCol%, Rows%, Page%)
DECLARE SUB ShowCursor ()
DECLARE SUB SplitColor (AColor, Fg, Bg)
DECLARE SUB StringSave (BYVAL Address, SEG Element, NumEls)


'----- Assembler FUNCTIONs
DECLARE FUNCTION ArraySize% (UlRow, UlCol, BRRow, BRCol)
DECLARE FUNCTION ASCII% (Ky$)
DECLARE FUNCTION Blanks% (Text$)
DECLARE FUNCTION DOSVer% ()
DECLARE FUNCTION FindLast% (BYVAL Address, Size)
DECLARE FUNCTION MaxInt% (Num1, Num2)
DECLARE FUNCTION MinInt% (Num1, Num2)
DECLARE FUNCTION Monitor% ()
DECLARE FUNCTION Null% (Text$)
DECLARE FUNCTION NumLock% ()
DECLARE FUNCTION PDQTimer& ()
DECLARE FUNCTION PeekBuf% ()
DECLARE FUNCTION QInstrB% (Start%, Text$, Search$)
DECLARE FUNCTION ShiftKey% ()
DECLARE FUNCTION StringSize& (BYVAL Address, NumEls)
DECLARE FUNCTION StrLength% (SEG Element, NumBytes AS ANY, StrNumber)


'$INCLUDE: 'QEditype.BI'                        'Type for editing information

TYPE BlkCoords                                  'Type for Block coordinates
    B AS INTEGER                                'Block coordinates
    PB AS INTEGER                               'Previous block coordinates
    P AS INTEGER                                'Paint coordinates
    PP AS INTEGER                               'Previous paint coordinates
END TYPE


CONST NumPad$ = "12346789"                      'Shifted arrow keys
CONST NumPad2$ = "stOPQKMGHK"                   'Unshifted arrow keys
CONST SkipTbl$ = " ^*()[]-=+,.<>/\:;"           'Word delimiters

DIM Bl(3) AS BlkCoords
DIM WC(3, 1)
REDIM ScrBuf%(0)
REDIM Ruler(0) AS STRING * 260
REDIM ClipBd(0)


'----- Returns the number of columns to advance at the end of a line
DEF FnSpaces2Pad (Text$)
    STATIC Temp

    SELECT CASE ASCII(RIGHT$(Text$, 1))
       CASE 46, 33, 63          '".", "!", "?"
          Temp = 2
       CASE 32, -1              'Space
          Temp = 0
       CASE ELSE
          Temp = 1
    END SELECT
    FnSpaces2Pad = Temp
END DEF

SUB QEBackSpace (Array$(), Ed AS EditInfo)

    SHARED LineBuf$, LineEd, Insrt, RePrint

    IF Ed.CurCol > 1 THEN                       'If not at column 1,
       Ed.CurCol = Ed.CurCol - 1                '  decrement the cursor posit.
       IF Insrt = -1 THEN                       'If in Insert mode, drag the
                                                '  line 1 char. left
          Array$(Ed.CurLine) = LEFT$(Array$(Ed.CurLine), Ed.CurCol - 1) + MID$(Array$(Ed.CurLine), Ed.CurCol + 1)
          IF LEN(Array$(Ed.CurLine)) THEN Ed.Changed = -1

          IF Ed.Wrap THEN                       'Wrap words up
             Lin = QEWrapUp(Ed.CurLine, Array$(), Ed)
          END IF
                                                'Not in Insert mode, blank char
       ELSEIF Ed.CurCol = LEN(Array$(Ed.CurLine)) THEN
          Array$(Ed.CurLine) = LEFT$(Array$(Ed.CurLine), Ed.CurCol - 1)
          Ed.Changed = -1

       ELSEIF Ed.CurCol < LEN(Array$(Ed.CurLine)) THEN
          MID$(Array$(Ed.CurLine), Ed.CurCol, 1) = " "
          Ed.Changed = -1
       END IF                                   'Put edited line in a buffer

       IF Ed.CurCol < Ed.LC THEN                'If we're at left window col,
          Ed.LC = Ed.LC - 1                     '  decrement window column
          RePrint = -1
       ELSE
          LSET LineBuf$ = MID$(Array$(Ed.CurLine), Ed.LC)
          LOCATE , Ed.LSCol, 0                  'Print the edited line
          MQPrint LineBuf$, Ed.AColor
       END IF
       LineEd = -1
                                                'If in Insert mode, go up
    ELSEIF Ed.CurLine > 1 THEN

       Temp = FnSpaces2Pad(Array$(Ed.CurLine - 1))
                                                'Copy line to line above
       Ed.CurCol = LEN(Array$(Ed.CurLine - 1)) + Temp + 1
       Array$(Ed.CurLine - 1) = Array$(Ed.CurLine - 1) + SPACE$(Temp) + Array$(Ed.CurLine)
                                                'Update window column
       Ed.LC = MaxInt%(Ed.CurCol - Ed.Wide + 1, Ed.LC)

                                                'Delete the current line
       QEDeleteLine Ed.CurLine, Ed, Array$()

       Ed.CurLine = Ed.CurLine - 1
       QECursorUp Array$(), Ed                  'Back up a line
       RePrint = -1                             'Set flag to re-print window

       IF Ed.Wrap THEN
          Lin = QEWrapDown(Ed.CurLine, Array$(), Ed)
       END IF
       Ed.Changed = -1
    END IF

END SUB

SUB QEBackTab (Array$(), Ed AS EditInfo)

    SHARED LineBuf$, Insrt, RePrint

    X = ((Ed.CurCol - 2) \ Ed.HTab) * Ed.HTab + 1
                                                'If in Insert mode and not at
                                                '  end of line,
    IF Insrt = -1 AND Ed.CurCol <= LEN(Array$(Ed.CurLine)) THEN
                                                'drag line to the left
       Array$(Ed.CurLine) = LEFT$(Array$(Ed.CurLine), X - 1) + MID$(Array$(Ed.CurLine), Ed.CurCol)
       IF Ed.Wrap THEN                          'Wrap words up
          Lin = QEWrapUp(Ed.CurLine, Array$(), Ed)
       END IF
       Ed.Changed = -1
    END IF

    Ed.CurCol = X                               'Adjust current column posit.

    IF Ed.CurCol < Ed.LC THEN                   'If off left of window,
       Ed.LC = Ed.CurCol                        '  adjust current window col
       RePrint = -1                             'Set flag to re-print window
    ELSE                                        'Otherwise,
       LOCATE , Ed.LSCol, 0                     'locate at left margin
                                                'Put new text in line buffer
       LSET LineBuf$ = MID$(Array$(Ed.CurLine), Ed.LC)
       MQPrint LineBuf$, Ed.AColor              'Print the line buffer
    END IF

END SUB

SUB QECaptureBlock (Array$(), Ed AS EditInfo)

    SHARED BBytes&, Text2Paste
    SHARED ClipBd(), ClipBd1$, ClipBd2$, NumRows, NumCols, ArrayEnd
    SHARED Bl() AS BlkCoords

    NumRows = Ed.BrCRow - Ed.UlCRow + 1
    Ed.CopyBlock = 0

    IF Ed.CBlock THEN                           'Is this a column block?
       BBytes& = 0                              'Init. bytes needed for block
                                                'Get width of block
       NumCols = Ed.BrCCol - Ed.UlCCol + 1

       FOR N = Bl(0).B TO Bl(2).B               'Calc. bytes needed for block
          BBytes& = BBytes& + LEN(MID$(Array$(N), Bl(1).B, NumCols))
       NEXT
       '----- See if we have enough far memory
       IF ((CLNG(NumRows) * NumCols)) + 50000 > FRE(-1) OR CLNG(NumRows) * NumCols > 65536 THEN
          Ed.MErr = 1                           'Set error flag
          Ed.UlCRow = 0                         'Erase block marking flags
       ELSE
                                                'Save the block to far memory
          REDIM ClipBd((CLNG(NumRows) * NumCols) \ 2 + 1)
          MidStrSave VARPTR(Array$(Ed.UlCRow)), NumRows, Ed.UlCCol, NumCols, ClipBd(0)
          Text2Paste = -1
       END IF
    ELSE                                        'Sentence block
                                                'Save top and bottom lines
       ClipBd1$ = MID$(Array$(Ed.UlCRow), Ed.UlCCol)
       ClipBd2$ = MID$(Array$(Ed.BrCRow), 1, Ed.BrCCol)

       NumRows = NumRows - 2                    'Calc number of rows
                                                'Init. bytes needed for block
       BBytes& = LEN(ClipBd1$) + LEN(ClipBd2$)
       Text2Paste = -1
       IF NumRows > 0 THEN                      'Calc bytes needed by rest of
          FOR N = Bl(0).B TO Bl(2).B            '  block
             BBytes& = BBytes& + LEN(Array$(N))
          NEXT
          '----- See if we have enough far memory
          Temp& = StringSize&(VARPTR(Array$(Ed.UlCRow + 1)), NumRows)
          IF Temp& + 40000 > FRE(-1) THEN
             BEEP
             Ed.MErr = 1                        'Set error flag
             Ed.UlCRow = 0                      'Erase block marking flags
             Text2Paste = 0
          ELSE
                                                'Save the block to far memory
             REDIM ClipBd(Temp& \ 2 + (Temp& MOD 2))
             StringSave VARPTR(Array$(Ed.UlCRow + 1)), ClipBd(0), NumRows
          END IF
       ELSE
          REDIM ClipBd(0)
       END IF
    END IF

    Ed.Text2Paste = Text2Paste

END SUB

SUB QECheckBlockOps (X$, Array$(), Ed AS EditInfo)

    SHARED MarkBlock, FrstBlkKey, BlkRow, BlkCol, SaveT, SaveC, ColBlock
    SHARED BBytes&, RePrint, MouseKey$, Text2Paste
    SHARED Bl() AS BlkCoords

    KeyLen = LEN(X$)

    '----- If they pressed a shift cursor key,
    IF ShiftKey THEN
       IF NumLock THEN
          IF KeyLen = 2 AND INSTR(NumPad2$, RIGHT$(X$, 1)) THEN HiLite = -1
       ELSE
          IF (KeyLen = 1 AND INSTR(NumPad$, X$)) OR (KeyLen = 2 AND INSTR(NumPad2$, RIGHT$(X$, 1))) THEN HiLite = -1
       END IF
    END IF

    IF HiLite THEN
       IF NOT MarkBlock THEN                    'If it's a new block
          FrstBlkKey = -1                       'Set first key flag
          BlkRow = Ed.CurLine                   'Save upper left coordinates
          BlkCol = Ed.CurCol
          SaveT = Ed.TL                         'Save window coordinates
          SaveC = Ed.LC
          MarkBlock = FrstBlkKey                'Set block marking flag
          Ed.WasMarked = FrstBlkKey
       END IF

       '----- Reset the key codes to their un-shifted states for
       '      normal key processing
       SELECT CASE ASCII(X$)
          CASE 49                               '1/End Key
             X$ = CHR$(0) + CHR$(79)
          CASE 50                               '2/Down Key
             X$ = CHR$(0) + CHR$(80)
          CASE 51                               '3/PgDn Key
             X$ = CHR$(0) + CHR$(81)
          CASE 52                               '4/Left Key
             X$ = CHR$(0) + CHR$(75)
          CASE 54                               '6/Right Key
             X$ = CHR$(0) + CHR$(77)
          CASE 55                               '7/Home Key
             X$ = CHR$(0) + CHR$(71)
          CASE 56                               '8/Up Key
             X$ = CHR$(0) + CHR$(72)
          CASE 57                               '9/PgUp Key
             X$ = CHR$(0) + CHR$(73)
          CASE ELSE
       END SELECT

    '----- If a block is marked and they didn't press a shifted cursor
    '----- key or they pressed "Ctrl Y", capture the Block to the
    '----- Clipboard array
    ELSEIF MarkBlock OR ASCII(X$) = 25 OR Ed.DelBlock OR Ed.CopyBlock THEN
       Ky = ASCII(RIGHT$(X$, 1))
       IF KeyLen = 2 THEN Ky = -Ky

       IF Ky = 25 THEN                          'If they pressed "Ctrl Y",
          Bl(0).B = Ed.CurLine                  '  save current line coords.
          Bl(1).B = 1
          Bl(2).B = Ed.CurLine
          Bl(3).B = LEN(Array$(Ed.CurLine))
          ColBlock = -1                         'Not a column block.
       END IF

       Ed.UlCRow = Bl(0).B                      'Save top and bottom block
       Ed.UlCCol = Bl(1).B                      '  coordinates.
       Ed.BrCRow = Bl(2).B
       Ed.BrCCol = Bl(3).B

       '----- BC7ONLY - If you are not using BASIC 7+, rem out the following
       '----- two lines and unrem the next two.
       OK = Ky = -146 OR Ky = -83 OR (ShiftKey AND Ky = 46)
       OK = OK OR Ky = 25 OR Ed.DelBlock OR Ed.CopyBlock

       'OK = Ed.DelBlock OR KeyLen <> 0          'If key not Escape or F1-Help
       'OK = OK AND Ky <> 27 AND Ky <> -59 AND Ky <> -3

       IF OK THEN
          Ed.CBlock = ColBlock                  'Save block type (mode) flag

          IF Ky <> -83 OR (ShiftKey AND Ky = -83) OR Ed.DelBlock < -1 OR Ed.CopyBlock THEN



             QECaptureBlock Array$(), Ed
          END IF

          IF Ed.MErr THEN
             MarkBlock = 0
             X$ = ""                            'Erase key so nothing more
             Ky = 0
             KeyLen = 0
          END IF

          '----- Delete block if they pressed "Shift Del" or just "Del"
          IF Ed.DelBlock OR (ShiftKey AND Ky = 46) OR Ky = -83 THEN

             QEDeleteBlock Array$(), Ed

             X$ = CHR$(0) + CHR$(1)             'Clear key press
             Ky = -1
             KeyLen = 2
             Ed.Changed = -1
          END IF
          RePrint = -1                          'Set to reprint window

       ELSEIF Ky = 27 THEN                      'User pressed Esc so clear it
          X$ = CHR$(0) + CHR$(1)
          Ky = -1
          KeyLen = 2
       END IF
                                                'If User didn't press help,
                                                '  clear block marking flag
       IF Ky <> -59 AND Ky <> -3 AND KeyLen <> 0 THEN
          MarkBlock = 0
       END IF

    '----- Shift Insert (Insert Clipboard contents)
    ELSEIF Ed.InsBlock OR (ShiftKey AND (X$ = "0" OR X$ = CHR$(0) + CHR$(82))) THEN
       IF Text2Paste THEN
          Ed.InsBlock = 0
          X& = FRE("")                          'If a block has been marked
                                                '  and there is enough string
                                                '  memory
          IF Ed.UlCRow AND BBytes& < X& - 1280 THEN

             IF Ed.CBlock THEN                  'If its a column block,
                QEPasteColBlock Array$(), Ed
             ELSE                               'Sentence block mode
                QEPasteSentBlock Array$(), Ed
             END IF

             RePrint = -1                       'Set flag to re-print window
             Ed.Changed = -1                    'Text has been changed

          ELSEIF BBytes& >= X& - 1280 THEN      'Wasn't enough string memory
             BEEP
             Ed.MErr = 1                        'Set error flag
          END IF
       END IF
       X$ = CHR$(0) + CHR$(1)                   'Clear key press

    END IF

END SUB

SUB QECheckMouseOps (Array$(), Ed AS EditInfo, X$) STATIC

    SHARED NPixLines, LMRow, LMCol, WasPressed, MouseAct, ScrRows, MouseThere

    MouseThere = -1                      'Mouse code is here
                                                
    ButtonPress 1, Temp, Ed.Presses, X, Y       'Check for button presses

    '----- If User pressed a button
    IF Ed.Presses OR Temp THEN
       IF Ed.Presses = 0 THEN GetCursor X, Y, Temp
       Ed.MRow = (Y \ NPixLines) + 1            'Convert X, Y to Row and Col.
       Ed.MCol = (X \ 8) + 1

       '----- If Button just pressed
       IF Ed.Presses THEN

          QEMousePress X$, Ed

       '----- Button is DOWN but not just pressed
       ELSE

          QEMouseDrag X$, Array$(), Ed
       END IF

       LMRow = Ed.MRow                          'Remember were we were so we
       LMCol = Ed.MCol                          '  can detect movement.

    '----- No Mouse activity
    ELSEIF WasPressed THEN
       MouseAct = 0

       '----- Un-restrict Mouse cursor if button let go
       MouseTrap 1, 1, ScrRows, 80

       LMRow = -1
       LMCol = -1
       WasPressed = 0
    END IF


END SUB

'********************************************************************
'Checks the current cursor location to see if the window boundaries
'need to be updated.  If they do, the global flag "RePrint" is set
'to true (-1) and the window boundaries are updated.
'********************************************************************
'
SUB QECheckWindowLimits (Ed AS EditInfo) STATIC

    SHARED RePrint

    '----- Check the cursor column position
    IF Ed.CurCol >= Ed.LC + Ed.Wide THEN
       Ed.LC = Ed.CurCol - Ed.Wide + 1
       RePrint = -1
    ELSEIF Ed.CurCol < Ed.LC THEN
       Ed.LC = MaxInt(1, Ed.CurCol - Ed.Wide)
       RePrint = -1
    END IF

    '----- Check the cursor row
    IF Ed.CurLine >= Ed.TL + Ed.Rows THEN
       Ed.TL = Ed.CurLine - Ed.Rows + 1
       RePrint = -1
    ELSEIF Ed.CurLine < Ed.TL THEN
       Ed.TL = Ed.CurLine
       RePrint = -1
    END IF

END SUB

SUB QECtrlLeft (Array$(), Ed AS EditInfo)

    SHARED ColBlock

    DO                                          'Already at the left margin?
       IF Ed.CurCol = 1 AND Ed.CurLine > 1 THEN
          Ed.CurLine = Ed.CurLine - 1           'Move down a line and goto end
          Ed.CurCol = MaxInt(LEN(Array$(Ed.CurLine)), 1)
          ColBlock = 0
       END IF

       X = -1                                   'Find the next word
       DO WHILE Ed.CurCol > 1
          Ed.CurCol = Ed.CurCol - 1
          IF X THEN                             'Find beginning of word first
             IF INSTR(SkipTbl$, MID$(Array$(Ed.CurLine), Ed.CurCol, 1)) = 0 THEN
                X = 0
             END IF
          ELSE                                  'Now look for a space
             IF INSTR(SkipTbl$, MID$(Array$(Ed.CurLine), Ed.CurCol, 1)) THEN
                Ed.CurCol = Ed.CurCol + 1
                EXIT DO
             END IF
          END IF
       LOOP
    LOOP WHILE Ed.CurLine > 1 AND INSTR(SkipTbl$, MID$(Array$(Ed.CurLine), Ed.CurCol, 1))

    QECheckWindowLimits Ed                      'If off left of window, adjust

END SUB

SUB QECtrlPgDn (Array$(), Ed AS EditInfo)

    SHARED RePrint, ArrayEnd

    IF Ed.TL <= ArrayEnd - Ed.Rows THEN         'If we're not already there
       IF Ed.LCount > 0 THEN                    'empty file?   go to the top
                                                'Cursor past the end, but see
          IF Ed.CurLine > Ed.LCount THEN        '  exactly where we are
             X = Ed.CurLine - Ed.LCount
                                                'Last line showing on screen
             IF X < Ed.Rows AND Ed.TL <= Ed.LCount THEN
                                                '  make that the current line
                Ed.CurLine = Ed.LCount
                LOCATE CSRLIN - X               '  and put the cursor there
             END IF                             '  too
          END IF

          Ed.CurLine = Ed.LCount                'Make the last line current
          X = Ed.CurLine - Ed.TL                'See where cursor is relative
                                                '  to end
                                                'Last line is on the screen,
          IF X <= 0 OR X >= Ed.Rows THEN
                                                '  don't re-display, just move
                                                'establish top line to display
             Ed.TL = Ed.CurLine - (Ed.Rows - 1)
                                                'Can't have negative line #
             Ed.TL = MaxInt%(Ed.TL, 1)
             RePrint = -1                       'Set flag to re-print window
          END IF
                                                'Locate at end of line
          Ed.CurCol = LEN(Array$(Ed.CurLine)) + 1
          IF Ed.CurCol < Ed.LC THEN
             Ed.LC = MaxInt(1, Ed.CurCol - Ed.Wide + 1)
             RePrint = -1
          ELSEIF Ed.CurCol > Ed.LC + Ed.Wide - 1 THEN
             Ed.LC = Ed.CurCol - Ed.Wide + 1
             RePrint = -1
          END IF

       END IF
    END IF

END SUB

SUB QECtrlRight (Array$(), Ed AS EditInfo)

    SHARED ColBlock

    DO
       X = -1
       DO WHILE Ed.CurCol <= LEN(Array$(Ed.CurLine))
          Ed.CurCol = Ed.CurCol + 1             'Increment column position
          IF X THEN
             IF INSTR(SkipTbl$, MID$(Array$(Ed.CurLine), Ed.CurCol, 1)) THEN
                X = 0
             END IF
          ELSE
             IF INSTR(SkipTbl$, MID$(Array$(Ed.CurLine), Ed.CurCol, 1)) = 0 THEN
                EXIT DO
             END IF
          END IF
       LOOP
                                                'If past end of line,
       IF Ed.CurCol > LEN(Array$(Ed.CurLine)) AND Ed.CurLine < Ed.LCount THEN
          Ed.CurCol = 1                         '  Set current column to 1
          Ed.CurLine = Ed.CurLine + 1 'Increment line number
          ColBlock = 0
       ELSE
          EXIT DO
       END IF
    LOOP WHILE INSTR(SkipTbl$, MID$(Array$(Ed.CurLine), Ed.CurCol, 1))

    QECheckWindowLimits Ed                      'If off right of window, adjust

END SUB

'----- Move the cursor down a line
'
SUB QECursorDown (Array$(), Ed AS EditInfo)

    SHARED ArrayEnd

    IF Ed.CurLine >= ArrayEnd THEN Ed.CurLine = ArrayEnd
                                        'if we're at the bottom of the screen
    Temp = (Ed.CurLine - Ed.TL + 1) - Ed.Rows
    IF Temp > 0 THEN
       Ed.TL = Ed.TL + Temp             '  show the top line being one higher,
       X = Ed.TSRow + Ed.Rows - 1
       HideCursor                       'Scroll the window up
       ScrollU Ed.TSRow, Ed.LSCol, X, Ed.LSCol + Ed.Wide - 1, Temp, -1
       FOR N = 1 TO Temp
           QPrintRC MID$(Array$(Ed.CurLine - N + 1), Ed.LC, Ed.Wide), X - N + 1, Ed.LSCol, -1
       NEXT
       ShowCursor
    END IF

END SUB

'********************************************************************
'Checks the cursor location to make sure it stays within the window
'when moving to the left.  If the cursor moves off the left edge of
'the window, the window will be scrolled.
'********************************************************************
'
SUB QECursorLeft (Array$(), Ed AS EditInfo)

    IF Ed.CurCol < 1 THEN Ed.CurCol = 1

    Temp = Ed.LC - Ed.CurCol
    IF Temp > 0 THEN                            'If off the left of screen
       Ed.LC = Ed.LC - Temp                     'Decrement window column
       HideCursor                               'Scroll the window
       ScrollR Ed.TSRow, Ed.LSCol, Ed.TSRow + Ed.Rows - 1, Ed.LSCol + Ed.Wide - 1, Temp, -1
       LOCATE Ed.TSRow, Ed.LSCol                'Reprint the right edge
       APrint0 VARPTR(Array$(Ed.TL)), Ed.Rows, Ed.LC, Temp, -1
       ShowCursor
    END IF

END SUB

'********************************************************************
'Checks the cursor location to make sure it stays within the window
'when moving to the right.  If the cursor moves off the right edge of
'the window, the window will be scrolled.
'********************************************************************
'
SUB QECursorRight (Array$(), Ed AS EditInfo)

    IF Ed.CurCol > 255 THEN Ed.CurCol = 255
                                                
    Temp = (Ed.CurCol - Ed.LC + 1) - Ed.Wide    'If off right of window,
    IF Temp > 0 THEN
       Ed.LC = Ed.LC + Temp                     '  increment window column
       HideCursor                               'Scroll the window
       ScrollL Ed.TSRow, Ed.LSCol, Ed.TSRow + Ed.Rows - 1, Ed.LSCol + Ed.Wide - 1, Temp, -1
                                                'Reprint the left edge
       LOCATE Ed.TSRow, Ed.LSCol + Ed.Wide - Temp
       APrint0 VARPTR(Array$(Ed.TL)), Ed.Rows, Ed.LC + Ed.Wide - Temp, Temp, -1
       ShowCursor
    END IF

END SUB

'----- Move the cursor up a line
'
SUB QECursorUp (Array$(), Ed AS EditInfo)

    IF Ed.CurLine < 1 THEN Ed.CurLine = 1 'ignore if already on first line

    Temp = Ed.TL - Ed.CurLine
    IF Temp > 0 THEN                    'if we're at the top of the screen
       Ed.TL = Ed.TL - Temp             '  show the top line being one less,
       HideCursor                       'Scroll the window Down
       ScrollD Ed.TSRow, Ed.LSCol, Ed.TSRow + Ed.Rows - 1, Ed.LSCol + Ed.Wide - 1, Temp, -1
       FOR N = Temp TO 1 STEP -1
           QPrintRC MID$(Array$(Ed.CurLine + N - 1), Ed.LC, Ed.Wide), Ed.TSRow + N - 1, Ed.LSCol, Ed.AColor
       NEXT
       ShowCursor
    END IF

END SUB

SUB QEDeleteBlock (Array$(), Ed AS EditInfo)

    SHARED SaveT, SaveC, ArrayEnd
    SHARED Bl() AS BlkCoords

    Ed.DelBlock = 0


    IF Ed.BrCRow = Ed.UlCRow THEN
       Array$(Ed.UlCRow) = LEFT$(Array$(Ed.UlCRow), Ed.UlCCol - 1) + MID$(Array$(Ed.BrCRow), Ed.BrCCol + 1)
       IF Ed.Wrap THEN

          IF Ed.UlCRow < Ed.Rows THEN        'PC 11/18/93
            Array$(Ed.UlCRow) = Array$(Ed.UlCRow) + SPACE$(FnSpaces2Pad(Array$(Ed.BrCRow))) + Array$(Ed.UlCRow + 1)
          ELSE
            Array$(Ed.UlCRow) = Array$(Ed.UlCRow) + SPACE$(FnSpaces2Pad(Array$(Ed.BrCRow)))
          END IF
          QEDeleteLine Ed.UlCRow + 1, Ed, Array$()

       END IF
    ELSEIF Ed.CBlock THEN                       'If it's a column block,
                                                '  delete range of each row
       FOR N = Bl(0).B TO Bl(2).B
          Array$(N) = LEFT$(Array$(N), Bl(1).B - 1) + MID$(Array$(N), Bl(3).B + 1)
          Array$(N) = RTRIM$(Array$(N))
       NEXT
    ELSE                                        'Sentence block
       Array$(Bl(0).B) = LEFT$(Array$(Bl(0).B), Bl(1).B - 1) + MID$(Array$(Bl(2).B), Bl(3).B + 1)
       Temp = Bl(0).B + 1                       'Delete range of each row
       FOR N = Bl(0).B + 1 TO Bl(2).B
          QEDeleteLine Temp, Ed, Array$()
       NEXT
    END IF
    Ed.LCount = FindLast%(VARPTR(Array$(ArrayEnd)), ArrayEnd)
    Ed.CurLine = Bl(0).B                        'Re-establish current cursor
    Ed.CurCol = Bl(1).B                         '  and window coordinates.
    Ed.TL = MinInt(SaveT, Ed.CurLine)
    Ed.LC = MinInt(SaveC, Ed.CurCol)
    IF Ed.Wrap THEN                             'If word wrap is on, then
       Lin = QEWrapDown(Ed.CurLine, Array$(), Ed)
       Lin = QEWrapUp(Ed.CurLine, Array$(), Ed)
    END IF

END SUB

SUB QEDeleteKey (Array$(), Ed AS EditInfo)

    SHARED LineBuf$, LineEd, RePrint, ArrayEnd

    IF Ed.CurCol > LEN(Array$(Ed.CurLine)) THEN
       Array$(Ed.CurLine) = Array$(Ed.CurLine) + SPACE$(Ed.CurCol - LEN(Array$(Ed.CurLine)) - 1)

       '----- If not on last line concatenate the next line to this one
       IF Ed.CurLine < ArrayEnd THEN
          Array$(Ed.CurLine) = Array$(Ed.CurLine) + LTRIM$(Array$(Ed.CurLine + 1))
       END IF

       QEDeleteLine Ed.CurLine + 1, Ed, Array$()

       RePrint = -1                             'Set flag to re-print window
       IF Ed.Wrap THEN
          Lin = QEWrapDown(Ed.CurLine, Array$(), Ed)
          Lin = QEWrapUp(Ed.CurLine, Array$(), Ed)
       END IF
    ELSE                                        'Within line, delete current
                                                '  character
       Array$(Ed.CurLine) = LEFT$(Array$(Ed.CurLine), Ed.CurCol - 1) + MID$(Array$(Ed.CurLine), Ed.CurCol + 1)
                                                'Put new text in line buffer
       LSET LineBuf$ = MID$(Array$(Ed.CurLine), Ed.LC)
       IF Ed.Wrap THEN Lin = QEWrapUp(Ed.CurLine, Array$(), Ed)
       LOCATE , Ed.LSCol, 0                     'Print the line buffer
       MQPrint LineBuf$, -1
       
    END IF

    Ed.Changed = -1
    LineEd = -1

END SUB

'**********************************************************************
'Deletes the line "AtLine" from the text array and updates "Ed.LCount"
'to reflect the number of currently active lines in the array.
'**********************************************************************
'
SUB QEDeleteLine (AtLine, Ed AS EditInfo, Array$()) STATIC

    IF AtLine <= Ed.LCount THEN
       IF AtLine < Ed.LCount THEN               'If not off the end,
                                                'Delete the element
          DeleteStr VARPTR(Array$(AtLine)), Ed.LCount - AtLine
       END IF
       Array$(Ed.LCount) = ""                   'Erase the scrolled up line
       Ed.LCount = Ed.LCount - 1                'Update last line number
    END IF

END SUB

'----- Display the current column number on the status line
'
SUB QEDisplayColumn (Ed AS EditInfo) STATIC

    SHARED CurCol$, HorPtr, OldHorPtr

    LOCATE , , 0                                'Turn the cursor off
    RSET CurCol$ = LTRIM$(STR$(Ed.CurCol))      'Put number in temp string
    QPrintRC CurCol$, Ed.TSRow + Ed.Rows, Ed.LSCol + 5, 63

    '----- Update the horizontal scroll bar pointer
    IF Ed.Wrap THEN                             'Calc pointer position
       HorPtr = Ed.Wrap + 1
    ELSE
       HorPtr = 256
    END IF
    HorPtr = MinInt(Ed.CurCol * (Ed.Wide - 10) \ HorPtr, Ed.Wide - 11)

    QPrintRC CHR$(176), Ed.TSRow + Ed.Rows, Ed.LSCol + 9 + OldHorPtr, 112
    QPrintRC CHR$(8), Ed.TSRow + Ed.Rows, Ed.LSCol + 9 + HorPtr, 112
    OldHorPtr = HorPtr                          'Save pointer for next pass

END SUB

'----- Display the current line number on the status line
'
SUB QEDisplayLineNo (Ed AS EditInfo) STATIC

    SHARED CurLine$, VrtPtr, OldVrtPtr

    LOCATE , , 0                                'Turn the cursor off
    RSET CurLine$ = LTRIM$(STR$(Ed.CurLine))    'Put number in temp string
    QPrintRC CurLine$, Ed.TSRow + Ed.Rows, Ed.LSCol, 63

    '----- Update the vertical scroll bar pointer
    IF Ed.LCount >= Ed.Rows THEN                'Calc the Vertical position %
       VrtPtr = MinInt(Ed.CurLine * (Ed.Rows - 3&) \ Ed.LCount, Ed.Rows - 3)
    ELSE
       VrtPtr = 0
    END IF
                                                'Erase old pointer
    QPrintRC CHR$(176), Ed.TSRow + OldVrtPtr + 1, Ed.LSCol + Ed.Wide, 112
                                                'Print the new one
    QPrintRC CHR$(8), Ed.TSRow + VrtPtr + 1, Ed.LSCol + Ed.Wide, 112
    OldVrtPtr = VrtPtr                          'Save old pointer for later

END SUB

SUB QEDisplayWindow (Action, Array$(), Ed AS EditInfo)

    SHARED ArrayEnd, Par$, WrapWas, HiClr, BlkClr, BScan, Insrt
    SHARED Ruler() AS STRING * 260


    '----- Find the last element being used in the text array
    ArrayEnd = UBOUND(Array$)
    Ed.LCount = FindLast%(VARPTR(Array$(ArrayEnd)), ArrayEnd)


    IF Ed.Wrap THEN             'If word wrap is on, use "" paragraph marker
       Par$ = CHR$(20)          '(you could use CHR$(255) for invisable marker)
       Ed.Wrap = MaxInt(MinInt(Ed.Wrap, 255), 10)
    ELSE                        'Otherwise,
       Par$ = ""                '  use a null character
    END IF

    '----- If word wrap is on, format all the text.
    IF Ed.Wrap THEN
       IF WrapWas = 0 THEN WrapWas = Ed.Wrap
       IF Action < 3 THEN
          'Lin = QEWrapDown(Ed.CurLine, Array$(), Ed)
          QEWrapAll 1, Array$(), Ed
       ELSE
          Lin = QEWrapDown(Ed.CurLine, Array$(), Ed)
          Lin = QEWrapUp(Ed.CurLine, Array$(), Ed)
       END IF
       WrapWas = Ed.Wrap
    END IF


    '----- Insert margin markers in ruler line.
    Ruler(1) = Ruler(0)
    IF Ed.Wrap THEN
       MID$(Ruler(1), 2) = CHR$(16)
       MID$(Ruler(1), Ed.Wrap + 1) = CHR$(17)
    END IF

    HiClr = Ed.AColor                           'Determine high intensity Clr
    SplitColor Ed.AColor, X, Temp               'Split color # into Fg & Bg
    IF X < 8 THEN HiClr = Ed.AColor + 8
    IF Ed.AColor = 112 THEN
       BlkClr = 7
    ELSE
       BlkClr = 112
    END IF

    QEInitWindow Ed, Array$()                   'Display the window

                                                'Set the cursor size
    LOCATE , , , BScan \ (1 - (Insrt = -1)) - 1, BScan


END SUB

'****************************************************************************
'  Title: QEdit - Full featured text editing sub-program
'     by: Don Malin  10/21/88
'
'Purpose: Displays a word processing window and allows the user to edit text.
'         Horizontal and vertical scrolling can be used to edit a string
'         array passed to the routine.  Margins and word wrap are supported
'         along with full block operations and mouse support.
'
' Syntax: Call QEdit (Arg1$(), Arg2$, Arg3%, Arg4 as EditInfo)
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
'****************************************************************************
'
SUB QEdit (Array$(), X$, Action%, Ed AS EditInfo) STATIC

    SHARED ScrBuf(), Ruler() AS STRING * 260
    SHARED LineBuf$, LastCurLine%, LastCurCol, RePrint, ArrayEnd, LineEd
    SHARED BlocksThere, MarkBlock, ColBlock, BlkClr
    SHARED ScrRows, MouseThere, Insrt, BScan, CtrlP

    Ed.MErr = 0                                 'No errors yet

    '----- Action of 0 or 1 - Initialize and save the underlying screen
    IF Action < 2 THEN
       QEInitialize Ed
    END IF

    '----- Action of 5 - Restore the underlying screen
    IF Action = 5 THEN
       GOSUB CleanUp                            'Restore the screen
       Action = 1                               'Reset action to 1
       EXIT SUB                                 'Bail out
    END IF
   
    '----- Action of 0, 1, 2 - Display the edit window
    IF Action < 3 OR Action = 4 THEN
       QEDisplayWindow Action, Array$(), Ed
    END IF

    

    '----- Main editing (key processing) loop
    DO

        '----- Position the cursor
        LOCATE Ed.TSRow + Ed.CurLine - Ed.TL, Ed.LSCol + (Ed.CurCol - Ed.LC), 1
       
        Ed.UnKnownKey = 0
        LineWas = Ed.CurLine

        '----- Handle regular keys (non extended keys)
        IF LEN(X$) = 1 THEN
    
           SELECT CASE ASC(X$)

              '----- All Non Control Characters (Normal text keys)
              CASE IS >= CtrlP
                 QETextKeys X$, Array$(), Ed
                 CtrlP = 32

              '----- Back Space
              CASE 8
                 QEBackSpace Array$(), Ed
                  
              '----- Enter
              CASE 13
                 QEEnterKey Array$(), Ed

              '----- TAB
              CASE 9
                 QETabKey Array$(), Ed

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
                    MPaintBox X, Ed.LSCol, X, Ed.LSCol + Ed.Wide - 1, BlkClr

                                                'Delete the current line
                    QEDeleteLine Ed.CurLine, Ed, Array$()

                    Pause 1                     'Wait an 1/18 of a second
                    RePrint = -1                'Set flag to re-print window
                    IF Ed.LCount THEN Ed.Changed = -1
                 END IF
            
              '----- Ctrl N - Insert a Line
              CASE 14
                 QEInsertLine "", Ed.CurLine, Ed, Array$()
                 RePrint = -1                   'Set flag to re-print window
                 IF Ed.LCount THEN Ed.Changed = -1

              '----- Ctrl P - Imbed characters
              CASE 16
                 CtrlP = 0
                 LineEd = -1

              CASE ELSE
                 Ed.UnKnownKey = -1

           END SELECT


           IF FRE("") < 1280& THEN
              BEEP
              Ed.MErr = 1                       'Set error flag
           END IF


        '----- Handle Extended (2 Char) key codes
        ELSEIF LEN(X$) = 2 THEN

           SELECT CASE ASCII(RIGHT$(X$, 1))     'Get ASCII value of right 1

              '----- HELP key pressed
              CASE 59
                 QEShowHelp Ed

              '----- Cursor UP
              CASE 72
                 IF PeekBuf = -72 THEN
                    Ed.CurLine = Ed.CurLine - 2
                    X$ = INKEY$
                 ELSE
                    Ed.CurLine = Ed.CurLine - 1
                 END IF
                 QECursorUp Array$(), Ed        'Go do it

              '----- Cursor DOWN
              CASE 80
                 IF PeekBuf = -80 THEN
                    Ed.CurLine = Ed.CurLine + 2
                    X$ = INKEY$
                 ELSE
                    Ed.CurLine = Ed.CurLine + 1
                 END IF
                 QECursorDown Array$(), Ed

              '----- Cursor LEFT
              CASE 75
                 IF Ed.CurCol > 1 THEN
                    IF PeekBuf = -75 THEN
                       Ed.CurCol = Ed.CurCol - 2
                       X$ = INKEY$
                    ELSE
                       Ed.CurCol = Ed.CurCol - 1
                    END IF
                    QECursorLeft Array$(), Ed
                                                'Are we in word wrap mode?
                 ELSEIF Ed.Wrap AND Ed.CurLine > 1 THEN
                    Ed.CurCol = Ed.Wrap         'Set column to right margin
                    Ed.LC = MaxInt%(Ed.Wrap - Ed.Wide + 1, 1)
                    Ed.CurLine = Ed.CurLine - 1
                    QECursorUp Array$(), Ed
                    RePrint = -1
                    ColBlock = 0
                 END IF

              '----- Cursor RIGHT
              CASE 77
                 IF Ed.CurCol < 256 THEN
                    IF PeekBuf = -77 THEN
                       Ed.CurCol = Ed.CurCol + 2
                       X$ = INKEY$
                    ELSE
                       Ed.CurCol = Ed.CurCol + 1
                    END IF
                    QECursorRight Array$(), Ed
                                                'If at right margin
                    IF Ed.Wrap AND Ed.CurCol > Ed.Wrap THEN
                       Ed.CurCol = 1            'Set current column to 1
                       Ed.LC = 1                'Set window column to 1
                       Ed.CurLine = Ed.CurLine + 1
                       QECursorDown Array$(), Ed
                       RePrint = -1
                       ColBlock = 0
                    END IF
                 END IF

              '----- Ctrl LEFT - move one word left
              CASE 115
                 QECtrlLeft Array$(), Ed

              '----- Ctrl RIGHT - move one word right
              CASE 116
                 QECtrlRight Array$(), Ed

              '----- Cursor HOME
              CASE 71                           'Starting at column 1
                 X = Blanks%(Array$(Ed.CurLine)) + 1
                 IF X = Ed.CurCol THEN X = 1
                 Ed.CurCol = X
                 QECheckWindowLimits Ed

              '----- Cursor END
              CASE 79                           'Set current column to end +
                 Ed.CurCol = LEN(Array$(Ed.CurLine)) + 1
                 QECheckWindowLimits Ed

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
              CASE 118
                 QECtrlPgDn Array$(), Ed

              '----- Togle INSERT mode
              CASE 82
                 Insrt = Insrt * -1             'toggle insert on and off
                                                'set cursor size accordingly
                 LOCATE , , , BScan \ (1 - (Insrt = -1)) - 1, BScan

              '----- Delete
              CASE 83
                 QEDeleteKey Array$(), Ed
                  
              '----- Back TAB
              CASE 15                           'Calc spaces to next stop
                 QEBackTab Array$(), Ed
               
              CASE ELSE                         'Ignor all other keys
                 Ed.UnKnownKey = -1

           END SELECT
        END IF

       
        '----- Trim the line if it was edited.
        IF LineEd AND Ed.CurLine <> LineWas THEN
           Array$(LineWas) = RTRIM$(Array$(LineWas))
           LineEd = 0
        END IF


        '----- Re-display the window if flag set or block marking complete
        IF RePrint OR (Ed.WasMarked AND MarkBlock = 0) THEN
           LOCATE Ed.TSRow, Ed.LSCol, 0         'APrint the screen
           HideCursor                           'Turn Mouse cursor off
           APrint0 VARPTR(Array$(Ed.TL)), Ed.Rows, Ed.LC, Ed.Wide, Ed.AColor
           ShowCursor                           'Turn mouse cursor back on
           RePrint = 0                          'Turn Flag off
           IF MarkBlock = 0 THEN Ed.WasMarked = 0  'Turn hiliting off
        END IF
     

        '----- Update the window frame displays
        IF Ed.Frame THEN
                                                'If line number has changed,
           IF Ed.CurLine <> LastCurLine OR RePrint THEN
              QEDisplayLineNo Ed                '  display line # on status
              LastCurLine = Ed.CurLine          'Save line number
           END IF
                                                'If column number has changed,
           IF Ed.CurCol <> LastCurCol OR RePrint THEN
              QEDisplayColumn Ed                '  display col. # on status
              LastCurCol = Ed.CurCol            'Save column number
           END IF

           IF Ed.LC <> LastC THEN               'If window column has changed,
              LOCATE Ed.TSRow - 1, Ed.LSCol, 0
              MQPrint MID$(Ruler(1), Ed.LC + 1, Ed.Wide), 112
              LastC = Ed.LC                     'Save window column
           END IF
        END IF

       
        '----- Position the cursor
        LOCATE Ed.TSRow + Ed.CurLine - Ed.TL, Ed.LSCol + (Ed.CurCol - Ed.LC), 1
        

        '----- If in block marking mode, paint the marked block
        BlocksThere = -1
        IF MarkBlock AND LEN(X$) THEN
           QEPaintBlock Ed
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

           QECheckMouseOps Array$(), Ed, X$

        LOOP UNTIL LEN(X$) OR Action <> 0

        '----- Check for Block operation keys
        IF LEN(X$) OR Ed.DelBlock OR Ed.CopyBlock OR Ed.InsBlock THEN
           QECheckBlockOps X$, Array$(), Ed
        END IF

    LOOP WHILE Action = 0                       'Go back for another key if
                                                '  not in polling mode.

    Ed.InsStat = Insrt                          'Show the caller the Insert
                                                '  state

    EXIT SUB                                    'Bail out



'----- Restore the screen and free up memory
CleanUp:
    MScrnRest 1, 1, ScrRows, 80, ScrBuf(1)      'Restore the screen
    ERASE ScrBuf, Ruler                         'Clean up memory
    LineBuf$ = ""
    LOCATE , , , BScan - 1, BScan
RETURN



END SUB          'Thats all folks.  And you thought editing was easy?

SUB QEEnterKey (Array$(), Ed AS EditInfo)

    SHARED RePrint, Insrt, ArrayEnd, LineEd

    IF Ed.CurLine < ArrayEnd THEN

       X = Blanks(Array$(Ed.CurLine)) + 1
                                                'If in Insert mode, insert a
       IF Insrt = -1 THEN
                                                '  new line below.
          IF Ed.LCount < ArrayEnd THEN
             'Ed.LCount = Ed.LCount + 1
                                                'New line is right of cursor
             Temp$ = SPACE$(MinInt(X, Ed.CurCol) - 1) + RTRIM$(MID$(Array$(Ed.CurLine), Ed.CurCol))
             QEInsertLine Temp$, Ed.CurLine + 1, Ed, Array$()
                                                'Current line is left of
                                                '  cursor & paragraph marker
             Array$(Ed.CurLine) = RTRIM$(LEFT$(Array$(Ed.CurLine), Ed.CurCol - 1))
             
             Ed.Changed = -1
             LineEd = Ed.Changed
          END IF
       END IF

       IF X > 1 OR LEN(Array$(Ed.CurLine)) THEN Ed.CurCol = X
       Ed.CurLine = MinInt%(Ed.CurLine + 1, ArrayEnd)
       QECheckWindowLimits Ed

       'IF Ed.Wrap THEN                         'Wrap words up
       '   Lin = QEWrapUp(ED.CurLine, Array$(), ED)
       'END IF
       RePrint = -1                             'Set flag to re-print window
    END IF

END SUB

SUB QEInitialize (Ed AS EditInfo)

    SHARED WrapWas, TMarg, BMarg, Insrt, CtrlP, CurLine$, CurCol$, MouseKey$
    SHARED MouseKey2$, MouseThere, BlocksThere, BScan, NPixLines
    SHARED ScrRows
    SHARED WC(), ScrBuf(), Ruler() AS STRING * 260


    WrapWas = Ed.Wrap
    Ed.HTab = MaxInt(Ed.HTab, 1)                'Horizontal Tab spaces
    TMarg = 1
    BMarg = 1
    Insrt = Ed.InsStat
    IF Insrt = 0 THEN Insrt = -1                'Insert mode set to ON
                                                'make 1 to default to OT
    CtrlP = 32

    CurLine$ = SPACE$(4)                        'Used to display Cursor Pos.
    CurCol$ = SPACE$(3)

    MouseKey$ = CHR$(0) + CHR$(3)               'Dummy key for mouse actions
    MouseKey2$ = CHR$(0) + CHR$(4)

    '----- Compose the Ruler line string
    REDIM Ruler(0 TO 1) AS STRING * 260         'Put it out in far memory

    FOR N = 0 TO 250 STEP 10                    'Compose Ruler line
       MID$(Ruler(0), N + 1) = LTRIM$(STR$(N MOD 100))
       FOR X = 1 TO 9
          IF X = 5 THEN
             MID$(Ruler(0), N + X + 1) = "Å"
          ELSE
             MID$(Ruler(0), N + X + 1) = "Â"
          END IF
       NEXT
    NEXT


    MouseThere = 0                              'Assume Mouse code absent
    BlocksThere = 0                             'Assume Block code absent


    '----- Determine bottom cursor scan line.
    SELECT CASE Monitor%                        'Determine the monitor type
       CASE 3, 5, 10                            'CGA, EGA monitors
          BScan = 7                             'Set bottom scan line
       CASE ELSE                                'All other monitors
          BScan = 12
    END SELECT
    LOCATE , , 0, BScan - 1, BScan

    NPixLines = 8
    GetVMode 0, 0, 0, ScrRows, 80               'Get current line mode
                                                'Fix for OS2 DOS
    IF ScrRows = 50 AND DOSVer = 1000 THEN NPixLines = 7

    Ed.TSRow = CSRLIN - (Ed.Frame <> 0)         'Calc the top line of window
    Ed.LSCol = POS(0) - (Ed.Frame <> 0)         'Calc Left margin of window
                                                'Both are to inside of frame
    Ed.Rows = MinInt(MaxInt(Ed.Rows, 3), (ScrRows + ((Ed.Frame <> 0) * 2)) - CSRLIN + 1)
    Ed.Wide = MinInt(MaxInt(Ed.Wide, 11), (80 + ((Ed.Frame <> 0) * 2)) - POS(0) + 1)

    '----- Save current window coordinates for later resizing
    WC(0, 1) = Ed.TSRow + (Ed.Frame <> 0)       'Top line
    WC(1, 1) = Ed.LSCol + (Ed.Frame <> 0)       'Left margin
    WC(2, 1) = WC(0, 1) + Ed.Rows + (2 * (Ed.Frame <> 0)) - 1'Bottom line of window
    WC(3, 1) = WC(1, 1) + Ed.Wide + (2 * (Ed.Frame <> 0)) - 1'Right margin of window

    '----- Dim array to hold the underlying screen and save it.
    REDIM ScrBuf(1 TO (ScrRows * 80) + 2)
    MScrnSave 1, 1, ScrRows, 80, ScrBuf(1)

    IF Ed.LC <= 0 THEN Ed.LC = 1                'Set window column to 1
    IF Ed.CurCol <= 0 THEN Ed.CurCol = 1        'establish cursor column at 1
    IF Ed.TL <= 0 THEN Ed.TL = 1                'Top of window row number
    IF Ed.CurLine <= 0 THEN Ed.CurLine = 1      'make top line the cursor col.
    QECheckWindowLimits Ed

END SUB

'----- Resize and Draw the window frame
'
SUB QEInitWindow (Ed AS EditInfo, Array$())

    SHARED WC%(), ScrBuf%(), LineBuf$, HiClr%, Ruler() AS STRING * 260
    SHARED LastCurLine%, LastCurCol%, OldVrtPtr%, OldHorPtr%, RePrint%
    SHARED ArrayEnd

    '----- Calculate the bounds of the window
    ReDo = 0
    DO
       WC(0, 0) = Ed.TSRow + (Ed.Frame <> 0)       'Top line of window

       WC(1, 0) = Ed.LSCol + (Ed.Frame <> 0)       'Left margin of window
                                                   'Bottom line of window
       WC(2, 0) = WC(0, 0) + Ed.Rows - (2 * (Ed.Frame <> 0)) - 1
                                                   'Right margin of window
       WC(3, 0) = WC(1, 0) + Ed.Wide - (2 * (Ed.Frame <> 0)) - 1

       IF WC(0, 0) < WC(0, 1) OR WC(2, 0) > WC(2, 1) THEN
          IF Ed.TL + Ed.Rows - 1 > ArrayEnd THEN
             Ed.TL = ArrayEnd - Ed.Rows + 1
             IF Ed.TL < 1 THEN
                Ed.TL = 1
                Ed.Rows = Ed.TSRow + ArrayEnd - 1
                ReDo = -1
             END IF
          END IF
       END IF

    LOOP WHILE ReDo


    'Did the Lower Right corner move Up?
    IF WC(2, 0) < WC(2, 1) THEN                 'Restore slice
       MPRestore WC(2, 0) + 1, WC(1, 1), WC(2, 1), WC(3, 1), 80, ScrBuf((WC(2, 0) * 80) + WC(1, 1))
    END IF

    'Did the Lower Right corner move Left?
    IF WC(3, 0) < WC(3, 1) THEN                 'Restore slice
       MPRestore WC(0, 1), WC(3, 0) + 1, WC(2, 1), WC(3, 1), 80, ScrBuf((WC(0, 1) - 1) * 80 + WC(3, 0) + 1)
    END IF

    'Did the Upper Left corner move Down?
    IF WC(0, 0) > WC(0, 1) THEN                 'Restore slice
       MPRestore WC(0, 1), WC(1, 1), WC(0, 0) - 1, WC(3, 1), 80, ScrBuf((WC(0, 1) - 1) * 80 + WC(1, 1))
    END IF

    'Did the Upper Left corner move Right?
    IF WC(1, 0) > WC(1, 1) THEN                 'Restore slice
       MPRestore WC(0, 1), WC(1, 1), WC(2, 1), WC(1, 0) - 1, 80, ScrBuf((WC(0, 1) - 1) * 80 + WC(1, 1))
    END IF


    WC(0, 1) = WC(0, 0)
    WC(1, 1) = WC(1, 0)                         'Save new bounds for next time
    WC(2, 1) = WC(2, 0)
    WC(3, 1) = WC(3, 0)

    LineBuf$ = SPACE$(Ed.Wide)                  'Temp buffer used for printing


    '----- If Frame flag set, draw the frame and scroll bars
    IF Ed.Frame THEN
       HideCursor                               'Shut the mouse cursor off
       '----- Print the top line
       QPrintRC CHR$(4), Ed.TSRow - 1, Ed.LSCol - 1, HiClr
       QPrintRC MID$(Ruler(1), Ed.LC + 1, Ed.Wide), Ed.TSRow - 1, Ed.LSCol, 112
       QPrintRC CHR$(18), Ed.TSRow - 1, WC(3, 0), HiClr
       '----- Print the middle lines
       X = Ed.TL
       FOR N = Ed.TSRow TO Ed.TSRow + Ed.Rows - 1

           QPrintRC "³", N, Ed.LSCol - 1, HiClr
     '      LSET LineBuf$ = MID$(Array$(X), Ed.LC)
     '      X = X + 1
     '      QPrintRC LineBuf$, N, Ed.LSCol, Ed.AColor

           QPrintRC "°", N, WC(3, 0), 112
       NEXT
       '----- Print the up and down arrows
       QPrintRC CHR$(30), Ed.TSRow, WC(3, 0), 112
       QPrintRC CHR$(31), N - 1, WC(3, 0), 112
       '----- Print the status spaces on bottom of window
       QPrintRC "À", Ed.TSRow + Ed.Rows, Ed.LSCol - 1, HiClr
       QPrintRC ":", Ed.TSRow + Ed.Rows, Ed.LSCol + 4, 48
       '----- Print the horizontal scroll bar
       QPrintRC CHR$(17) + STRING$(Ed.Wide - 10, "°") + CHR$(16), Ed.TSRow + Ed.Rows, Ed.LSCol + 8, 112
       QPrintRC CHR$(4), Ed.TSRow + Ed.Rows, WC(3, 0), HiClr

       ShowCursor                               'Turn the mouse cursor back on
       LastCurLine = 0                          'Save cursor location so we
       LastCurCol = 0                           '  know when to reprint status
    END IF

    RePrint = -1                                'Set flag to print the window
                                                'Make sure the cursor stays in
                                                '  the window
    Ed.CurLine = MinInt(Ed.CurLine, Ed.TL + Ed.Rows - 1)
    Ed.CurCol = MinInt(Ed.CurCol, Ed.LC + Ed.Wide - 1)
    OldVrtPtr = 0                               'Init scroll pointers
    OldHorPtr = 0

END SUB

'*************************************************************************
'Insert an element into the text array at "AtLine" and updates "Ed.LCount"
'to reflect the number of currently active lines in the array.
'*************************************************************************
'
SUB QEInsertLine (NewLine$, AtLine, Ed AS EditInfo, Array$()) STATIC

    SHARED ArrayEnd

    IF AtLine <= Ed.LCount THEN                 'If within the active part of
                                                '  the array, increment the
                                                '  number of active lines
       Ed.LCount = MinInt%(Ed.LCount + 1, ArrayEnd)
                                                'Insert the new element
       InsertStr VARPTR(Array$(AtLine)), NewLine$, Ed.LCount - AtLine
    ELSE                                        'Otherwise
       Ed.LCount = AtLine                       'Extend the # of active lines
       Array$(AtLine) = NewLine$                'Assign the new element.
    END IF

END SUB

SUB QEMouseDrag (X$, Array$(), Ed AS EditInfo) STATIC

    SHARED MouseAct, MouseKey$, LMRow, LMCol, TMarg, BMarg
    SHARED RePrint, WC%(), ScrRows, Ruler() AS STRING * 260, Delay, ArrayEnd
    SHARED MarkBlock, FrstBlkKey, VrtPtr, HorPtr

    '----- DRAG actions
    SELECT CASE MouseAct

       '----- BLOCK marking operations
       CASE 1
          '----- Has the mouse been moved?
          IF Ed.MRow <> LMRow OR Ed.MCol <> LMCol THEN
             IF NOT MarkBlock THEN              'Beginning of block?

                FrstBlkKey = -1                 'Set first key flag
                MarkBlock = -1                  'Set block marking flags
                Ed.WasMarked = -1
             END IF
                                                'Set cursors new location
             Ed.CurLine = MinInt(Ed.TL + Ed.Rows - 1, MaxInt(Ed.TL, Ed.MRow - Ed.TSRow + Ed.TL))
             Ed.CurCol = MinInt(Ed.LC + Ed.Wide - 1, MaxInt(Ed.LC, Ed.MCol - Ed.LSCol + Ed.LC))
             X$ = MouseKey$                     'Make dummy key so we fall out
          END IF

          '----- On TOP of frame?  Scroll UP
          IF Ed.MRow = Ed.TSRow - 1 THEN
                                                'Check timer
             IF PDQTimer& <> LMTime& THEN
                Ed.CurLine = Ed.TL - 1          'Set cursor to top of window
                QECursorUp Array$(), Ed
                X$ = MouseKey$                  'Make dummy key
                LMTime& = PDQTimer&             'Reset timer for delay
             END IF
          END IF

          '----- On BOTTOM of frame?  Scroll DOWN
          IF Ed.MRow = Ed.TSRow + Ed.Rows THEN
                                                'Check timer
             IF PDQTimer& <> LMTime& THEN
                Ed.CurLine = Ed.TL + Ed.Rows
                QECursorDown Array$(), Ed
                X$ = MouseKey$                  'Make dummy key
                LMTime& = PDQTimer&             'Reset timer for delay
             END IF
          END IF

          '----- On RIGHT side of frame?  Scroll right
          IF Ed.MCol = Ed.LSCol + Ed.Wide THEN
                                                'Check timer
             IF PDQTimer& <> LMTime& THEN
                Ed.CurCol = Ed.LC + Ed.Wide
                QECursorRight Array$(), Ed
                X$ = MouseKey$                  'Make dummy key
                LMTime& = PDQTimer&             'Reset timer for delay
             END IF
          END IF

          '----- On LEFT side of frame?  Scroll left
          IF Ed.MCol = Ed.LSCol - 1 THEN
                                                'Cursor to left of window
                                                'Check timer
             IF PDQTimer& <> LMTime& THEN
                Ed.CurCol = Ed.LC - 1           'Decrement current column
                QECursorLeft Array$(), Ed
                X$ = MouseKey$                  'Make dummy key
                LMTime& = PDQTimer&             'Reset timer for delay
             END IF
          END IF

       '----- Vertical Scroll Pointer operations
       CASE 2
          IF Ed.MRow <> LMRow THEN              'If the mouse moved
                                                'Calc. % of bar and set line
             Ed.CurLine = ((Ed.MRow - Ed.TSRow - 1&) * Ed.LCount) \ (Ed.Rows - 3) + 1
             Ed.CurLine = MinInt(Ed.CurLine, Ed.LCount)
             IF Ed.MRow > LMRow THEN            'Set top of window
                Ed.TL = MaxInt(MinInt(MaxInt(Ed.TL, Ed.CurLine), Ed.LCount - Ed.Rows + 2), 1)
             ELSE
                Ed.TL = MaxInt(MinInt(Ed.TL, Ed.CurLine - Ed.Rows + 1), 1)
             END IF
             X$ = MouseKey$                     'Make dummy key
             RePrint = -1                       'Set flag to reprint
          END IF                                '  window

       '----- Horizontal Scroll Pointer operations
       CASE 3
          IF Ed.MCol <> LMCol THEN              'If the mouse moved
             IF Ed.Wrap THEN                    'If word wrap is on,
                X = Ed.Wrap + 1                 '  use right margin as width
             ELSE
                X = 256                         '  otherwise use 256
             END IF
                                                'Set column to %
             Ed.CurCol = ((Ed.MCol - Ed.LSCol - 9) * X) \ (Ed.Wide - 10) + 1
             IF Ed.MCol > LMCol THEN            'Set left column
                Ed.LC = MaxInt(MinInt(MaxInt(Ed.LC, Ed.CurCol), X - Ed.Wide), 1)
             ELSE
                Ed.LC = MaxInt(MinInt(Ed.LC, Ed.CurCol - Ed.Wide + 1), 1)
             END IF

             X$ = MouseKey$                     'Make dummy key
             RePrint = -1                       'Set flag to reprint window
          END IF

       '----- Lower Right Corner operations (ReSize window)
       CASE 4                                   'If the mouse has moved
          IF Ed.MRow <> LMRow OR Ed.MCol <> LMCol THEN
                                                'Calc new location and size
             Ed.Wide = MaxInt(Ed.MCol - Ed.LSCol, 11)
             Ed.LSCol = MaxInt(Ed.MCol - Ed.Wide, 2)

             Ed.Rows = MaxInt(Ed.MRow - Ed.TSRow, 3)
             Ed.TSRow = MaxInt(Ed.MRow - Ed.Rows, TMarg + 2)

                                                'Redraw window
             QEInitWindow Ed, Array$()
             X$ = MouseKey$                     'Make dummy key
          END IF

       '----- Upper Left Corner operations (ReSize window)
       CASE 5                                   'If the mouse has moved
          IF Ed.MRow <> LMRow OR Ed.MCol <> LMCol THEN
                                                'Calc new location and size
             WC(3, 0) = Ed.LSCol + Ed.Wide
             WC(2, 0) = Ed.TSRow + Ed.Rows

             Ed.LSCol = MinInt(Ed.MCol + 1, 80 - 11)
             Ed.Wide = MaxInt(WC(3, 0) - Ed.LSCol, 11)

             Ed.TSRow = MinInt(Ed.MRow + 1, ScrRows - BMarg - 3)
             Ed.Rows = MaxInt(WC(2, 0) - Ed.TSRow, 3)

                                                'Redraw window
             QEInitWindow Ed, Array$()
             X$ = MouseKey$                     'Make dummy key
          END IF

       '----- Left boarder operation (Move window)
       CASE 8                                   'If the mouse has moved
          IF Ed.MRow <> LMRow OR Ed.MCol <> LMCol THEN
                                                'Calc new location and size
             Ed.LSCol = Ed.LSCol + Ed.MCol - LMCol
             Ed.TSRow = Ed.TSRow + Ed.MRow - LMRow

                                                'Redraw window
             QEInitWindow Ed, Array$()
             X$ = MouseKey$                     'Make dummy key
          END IF

       '----- Zoom
       CASE 9
          Ed.LSCol = 2
          Ed.Wide = 78

          Ed.TSRow = TMarg + 2
          Ed.Rows = ScrRows - BMarg - Ed.TSRow

                                                'Redraw window
          QEInitWindow Ed, Array$()
          X$ = MouseKey$           'Make dummy key

       '----- Move right margin operations
       CASE 6
          IF Ed.MCol <> LMCol THEN              'If the mouse has moved
             Ruler(1) = Ruler(0)                'Reset the ruler$ to erase
                                                '  the old marker
             MID$(Ruler(1), 2) = CHR$(16)
                                                'Calc the new right margin
             Temp = MaxInt(Ed.MCol - Ed.LSCol + Ed.LC, 10)
                                                'Put margin icon in Ruler$
             MID$(Ruler(1), Temp + 1) = CHR$(17)
             LOCATE Ed.TSRow - 1, Ed.LSCol, 0   '  re-display ruler line
             MQPrint MID$(Ruler(1), Ed.LC + 1, Ed.Wide), 112  'part to print

             DO
                Ed.Wrap = MinInt(Ed.Wrap + 4, Temp)
                QEWrapAll 1, Array$(), Ed
                Ed.CurCol = MinInt(Ed.CurCol, Ed.Wrap)
             LOOP UNTIL Ed.Wrap = Temp

             X$ = MouseKey$                     'Make dummy key
             RePrint = -1                       'Set flag to redisplay text
                                                'Set "Changed" flag
             IF Ed.LCount THEN Ed.Changed = -1
          END IF

       '----- Scroll bar operations (except scroll pointer)
       CASE ELSE

          '----- Wait for delay
          IF (PDQTimer& > LMTime& + Delay OR PDQTimer& < LMTime&) AND Ed.Frame THEN
             IF MouseAct = 7 THEN
                Delay = 6
                MouseAct = 0
             ELSE
                Delay = 1
             END IF
             LMTime& = PDQTimer&

             '----- Vertical scroll bar operations
             IF Ed.MCol = Ed.LSCol + Ed.Wide AND Ed.MRow >= Ed.TSRow AND Ed.MRow < Ed.TSRow + Ed.Rows THEN
                ScrVrtPtr = VrtPtr + Ed.TSRow + 1
                SELECT CASE Ed.MRow

                   '----- On Up Arrow icon
                   CASE IS = Ed.TSRow
                      IF Ed.TL > 1 THEN
                         Ed.TL = Ed.TL - 1
                         Ed.CurLine = MinInt(Ed.CurLine, Ed.TL + Ed.Rows - 1)
                         X$ = MouseKey$
                         RePrint = -1
                      END IF

                   '----- On Down Arrow icon
                   CASE IS = Ed.TSRow + Ed.Rows - 1
                      IF Ed.TL < ArrayEnd - Ed.Rows + 1 THEN
                         Ed.TL = Ed.TL + 1
                         Ed.CurLine = MaxInt(Ed.CurLine, Ed.TL)
                         X$ = MouseKey$
                         RePrint = -1
                      END IF

                   '----- Above Pointer
                   CASE IS < ScrVrtPtr
                      X$ = CHR$(0) + CHR$(73)

                   '----- Below Pointer
                   CASE IS > ScrVrtPtr
                      X$ = CHR$(0) + CHR$(81)

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
                         Ed.CurCol = MinInt(Ed.CurCol, Ed.LC + Ed.Wide - 1)
                         X$ = MouseKey$
                         RePrint = -1
                      END IF

                   '----- On Right Arrow icon
                   CASE IS = Ed.LSCol + Ed.Wide - 1
                      IF Ed.LC < 255 - Ed.Wide + 1 THEN
                         Ed.LC = Ed.LC + 1
                         Ed.CurCol = MaxInt(Ed.CurCol, Ed.LC)
                         X$ = MouseKey$
                         RePrint = -1
                      END IF

                   '----- Left of Pointer
                   CASE IS < ScrHorPtr
                      LMTime& = LMTime& - 1
                      Ed.LC = MaxInt(Ed.LC - Ed.Wide, 1)
                      Ed.CurCol = MaxInt(Ed.CurCol - Ed.Wide, 1)
                      X$ = MouseKey$
                      RePrint = -1

                   '----- Right of Pointer
                   CASE IS > ScrHorPtr
                      LMTime& = LMTime& - 1
                      IF Ed.Wrap THEN
                         Temp = MaxInt(1, Ed.Wrap - Ed.Wide)
                      ELSE
                         Temp = 256 - Ed.Wide
                      END IF
                      Ed.LC = MinInt(Ed.LC + Ed.Wide, Temp)
                      Ed.CurCol = MinInt(Ed.CurCol + Ed.Wide, Temp)
                      X$ = MouseKey$
                      RePrint = -1

                   CASE ELSE
                END SELECT
             END IF
          END IF

    END SELECT

END SUB

SUB QEMousePress (X$, Ed AS EditInfo)

    SHARED MouseAct, Delay, WasPressed
    SHARED MouseKey$, MouseKey2$, MarkBlock, BlkRow, BlkCol, SaveT, SaveC
    SHARED OldVrtPtr, OldHorPtr, TMarg, BMarg, ScrRows

    WasPressed = -1
    Delay = 0

    '----- Are we within the ROW limit of the TEXT?
    IF Ed.MRow >= Ed.TSRow AND Ed.MRow < Ed.TSRow + Ed.Rows THEN

       '----- Are we within the COLUMN limit of the TEXT?
       IF Ed.MCol >= Ed.LSCol AND Ed.MCol < Ed.LSCol + Ed.Wide THEN
          MouseAct = 1                          'Flag for TEXT operations
                                                'Limit mouse movement to window
          MouseTrap Ed.TSRow + (Ed.Frame <> 0), Ed.LSCol + (Ed.Frame <> 0), Ed.TSRow + Ed.Rows + (Ed.Frame = 0), Ed.LSCol + Ed.Wide + (Ed.Frame = 0)
                                                'Set the cursor row and column
          Ed.CurLine = Ed.MRow - Ed.TSRow + Ed.TL ' to the mouse location
          Ed.CurCol = Ed.MCol - Ed.LSCol + Ed.LC

          X$ = MouseKey$                        'Set dummy key so we fall out
                                                '  of key loop
          IF NOT MarkBlock THEN                 'If it's a new block
             BlkRow = Ed.CurLine                'Save upper left coordinates
             BlkCol = Ed.CurCol
             SaveT = Ed.TL                      'Save window coordinates
             SaveC = Ed.LC
          ELSE
             X$ = MouseKey2$
          END IF
          Ed.Presses = 0                        'Clear presses

       '----- Are we on the VERTICAL scroll bar?
       ELSEIF Ed.MCol = Ed.LSCol + Ed.Wide AND Ed.Frame THEN
                                                'On a Scroll Arrow?
          IF Ed.MRow = Ed.TSRow OR Ed.MRow = Ed.TSRow + Ed.Rows - 1 THEN
                                                'Limit mouse movement to the
                                                '  Scroll Arrow
             MouseTrap Ed.MRow, Ed.MCol, Ed.MRow, Ed.MCol
             MouseAct = 7

          '----- Are we on the scroll pointer?
          ELSEIF Ed.MRow = OldVrtPtr + Ed.TSRow + 1 AND Ed.LCount > Ed.Rows THEN
             MouseAct = 2                       'Flag for vertical scroll pointer
                                                'Limit mouse to scroll bar
             MouseTrap Ed.TSRow + 1, Ed.LSCol + Ed.Wide, Ed.TSRow + Ed.Rows - 2, Ed.LSCol + Ed.Wide
          END IF
          Ed.Presses = 0                        'Clear the press

       ELSEIF Ed.MCol = Ed.LSCol - 1 AND Ed.Frame THEN
          MouseAct = 8                          'On left hand border, move window
          MouseTrap Ed.MRow - Ed.TSRow + 2 + TMarg, 1, Ed.MRow + ScrRows - (Ed.TSRow + Ed.Rows) - BMarg, 79 - Ed.Wide
          Ed.Presses = 0                        'Clear the press
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
                MouseTrap Ed.MRow, Ed.MCol, Ed.MRow, Ed.MCol
                MouseAct = 7

             '----- On the scroll pointer?
             CASE Ed.LSCol + 9 + OldHorPtr
                                                'Set flag for horizontal
                MouseAct = 3                    '   scroll pointer
                                                'Limit mouse to scroll bar
                MouseTrap Ed.TSRow + Ed.Rows, Ed.LSCol + 9, Ed.TSRow + Ed.Rows, Ed.LSCol + Ed.Wide - 2

             '----- On Right Corner of Frame?
             CASE Ed.LSCol + Ed.Wide
                MouseAct = 4       'Flag for lower right corner
                                                'Limit movement to screen
                                                '  margins
                MouseTrap TMarg + 1, 1, ScrRows - BMarg, 80

             CASE ELSE
          END SELECT

          Ed.Presses = 0                        'Clear the mouse press
       END IF

    '----- Are we on the TOP line of the Frame
    ELSEIF Ed.MRow = Ed.TSRow - 1 AND Ed.Frame THEN
       IF Ed.MCol >= Ed.LSCol - 1 AND Ed.MCol <= Ed.LSCol + Ed.Wide THEN
                                                'On the TOP LEFT corner?
          IF Ed.MCol = Ed.LSCol - 1 THEN
             MouseTrap TMarg + 1, 1, ScrRows - BMarg, 80
             MouseAct = 5                       'Flag for upper left corner

          '----- Are we on the RIGHT MARGIN marker?
          ELSEIF Ed.MCol = Ed.LSCol + Ed.Wrap - Ed.LC AND Ed.Wrap >= Ed.LC AND Ed.Wrap < Ed.LC + Ed.Wide THEN
             MouseAct = 6                       'Flag for margin marker
                                                'Limit mouse to ruler line
             MouseTrap Ed.TSRow - 1, Ed.LSCol, Ed.TSRow - 1, Ed.LSCol + Ed.Wide - 1

          ELSEIF Ed.MCol < Ed.LSCol + Ed.Wide THEN
             MouseAct = 8                       'move window
             MouseTrap TMarg + 1, Ed.MCol - Ed.LSCol + 2, Ed.MRow + ScrRows - (Ed.TSRow + Ed.Rows) - BMarg, Ed.MCol + (80 - Ed.Wide - Ed.LSCol)

          ELSE
             MouseAct = 9
          END IF
          Ed.Presses = 0                        'Clear the mouse press
       END IF
    END IF


END SUB

'**************************************************************************
'Paints the currently marked portion of the screen when defining a block.
'Also decides whether the block is a column or sentence block.
'**************************************************************************
'
SUB QEPaintBlock (Ed AS EditInfo)

    SHARED Bl() AS BlkCoords
    SHARED FrstBlkKey, ColBlock, BlkRow, BlkCol, BlkClr
    SHARED BlocksThere

    '----- If block marking key was just pressed
    IF FrstBlkKey THEN
       ColBlock = 0                             'Init flag to sentence mode
                                                'If still on same line, reset
                                                '  mode for column block
       IF Ed.CurLine = BlkRow THEN ColBlock = -1
       FrstBlkKey = 0                           'Reset first key flag
       Bl(0).PB = 60                            'Init history variables
       Bl(1).PB = 80
       Bl(2).PB = 0
       Bl(3).PB = 0
    END IF

    Bl(0).B = MinInt(Ed.CurLine, BlkRow)        'Set top of block
    Bl(2).B = MaxInt(Ed.CurLine, BlkRow)        'Set bottom of block

    '----- If in COLUMN BLOCK mode,
    IF ColBlock THEN

       '----- Set left and right columns
       Bl(1).B = MinInt(Ed.CurCol, BlkCol)
       Bl(3).B = MaxInt(Ed.CurCol - 1, BlkCol)

       '----- Set coordinates to paint
       Bl(0).P = MaxInt%(Bl(0).B, Ed.TL) - Ed.TL + Ed.TSRow
       Bl(1).P = MaxInt%(Bl(1).B, Ed.LC) - Ed.LC + Ed.LSCol
       Bl(2).P = MinInt%(Bl(2).B, Ed.TL + Ed.Rows - 1) - Ed.TL + Ed.TSRow
       Bl(3).P = MaxInt(MinInt%(Bl(3).B, Ed.LC + Ed.Wide - 1) - Ed.LC + Ed.LSCol, Ed.LSCol)

       '----- Get previous paint coordinates
       Bl(0).PP = MaxInt%(Bl(0).PB, Ed.TL) - Ed.TL + Ed.TSRow
       Bl(1).PP = MaxInt%(Bl(1).PB, Ed.LC) - Ed.LC + Ed.LSCol
       Bl(2).PP = MinInt%(Bl(2).PB, Ed.TL + Ed.Rows - 1) - Ed.TL + Ed.TSRow
       Bl(3).PP = MinInt%(Bl(3).PB, Ed.LC + Ed.Wide - 1) - Ed.LC + Ed.LSCol

       '----- Un-paint old part of block
       IF Bl(3).PB >= Ed.LC AND Bl(2).PB >= Ed.TL THEN
          IF Bl(0).PB < Bl(0).B THEN MPaintBox Bl(0).PP, MinInt(Bl(1).PP, Bl(1).P), Bl(0).P - 1, MaxInt(Bl(3).PP, Bl(3).P), Ed.AColor
          IF Bl(2).PB > Bl(2).B THEN MPaintBox Bl(2).P + 1, MinInt(Bl(1).PP, Bl(1).P), Bl(2).PP, MaxInt(Bl(3).PP, Bl(3).P), Ed.AColor
          IF Bl(1).PB < Bl(1).B THEN MPaintBox MinInt(Bl(0).P, Bl(0).PP), Bl(1).PP, MaxInt(Bl(2).P, Bl(2).PP), Bl(1).P, Ed.AColor
          IF Bl(3).PB > Bl(3).B THEN MPaintBox MinInt(Bl(0).P, Bl(0).PP), Bl(3).P, MaxInt(Bl(2).P, Bl(2).PP), Bl(3).PP, Ed.AColor
       END IF

       '----- Paint the block
       IF Bl(3).B >= Ed.LC AND Bl(2).B >= Ed.TL THEN
          MPaintBox Bl(0).P, Bl(1).P, Bl(2).P, Bl(3).P, BlkClr
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
       Bl(2).P = MinInt(Bl(2).B - Ed.TL + Ed.TSRow, Ed.TSRow + Ed.Rows - 1)
       Bl(3).P = MaxInt(Ed.LSCol, MinInt%(Bl(3).B, Ed.LC + Ed.Wide - 1) - Ed.LC + Ed.LSCol)

       '----- Get previous paint coordinates
       Bl(0).PP = MaxInt%(Bl(0).PB, Ed.TL) - Ed.TL + Ed.TSRow
       Bl(1).PP = MaxInt%(Bl(1).PB, Ed.LC) - Ed.LC + Ed.LSCol
       Bl(2).PP = MinInt(Bl(2).PB - Ed.TL + Ed.TSRow, Ed.TSRow + Ed.Rows - 1)
       Bl(3).PP = MaxInt(Ed.LSCol, MinInt%(Bl(3).PB, Ed.LC + Ed.Wide - 1) - Ed.LC + Ed.LSCol)

       '----- Un-paint old part of block
       IF Bl(2).B < Bl(2).PB THEN MPaintBox Bl(2).P, Ed.LSCol, Bl(2).PP, Ed.LSCol + Ed.Wide - 1, Ed.AColor
       IF Bl(0).B > Bl(0).PB THEN MPaintBox Bl(0).PP, Ed.LSCol, Bl(0).P, Ed.LSCol + Ed.Wide - 1, Ed.AColor

       '----- Paint the new block
       IF Ed.CurLine <> BlkRow THEN             'If more than one line

          '----- Paint top line if on screen
          IF Bl(0).B >= Ed.TL THEN
             IF Bl(1).B >= Bl(1).PB THEN MPaintBox Bl(0).P, Ed.LSCol, Bl(0).P, MaxInt(Bl(1).P - 1, Ed.LSCol), Ed.AColor
             MPaintBox Bl(0).P, Bl(1).P, Bl(0).P, Ed.LSCol + Ed.Wide - 1, BlkClr
          END IF

          '----- Paint middle lines if on screen
          FOR N = Bl(0).B + 1 TO Bl(2).B - 1
             IF N >= Ed.TL AND N < Ed.TL + Ed.Rows THEN
                Bl(0).P = N - Ed.TL + Ed.TSRow
                MPaintBox Bl(0).P, Ed.LSCol, Bl(0).P, Ed.LSCol + Ed.Wide - 1, BlkClr
             END IF
          NEXT

          '----- Paint bottom line if on screen
          IF Bl(2).B < Ed.TL + Ed.Rows THEN
             IF Bl(3).B <= Bl(3).PB THEN MPaintBox Bl(2).P, Bl(3).P, Bl(2).P, Ed.LSCol + Ed.Wide - 1, Ed.AColor
             IF Bl(3).B >= Ed.LC THEN MPaintBox Bl(2).P, Ed.LSCol, Bl(2).P, Bl(3).P, BlkClr
          END IF
       ELSE                                     'Only one line

          MPaintBox Bl(2).P, Ed.LSCol, Bl(2).P, Ed.LSCol + Ed.Wide - 1, Ed.AColor
          LPCol = MaxInt%(MinInt(BlkCol, Ed.CurCol), Ed.LC) - Ed.LC + Ed.LSCol
          RPCol = MaxInt(MinInt%(MaxInt(BlkCol, Ed.CurCol - 1), Ed.LC + Ed.Wide - 1) - Ed.LC + Ed.LSCol, Ed.LSCol)
          MPaintBox Bl(2).P, LPCol, Bl(2).P, RPCol, BlkClr
       END IF
    END IF

    '----- Save bottom corner coordinates
    Bl(0).PB = Bl(0).B
    Bl(1).PB = Bl(1).B
    Bl(2).PB = Bl(2).B
    Bl(3).PB = Bl(3).B

END SUB

SUB QEPasteColBlock (Array$(), Ed AS EditInfo)

    SHARED ClipBd(), NumRows, NumCols, ArrayEnd

    Temp$ = SPACE$(NumCols)
    IF NumRows > 1 THEN
       FOR N = 1 TO NumRows                     'Do each line of clipboard

          Temp = Ed.CurLine + N - 1             'Calc text array element
          IF Temp < ArrayEnd THEN
                                                'If it would be inside a line,
                                                '  insert a line
             OK = 0
             IF Ed.CurCol <= LEN(Array$(Temp)) THEN
                IF Blanks%(Array$(Temp)) < Ed.CurCol + NumCols - 1 THEN
                   QEInsertLine "", Temp, Ed, Array$()
                   Temp$ = SPACE$(NumCols)
                ELSE
                   OK = -1
                END IF
             END IF

             MidStrRest Temp$, N, ClipBd(0)

             IF FRE("") < 1280& THEN
                BEEP
                Ed.MErr = 1                     'Set error flag
                EXIT FOR
             END IF

             IF NOT Null(Temp$) THEN
                IF OK THEN
                   MID$(Array$(Temp), Ed.CurCol) = Temp$
                ELSE
                                                'Pad with spaces to the left
                   Array$(Temp) = Array$(Temp) + SPACE$(Ed.CurCol - LEN(Array$(Temp)) - 1) + Temp$
                   Array$(Temp) = RTRIM$(Array$(Temp))
                END IF
             END IF
                                                'Update line count
             Ed.LCount = MaxInt%(Ed.LCount, Temp)
          END IF
       NEXT
                                                'Update number of lines
       Ed.LCount = FindLast%(VARPTR(Array$(ArrayEnd)), ArrayEnd)

    ELSE                                        'Restore one line of text
       IF Ed.CurCol > LEN(Array$(Ed.CurLine)) THEN
          Array$(Ed.CurLine) = Array$(Ed.CurLine) + SPACE$(Ed.CurCol - LEN(Array$(Ed.CurLine)) - 1)
       END IF
       MidStrRest Temp$, 1, ClipBd(0)
       Array$(Ed.CurLine) = LEFT$(Array$(Ed.CurLine), Ed.CurCol - 1) + Temp$ + MID$(Array$(Ed.CurLine), Ed.CurCol)
       Array$(Ed.CurLine) = RTRIM$(Array$(Ed.CurLine))
                                                'Wrap words down
       Ed.LCount = MaxInt(Ed.LCount, Ed.CurLine)
       IF Ed.Wrap THEN
          Lin = QEWrapDown(Ed.CurLine, Array$(), Ed)
       END IF
    END IF
    Temp$ = ""

END SUB

SUB QEPasteSentBlock (Array$(), Ed AS EditInfo)

    SHARED ClipBd(), NumRows, ArrayEnd
    SHARED ClipBd1$, ClipBd2$

    ClipBytes& = UBOUND(ClipBd) * 2 + (ClipBd(UBOUND(ClipBd)) < 256)
    IF Ed.Wrap THEN                             'If in word wrap mode,
                                                'Compose top line of block
       RightSide$ = MID$(Array$(Ed.CurLine), Ed.CurCol)
       Array$(Ed.CurLine) = LEFT$(Array$(Ed.CurLine), Ed.CurCol - 1)

       Temp = Ed.CurLine                        'Save current line #

       FOR N = 0 TO NumRows                     'Compose middle lines of block
          IF N THEN
                                                'Make string to hold a line
             Temp$ = SPACE$(StrLength%(ClipBd(0), ClipBytes&, N))
                                                'Get the next string
             Get1Str Temp$, ClipBd(0), N
          ELSE
             Temp$ = ClipBd1$
          END IF

          Temp$ = Temp$ + SPACE$(FnSpaces2Pad(Temp$))
                                                'If the string is nul,
          IF LEN(Temp$) = 0 OR LEFT$(Temp$, 1) = " " THEN
                                                '  insert a new line
             Temp = MinInt(Temp + 1, ArrayEnd)
             QEInsertLine Temp$, Temp, Ed, Array$()
             IF LEN(Temp$) = 0 THEN
                Temp = MinInt(Temp + 1, ArrayEnd)
                QEInsertLine Temp$, Temp, Ed, Array$()
             END IF
          ELSE                                  'Insert text in current line
             Array$(Temp) = Array$(Temp) + Temp$
          END IF
       NEXT                                     'Insert last line
       Array$(Temp) = RTRIM$(Array$(Temp) + ClipBd2$ + RightSide$)
                                                'Update last line number
       Ed.LCount = FindLast%(VARPTR(Array$(ArrayEnd)), ArrayEnd)

       QEWrapAll (Ed.CurLine), Array$(), Ed

    ELSE                                        'Not in word wrap mode

       FOR N = 1 TO NumRows + 2                 'For each row of the block
          Temp = Ed.CurLine + N - 1             'Calc line number of text
          IF Temp <= ArrayEnd THEN              'Don't go off the end of array

             Temp$ = ""                         'Init buffer string
             IF N = 1 THEN                      'If it's the first line, use
                                                '  the "ClipBd1$"
                Temp$ = SPACE$(Ed.UlCCol - 1) + ClipBd1$
                                                'If it's the last line use
             ELSEIF N = NumRows + 2 THEN        '  "ClipBd2$"
                IF Ed.BrCCol > 0 THEN
                   Temp$ = ClipBd2$
                ELSE
                   EXIT FOR
                END IF
             ELSE                               'For the body of the block,
                                                '  get lines from far mem.
                Temp$ = SPACE$(StrLength%(ClipBd(0), ClipBytes&, N - 1))
                Get1Str Temp$, ClipBd(0), N - 1
             END IF
             QEInsertLine RTRIM$(Temp$), Temp, Ed, Array$()
          END IF
       NEXT
                                                'Update last line number
       Ed.LCount = FindLast%(VARPTR(Array$(ArrayEnd)), ArrayEnd)

    END IF

END SUB

SUB QEShowHelp (Ed AS EditInfo)

    SHARED BlocksThere, MouseThere

    REDIM HelpScr(ArraySize%(2, 80 - 57 - 1, 12, 80))
                                                'Save underlying screen
    MScrnSave 2, 80 - 57 - 1, 12, 80, HelpScr(1)

    REDIM Help(35) AS STRING * 57
                                                'Load array with Help text
    LoadHelp7 VARSEG(Help(1)), VARPTR(Help(1))

    LOCATE 2, 80 - 57 - 1, 0                    'Locate the cursor

    HideCursor                                  'Print the help screen
    APrintT0 VARSEG(Help(1)), VARPTR(Help(1)), 57, 10, 1, 57, 112'79
    ShowCursor
                                                'Paint Shadows
    MPaintBox 3, 79, 11, 80, 8
    MPaintBox 12, 80 - 57 + 1, 12, 80, 8
    LOCATE 10, 78
    IF NOT MouseThere AND NOT BlocksThere THEN
       MQPrint "º", 79
    ELSE
       MQPrint CHR$(18), 240
    END IF

    LOCATE 3, 80 - 57 - 1                       'Locate the cursor
    I = 2
    DO                                          'Wait for a key press
       Temp = PeekBuf
       SELECT CASE Temp                         'Get key but don't remove it
          CASE -72, -73                         'Up arrow or PgUp
             SELECT CASE I                      'Set pointer based on last one
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
          CASE -80, -81                         'Down arrow or PgDn
             SELECT CASE I                      'Set pointer based on last one
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

          CASE 27                               'Escape key
             Temp$ = INKEY$                     'Take key out of buffer
             EXIT DO                            'Bail out
          CASE 0
          CASE ELSE                             'Bail out if any other key
             EXIT DO
       END SELECT

       IF Temp THEN
          Temp$ = INKEY$                        'Now extract key from buffer
          HideCursor                            'Display new page of help
          APrintT0 VARSEG(Help(I)), VARPTR(Help(I)), 57, 8, 1, 56, 112'79
          ShowCursor
       END IF
                                                'Bail out if mouse button pressed
       ButtonPress 1, 0, Ed.Presses, X, Y
    LOOP UNTIL Ed.Presses
                                                'Restore the screen
    MScrnRest 2, 80 - 57 - 1, 12, 80, HelpScr(1)
    ERASE HelpScr, Help                         'Clean up memory

END SUB

SUB QETabKey (Array$(), Ed AS EditInfo)

    SHARED LineBuf$, Insrt, RePrint

    '----- Make current column "Ed.HTab" to the right
    N = ((Ed.CurCol + Ed.HTab - 1) \ Ed.HTab) * Ed.HTab + 1
    N = MinInt(N, 255 - Ed.HTab)

    IF N <= Ed.Wrap OR Ed.Wrap = 0 THEN
                                                'If in Insert mode
       IF Insrt = -1 AND Ed.CurCol <= LEN(Array$(Ed.CurLine)) THEN
                                                '  insert "Ed.HTab" spaces
          Array$(Ed.CurLine) = LEFT$(Array$(Ed.CurLine), Ed.CurCol - 1) + SPACE$(N - Ed.CurCol) + MID$(Array$(Ed.CurLine), Ed.CurCol)
          IF Ed.Wrap THEN
             Lin = QEWrapDown(Ed.CurLine, Array$(), Ed)
          END IF
          Ed.Changed = -1
       END IF

       Ed.CurCol = N
                                                'Is it off the right of window?
       IF Ed.CurCol > Ed.LC + Ed.Wide - 1 THEN
          Ed.LC = Ed.LC + Ed.HTab               'Make it "Ed.HTab" to the right
          RePrint = -1                          'Set flag to re-print window
       ELSE                                     'Move to the left margin
          LOCATE , Ed.LSCol, 0
                                                'Put new line in buffer
          LSET LineBuf$ = MID$(Array$(Ed.CurLine), Ed.LC)
                                                'Print the buffer
          MQPrint LineBuf$, Ed.AColor
       END IF
    END IF

END SUB

SUB QETextKeys (X$, Array$(), Ed AS EditInfo)

    SHARED LineEd, ArrayEnd, Insrt

    X = LEN(Array$(Ed.CurLine))                 'See if line is long enough
    IF X < 256 AND Ed.CurCol < 256 THEN
       
       Ed.LCount = MaxInt%(Ed.LCount, Ed.CurLine) ' end
                                                'Insert character in line
       IF Insrt = -1 AND Ed.CurCol <= X THEN
          IF Ed.CurLine < ArrayEnd OR Ed.Wrap = 0 OR X < Ed.Wrap THEN
             Array$(Ed.CurLine) = LEFT$(Array$(Ed.CurLine), Ed.CurCol - 1) + X$ + MID$(Array$(Ed.CurLine), Ed.CurCol)
             MQPrint MID$(Array$(Ed.CurLine), Ed.CurCol, Ed.Wide - (Ed.CurCol - Ed.LC)), Ed.AColor
             IF Ed.Wrap THEN
                Lin = QEWrapDown(Ed.CurLine, Array$(), Ed)
             END IF
             Ed.CurCol = Ed.CurCol + 1          'Update the current column
             Ed.Changed = -1                    'We just changed the text
             LineEd = -1
          END IF
       ELSE                                     'Concat character to end
          IF Ed.CurLine < ArrayEnd OR Ed.Wrap = 0 OR Ed.CurCol < Ed.Wrap THEN
             IF Ed.CurCol > X THEN              'Make space for new character
                Array$(Ed.CurLine) = Array$(Ed.CurLine) + SPACE$(Ed.CurCol - X)
             END IF                             'Update line count if past

             MID$(Array$(Ed.CurLine), Ed.CurCol, 1) = X$
             MQPrint X$, Ed.AColor              'Print the character
             IF Ed.Wrap AND Ed.CurCol > Ed.Wrap THEN
                Lin = QEWrapDown(Ed.CurLine, Array$(), Ed)
             END IF
             Ed.CurCol = Ed.CurCol + 1          'Update the current column
             Ed.Changed = -1                    'We just changed the text
             LineEd = -1
          END IF
       END IF
          
       QECheckWindowLimits Ed
    END IF

END SUB

'*************************************************************************
'Wrap all text starting at "WrapLine" to current right margin.
'*************************************************************************
'
SUB QEWrapAll (WrapLine, Array$(), Ed AS EditInfo)

    DO UNTIL WrapLine > Ed.LCount               'Stop at last used element
        IF LEN(Array$(WrapLine)) THEN           'If it's not a blank line,
           
                                                '  wrap paragraph down and
                                                '  then up.
                                                'Look at line past paragraph
           Lin = WrapLine
           WrapLine = QEWrapDown(Lin, Array$(), Ed)
           WrapLine = QEWrapUp(Lin, Array$(), Ed)

        ELSE
           WrapLine = WrapLine + 1              'Line was blank, look at next
        END IF
    LOOP

END SUB

'----- Wrap words down to form a paragraph
'
FUNCTION QEWrapDown (WrapLine, Array$(), Ed AS EditInfo)

    SHARED Par$, ArrayEnd, RePrint

    Lin = WrapLine                              'Make temp copy of line #

    P = INSTR(Array$(Lin), Par$)                'Look for a paragraph marker
                                                'Do lines that are too long
    DO
       LinLen = LEN(Array$(Lin))                'Get the length of cur. line
       IF LinLen > Ed.Wrap OR P THEN

          IF P = 1 AND LinLen = 1 THEN
             Array$(Lin) = ""
             EXIT DO
          END IF

          IF P > 0 AND P <= Ed.Wrap + 1 THEN    'If marker is in range,
             B = P + 1                          '  set cutoff to marker
          ELSE                                  'Starting at the right margin,
                                                'look backwards for a blank
             I = QInstrB%(Ed.Wrap + 1, Array$(Lin), " ")
             IF I = 0 THEN I = Ed.Wrap + 1      'If no blanks, chop it off
                                                'Now look fwd. for non-blank
             B = Blanks%(MID$(Array$(Lin), I)) + I
          END IF


          IF B <= LinLen THEN                   'If we didn't go past the end,
             Lin = Lin + 1                      '  increment the line number
             IF Lin > ArrayEnd THEN             'Past end?  Bail out
                Lin = Lin - 1
                Ed.MErr = 2
                EXIT DO
             END IF

             LinLen = LEN(Array$(Lin))          'Get the length of new line
                                                'If this is a blank line or
                                                '  starts with a space
             IF LinLen = 0 OR Blanks%(Array$(Lin)) OR ASCII(Array$(Lin)) = 20 THEN
                                                'Insert remainder of last line
                                                '  into a new line
                QEInsertLine MID$(Array$(Lin - 1), B), Lin, Ed, Array$()
             ELSE                               'Add remainder of prev. line
                                                '  to this line
                IF P > 1 THEN
                   Array$(Lin) = MID$(Array$(Lin - 1), B) + Array$(Lin)
                ELSE
                   Array$(Lin) = MID$(Array$(Lin - 1), B) + SPACE$(FnSpaces2Pad(Array$(Lin - 1))) + Array$(Lin)
                END IF
             END IF
                                                'If we just wrapped current
             IF Lin - 1 = Ed.CurLine THEN       '  line and the cursor was
                IF Ed.CurCol >= B THEN          '  within the wrapped words,
                   Ed.CurCol = Ed.CurCol - B + 1'  move the cursor to the new
                   Ed.LC = ((Ed.CurCol \ Ed.Wide) * Ed.Wide) + 1'  line at the end of the
                   Ed.CurLine = MinInt(Lin, ArrayEnd)           '  wrapped words
                   Ed.TL = MaxInt%(Ed.TL, Ed.CurLine - Ed.Rows + 1)
                END IF
             END IF

             LinLen = LEN(Array$(Lin))          'Get length of the new line
                                                'Trim the prev. line
             Array$(Lin - 1) = RTRIM$(LEFT$(Array$(Lin - 1), B - 1))
             RePrint = -1                       'Set flag to re-print window

          ELSE                                  'Words weren't found past wrap
             Lin = Lin + 1                      'Increment the line number
             IF Lin > ArrayEnd THEN
                Lin = Lin - 1
                Ed.MErr = 2
                EXIT DO                         'Past end?  Bail out
             END IF
             LinLen = LEN(Array$(Lin))          'Get its length
          END IF
       ELSEIF LinLen = 0 OR Lin >= Ed.LCount THEN
          EXIT DO
       ELSE
          Lin = Lin + 1                         'Increment the line number
       END IF

       P = INSTR(Array$(Lin), Par$)             'Look for a paragraph marker

    LOOP                                        'Process the new line

    QEWrapDown = Lin + 1

END FUNCTION

'----- Wrap words Up to re-form a paragraph
'
FUNCTION QEWrapUp (WrapLine, Array$(), Ed AS EditInfo)

    SHARED Par$, WrapWas, RePrint

    Lin = WrapLine                              'Make temp copy of line #

    '----- If the line isn't nul and current line isn't past the end and the
    '----- current line doesn't have a paragraph marker on the end.
    DO UNTIL Null(Array$(Lin)) OR Lin >= Ed.LCount

        P = INSTR(Array$(Lin), Par$)
        IF P THEN
           '~~~~~ Rem put the following line to preserve paragraph markers
           Array$(Lin) = LEFT$(Array$(Lin), P - 1) + MID$(Array$(Lin), P + 1)
           EXIT DO
        END IF

        LinLen = LEN(Array$(Lin + 1))           'Get the length of next line
                                                'If it has Par marker or is
                                                '  blank, bail out
        IF INSTR(Array$(Lin + 1), Par$) = LinLen THEN
           IF LinLen THEN
              Array$(Lin + 1) = LEFT$(Array$(Lin + 1), LinLen - 1)
           END IF
           EXIT DO
        END IF
        IF Blanks%(Array$(Lin + 1)) THEN EXIT DO

        Temp = FnSpaces2Pad(Array$(Lin))

        IF Lin = WrapLine AND Ed.Wrap > WrapWas THEN
           Extra = WrapWas - LEN(Array$(Lin)) - Temp
           GOSUB GetWordPos
           IF I THEN                            'Words were found to fill so,
              IF INSTR(LEFT$(Array$(Lin + 1), I - 1), " ") THEN
                 EXIT DO
              END IF
           END IF
        END IF

        Extra = Ed.Wrap - LEN(Array$(Lin)) - Temp

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
              QEDeleteLine Lin + 1, Ed, Array$()

              Lin = Lin - 1
              IF Lin + 1 > Ed.LCount THEN EXIT DO 'Off the end, bail out
           END IF
        END IF

        Lin = Lin + 1
        
    LOOP

    

    QEWrapUp = Lin + 1

EXIT FUNCTION


GetWordPos:
    IF Extra > 0 THEN                           'If there is extra space,
       IF Extra >= LinLen THEN
          I = LinLen
       ELSE
          B = Extra
          IF MID$(Array$(Lin + 1), B, 1) <> " " THEN
             B = QInstrB(B, Array$(Lin + 1), " ")
          END IF

          FOR I = B TO 1 STEP -1
              IF MID$(Array$(Lin + 1), I, 1) <> " " THEN EXIT FOR
          NEXT
       END IF
    ELSE
       I = 0
    END IF
RETURN

END FUNCTION

