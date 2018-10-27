'***** "Spread.Bas" main module for declarations

'Copyright (c) 1988 Crescent Software


DEFINT A-Z

'----- ASM Sub Programs

DECLARE SUB Box0 (UlRow, UlCol, BrRow, BrCol, LineType, Clr)
DECLARE SUB ClearScr0 (UlRow, UlCol, BrRow, BrCol, Clr)
DECLARE SUB Editor (Edited$, EdLen, SCode, NumOnly, CapsOnly, OrigClr, EdClr, UlRow, LCol)
DECLARE SUB PaintBox0 (UlRow, UlCol, BrRow, BrCol, Clr)
DECLARE SUB QPrint0 (Printed$, Clr)
DECLARE SUB ScrnSave0 (UlRow, UlCol, BrRow, BrCol, SEG Address)
DECLARE SUB ScrnRest0 (UlRow, UlCol, BrRow, BrCol, SEG Address)
DECLARE SUB ScrollU (UlRow, UlCol, BrRow, BrCol, NLines, Page)
DECLARE SUB ScrollD (UlRow, UlCol, BrRow, BrCol, NLines, Page)
DECLARE SUB ScrollL (UlRow, UlCol, BrRow, BrCol, NLines, Page)
DECLARE SUB ScrollR (UlRow, UlCol, BrRow, BrCol, NLines, Page)
DECLARE SUB StuffBuf (Ky$)


'----- ASM Functions

DECLARE FUNCTION ArraySize% (UlRow, UlCol, BrRow, BrCol)
DECLARE FUNCTION FUsing$ (Number$, Mask$)
DECLARE FUNCTION Monitor% ()
DECLARE FUNCTION MinInt% (Arg1%, Arg2%)

'****************************************************************************
'  Title: Spread
'     by: Don Malin  5/09/88
'
'Purpose: Displays a spread sheet window and allows the user to make entries
'         and move within it.  The underlying screen can be saved and
'         restored by setting a code flag for either option.  The routine
'         will relinquish control when the user presses the Slash (/) key.
'
' Syntax: Call Spread (Arg1$(), Arg2$(), Arg3%(), Arg4%, Arg5%, Arg6%)
'
' Inputs: Arg1$(2) - Worksheet cell data. Arg2$(1, 1) = Cell A1 data
'                                         Arg2$(1, 2) = Cell B1 data... etc.
'         Arg2$(2) - Formatting strings for numeric data (parallel to above)
'         Arg3%(1) - Table of column widths (Arg1%(1) = Column #1 width)
'         Arg4%    - Window contents width in characters (not incl. frame)
'         Arg5%    - Window contents rows (not including frame)
'         Arg6%    - Action flag: 0 = Init window, save underlying screen
'                                 1 = same as 0 for now
'                                 2 = Do not redisplay or save window
'                                 5 = Restore underlying screen
'
'  Notes: It is up to you to determine the probable amount of string space
'         required for your worksheet and the amount already used by your
'         program.  "Out of string space" errors will be trapped by the
'         program but it is a good idea to dimension the string data arrays
'         only to the useful size of the spreadsheet.  See the labels
'         "QPCalcAll:" and "QPCalc1:" to see how to do calculated cells.
'
'         String data cells must be preceeded with a "'", "^" or "`"
'         character as in 123.  Numeric strings must begin with a space.
'****************************************************************************
'
SUB Spread (Wks$(), Frmt$(), ColWdths(), Wdth, Rows, Action) STATIC

    SELECT CASE Monitor%                        'determine the monitor type
       CASE 3, 5, 7, 9, 10, 12                  'CGA, EGA, VGA monitors
          BorderClr = 48                        'border color black on cyan
          WorkClr = 31                          'worksheet use white on blue
          HiClr = 112                           'hi-lite use black on white
       CASE ELSE                                'all other monitors
          BorderClr = 112                       'black on white borders
          WorkClr = 7                           'white on black cells
          HiClr = 112                           'black on white hi-lite
    END SELECT


    '----- Init parameters and save the screen
    IF Action = 0 OR Action = 1 THEN            'if flag set to init window,
       UlRow = CSRLIN                           'save the curent cursor line
       UlCol = POS(0)                           '  and column positions
       BrRow = UlRow + Rows + 1                 'calc window bottom row number
       BrCol = UlCol + Wdth + 1                 'ditto for right column
       Lin$ = SPACE$(BrCol - UlCol - 1)         'buffer for composing data
       NumTable$ = "+-.0123456789"              'table of numeric characters
       DispCode$ = "'^`" + CHR$(34)             'table of string justifiers
       Status$ = SPACE$(5)                      'buffer for status messages

                                                'array for screen contents
       REDIM ScrBuf(ArraySize%(UlRow, UlCol, BrRow, BrCol))
                                                'save the underlying screen
       ScrnSave0 UlRow, UlCol, BrRow, BrCol, ScrBuf(1)
                                                'clear the window area
       ClearScr0 UlRow, UlCol, BrRow, BrCol, WorkClr
                                                'draw the window frame
       Box0 UlRow, UlCol, BrRow, BrCol, 2, WorkClr
       LOCATE UlRow, BrCol - 7                  'print frame for status msg.
       QPrint0 "µ     Æ", -1
                                                'paint row & column borders
       PaintBox0 UlRow + 2, UlCol + 1, UlRow + 2, BrCol - 1, BorderClr
                                                'paint worksheet area
       PaintBox0 UlRow + 3, UlCol + 1, BrRow - 1, UlCol + 4, BorderClr

       WkCol = 1                                'current cell column
       WkRow = 1                                'current cell row
       UlCelRow = 1                             'upper left cell row
       UlCelCol = 1                             'upper left cell column

       Action = 2                               'set window flag to idle
    END IF

    IF Action = 5 THEN                          'Flag = 5 means pop window
                                                'restore the screen
       ScrnRest0 UlRow, UlCol, BrRow, BrCol, ScrBuf(1)
       ERASE ScrBuf                             'clean up memory
       Action = 1                               'reset flag
       EXIT SUB                                 'bail out
    END IF
   
    REDIM ColPtrs(UBOUND(Wks$, 2))              'column beginning positions
    REDIM ColBuf$(UBOUND(Wks$, 2))              'buffer for cell contents

    LOCATE , , 0                                'turn the cursor off
   
    HeadWdth = 0                                'accumulates header width
    Ptr = 0                                     'column beginning pos. pointer
    FOR N = 1 TO UBOUND(Wks$, 2)                'for each column,
        HeadWdth = HeadWdth + ColWdths(N)       'accumulate header width
        ColPtrs(N) = Ptr + 1                    'save char. pointer for column
        ColBuf$(N) = SPACE$(ColWdths(N))        'make buffer width of cell
        Ptr = Ptr + ColWdths(N)                 'increment pointer
    NEXT
    Head$ = SPACE$(HeadWdth + 8)                'make the header string

    FOR N = 1 TO UBOUND(Wks$, 2)                'compose column letter labels
        IF N > 26 THEN                          'two letter column labels
           Ltr$ = CHR$(((N - 1) \ 26) + 64) + CHR$(((N - 1) MOD 26) + 65)
        ELSE                                    'one letter column labels
           Ltr$ = CHR$(N + 64)
        END IF                                  'insert label in header string
        MID$(Head$, ColPtrs(N) + ((ColWdths(N) - LEN(Ltr$)) \ 2)) = Ltr$
    NEXT
   
    GOSUB QPPrintHdr                            'print the column header
    GOSUB QPPrintCell                           'display current cell contents
    GOSUB QPCalcAll                             'do cell calculations
    GOSUB QPHiLite                              'hi-lite the current cell


    '----- Main key processing loop
    DO
        LSET Status$ = "READY"                  'show READY status indicator
        LOCATE UlRow, BrCol - 6, 0
        QPrint0 Status$, BorderClr
                                                'locate cursor on cell
        LOCATE UlRow + 1, UlCol + LEN(CellAddr$) + 2, 1 'contents window

        DO                                      'wait for key strokes
            Ky$ = INKEY$
        LOOP WHILE LEN(Ky$) = 0

        IF Ky$ = CHR$(9) THEN                   'make Tab char. into extended
           Ky$ = CHR$(0) + Ky$                  '  Character
           GOTO QPExtKey                        'jump to 2 char key processing
        END IF

        IF LEN(Ky$) = 1 THEN                    'single char. key processing
                                                'if not a control key
           IF Ky$ <> "/" AND Ky$ <> CHR$(13) AND Ky$ <> CHR$(27) THEN
                                                '  they must be entering data
              IF INSTR(NumTable$, Ky$) OR LEN(Frmt$(WkRow, WkCol)) THEN     'is it a number?
                 LSET Status$ = "VALUE"         'set "VALUE" in status box
                 Num = 1                        'set # only flag for editor
              ELSE                              'no
                 LSET Status$ = "LABEL"         'set "LABEL" in status box
                 Num = 0                        'alpha/# flag for editor
              END IF
              LOCATE UlRow, BrCol - 6, 0        'print the status indicator
              QPrint0 Status$, BorderClr        'get edit line length
              EdLen = BrCol - UlCol - LEN(CellAddr$) - 2
              Ed$ = SPACE$(EdLen)               'make a buffer for editing
              StuffBuf Ky$                      'stuff key back in kbd buffer
              LOCATE , , 0                      'turn the cursor off (Editor
                                                'will turn it back on) - this
                                                'is necessary for PS2 W/VGA
                                                'let user edit the cell
              Editor Ed$, EdLen, XCode, Num, 0, 31, 112, UlRow + 1, UlCol + LEN(CellAddr$) + 2
              GOTO QPCellEdit                   'handle the new cell contents
           END IF
        END IF

QPExtKey:                                       'handle extended key codes
        IF LEN(Ky$) = 2 THEN                    'get value of code
           Ky = ASC(RIGHT$(Ky$, 1))

           SELECT CASE Ky                       'branch according to code

             '----- DOWN Arrow key pressed
             CASE 80
                IF WkRow < UBOUND(Wks$, 1) THEN 'if not at bottom of array
                                                'erase the hi-lite
                   PaintBox0 OUlR, OUlC, OUlR, OUlC + ColWdths(OWkCol) - 1, WorkClr
                   WkRow = WkRow + 1            'increment the row number
                   GOSUB QPPrintCell            'display new row's contents
                                                'if new row off bottom of page,
                   IF WkRow - UlCelRow = Rows - 2 THEN
                      UlCelRow = UlCelRow + 1   'increment upper left cell #
                                                'scroll the screen up
                      ScrollU UlRow + 3, UlCol + 1, BrRow - 1, BrCol - 1, 1, 0
                      R = UlCelRow + Rows - 3   'set pointer to bottom row #
                      GOSUB QPComposeLn         'compose the bottom line
                      LOCATE BrRow - 1, UlCol + 1
                      QPrint0 Lin$, -1          'print the new bottom line
                   END IF
                   GOSUB QPHiLite               'hi-lite the new cell
                END IF
                  
             '----- UP Arrow key pressed
             CASE 72
                IF WkRow > 1 THEN               'if not at top of array
                                                'erase the hi-lite
                   PaintBox0 OUlR, OUlC, OUlR, OUlC + ColWdths(OWkCol) - 1, WorkClr
                   WkRow = WkRow - 1            'decrement the row number
                   GOSUB QPPrintCell            'display new row's contents
                   IF WkRow < UlCelRow THEN     'if new row off top of page,
                      UlCelRow = UlCelRow - 1   'decrement upper left cell #
                                                'scroll the screen down
                      ScrollD UlRow + 3, UlCol + 1, BrRow - 1, BrCol - 1, 1, 0
                      R = UlCelRow              'set pointer to top row #
                      GOSUB QPComposeLn         'compose the top line
                      LOCATE UlRow + 3, UlCol + 1
                      QPrint0 Lin$, -1          'print the new top line
                   END IF
                   GOSUB QPHiLite               'hi-lite the new cell
                END IF

             '----- LEFT Arrow key pressed
             CASE 75
                IF WkCol > 1 THEN               'if not at first (A) column
                                                'erase the Hi-lite
                   PaintBox0 OUlR, OUlC, OUlR, OUlC + ColWdths(OWkCol) - 1, WorkClr
                   WkCol = WkCol - 1            'decrement the column number
                   GOSUB QPPrintCell            'display new cell's contents
                   IF WkCol < UlCelCol THEN     'if off left side of page,
                                                'scroll the screen right
                      ScrollR UlRow + 3, UlCol + 5, BrRow - 1, BrCol - 1, ColWdths(WkCol), 0
                      UlCelCol = UlCelCol - 1   'decrement upper left cell Col
                      GOSUB QPPrintHdr          're-print the header
                      GOSUB QPPrintWork         're-print the worksheet
                   END IF
                   GOSUB QPHiLite               'hi-lite the new cell
                END IF

             '----- RIGHT Arrow key pressed
             CASE 77
                IF WkCol < UBOUND(Wks$, 2) THEN 'if not at last column
                                                'erase the hi-lite
                   PaintBox0 OUlR, OUlC, OUlR, OUlC + ColWdths(OWkCol) - 1, WorkClr
                   WkCol = WkCol + 1            'increment the column number
                   GOSUB QPPrintCell            'display new cell's contents
                                                'if off right of page,
                   IF ColPtrs(WkCol) + ColWdths(WkCol) - ColPtrs(UlCelCol) > BrCol - UlCol - 5 THEN
                                                'scroll the screen left
                      ScrollL UlRow + 3, UlCol + 5, BrRow - 1, BrCol - 1, ColWdths(UlCelCol), 0
                      UlCelCol = UlCelCol + 1   'increment upper left cell Col.

                      DO WHILE ColPtrs(WkCol) + ColWdths(WkCol) - ColPtrs(UlCelCol) > BrCol - UlCol - 5
                         UlCelCol = UlCelCol + 1
                      LOOP

                      GOSUB QPPrintHdr          're-print the header
                      GOSUB QPPrintWork         're-print the worksheet
                   END IF
                   GOSUB QPHiLite               'hi-lite the new cell
                END IF

             '----- Page UP key pressed
             CASE 73
                IF UlCelRow - Rows - 2 < 1 THEN 'if not a full page above us
                   WkRow = WkRow - UlCelRow + 1 'calculate new cell row
                   UlCelRow = 1                 'set upper left cell row to 1
                ELSE                            'otherwise decrement upper
                   UlCelRow = UlCelRow - Rows + 2  '  left cell by a page
                   WkRow = WkRow - Rows + 2     'decrement cell row by a page
                END IF
                GOSUB QPPrintCell               'display new cell's contents
                GOSUB QPPrintWork               're-print the worksheet
                GOSUB QPHiLite                  'hi-lite the new cell

             '----- Page DOWN key pressed
             CASE 81                            'if not a full page below us
                IF UlCelRow + ((Rows - 2) * 2) > UBOUND(Wks$, 1) THEN
                   Tmp = WkRow - UlCelRow       'save cell row's offset in page
                                                'calc upper left cell address
                   UlCelRow = UBOUND(Wks$, 1) - Rows + 3
                   WkRow = UlCelRow + Tmp       'set new cell's address
                ELSE                            'otherwise increment upper left
                   UlCelRow = UlCelRow + Rows - 2 ' cell's row number by a page
                   WkRow = WkRow + Rows - 2     'ditto for cell's row
                END IF
                GOSUB QPPrintCell               'display new cell's contents
                GOSUB QPPrintWork               're-print the worksheet
                GOSUB QPHiLite                  'hi-lite the new cell

             '----- Ctrl RIGHT Arrow or TAB key (Page Right)
             CASE 116, 9
                UlCelCol = C                    'set upper left cell to new
                                                ' page then look for end of
                GOSUB ChkUlCelCol

                PaintBox0 OUlR, OUlC, OUlR, OUlC + ColWdths(OWkCol) - 1, WorkClr
                WkCol = UlCelCol                'set cell to upper left column
                GOSUB QPPrintCell               'display new cell's contents
                GOSUB QPPrintHdr                're-print the header
                GOSUB QPPrintWork               're-print the worksheet
                GOSUB QPHiLite                  'hi-lite the new cell

             '----- Ctrl LEFT Arrow or Shift TAB key (Page Left)
             CASE 115, 15
                LnWdth = 0                      'looking backwards from current
                FOR C = UlCelCol - 1 TO 1 STEP -1 ' page
                    LnWdth = LnWdth + ColWdths(C) 'add up column widths until
                    IF LnWdth + 4 > LnLin THEN EXIT FOR ' we have a full page
                NEXT
                UlCelCol = C + 1                'set upper left column #
                                                'erase the hi-lite
                PaintBox0 OUlR, OUlC, OUlR, OUlC + ColWdths(OWkCol) - 1, WorkClr
                WkCol = UlCelCol                'set cell col. to upper left
                GOSUB QPPrintCell               'display new cell's contents
                GOSUB QPPrintHdr                're-print the header
                GOSUB QPPrintWork               're-print the worksheet
                GOSUB QPHiLite                  'hi-lite the new cell

             '----- F2 function key (Edit Cell)
             CASE 60
                LSET Status$ = "EDIT"           'set the status msg. to EDIT
                LOCATE UlRow, BrCol - 6, 0      'print it
                QPrint0 Status$, BorderClr
                                                'calc the edit window size
                EdLen = BrCol - UlCol - LEN(CellAddr$) - 2
                Ed$ = SPACE$(EdLen)             'make an edit buffer string
                LSET Ed$ = Wks$(WkRow, WkCol)   'put the cell's contents in it
                LOCATE , , 0                    'turn the cursor off
                                                'call the editor routine
                Editor Ed$, EdLen, XCode, 0, 0, 31, 112, UlRow + 1, UlCol + LEN(CellAddr$) + 2
                GOTO QPCellEdit                 'update cell contents and
                                                '  re-calc
             '----- F5 function key (GOTO cell address)
             CASE 63                            'compose the column letter
                GOSUB QPMakeCellAd              'make cell address string
                OWkRow = WkRow
                OWkCol = WkCol
                DO                              'prompt the user for address
                    LSET Lin$ = "Enter address to go to: "
                    LOCATE UlRow + 1, UlCol + 1
                    QPrint0 Lin$, -1            'print the prompt
                    EdLen = BrCol - UlCol - 24  'calculate edit line length
                    Ed$ = SPACE$(EdLen)
                    Ok = 0                      'put current address in edit
                    LSET Ed$ = CellAddr$        '  string
                    LOCATE , , 0                'turn cursor off
                                                'call the editor routine
                    Editor Ed$, EdLen, XCode, 0, 0, 31, 112, UlRow + 1, UlCol + 24
                    IF XCode <> 2 THEN          'if user didn't press Escape
                       Ed$ = UCASE$(LTRIM$(RTRIM$(Ed$))) 'chop if up
                       EdLtr$ = ""              'parse up the address into
                       FOR N = 1 TO LEN(Ed$)    '  column letter and row #
                           IF MID$(Ed$, N, 1) < "A" THEN
                              EdLtr$ = LEFT$(Ed$, N - 1)
                              WkRow = VAL(MID$(Ed$, N))
                              EXIT FOR
                           END IF
                       NEXT

                       IF LEN(EdLtr$) = 1 THEN 'single char. column letter
                          WkCol = ASC(EdLtr$) - 64
                       ELSEIF LEN(EdLtr$) = 2 THEN 'double char. column letter
                          WkCol = ((ASC(EdLtr$) - 64) * 26) + (ASC(MID$(EdLtr$, 2)) - 64)
                       END IF
                                                'handle bad addresses
                       IF N > LEN(Ed$) OR EdLtr$ = "" OR WkRow < 1 OR WkRow > UBOUND(Wks$, 1) OR WkCol > UBOUND(Wks$, 2) THEN
                          BEEP                  'tell the user it's bad
                          LSET Lin$ = "Illegal cell or range address.  Press any key to continue."
                          LOCATE UlRow + 1, UlCol + 1
                          QPrint0 Lin$, -1
                          K$ = INPUT$(1)        'wait for user to acknowlege
                                                'bail out if they Escaped
                          IF K$ = CHR$(27) THEN XCode = 2
                       ELSE                     'no problem,
                          Ok = -1               'set OK flag to true
                       END IF
                    END IF
                                  
                LOOP WHILE NOT Ok AND XCode <> 2 'go back for more if not okay
                IF XCode = 2 THEN
                   WkRow = OWkRow
                   WkCol = OWkCol
                END IF
                                                 'erase the hi-lite
                PaintBox0 OUlR, OUlC, OUlR, OUlC + ColWdths(OWkCol) - 1, WorkClr
                GOSUB QPPrintCell               'display new cell's contents
                DoWork = 0                      'flag to re-print worksheet
                                                'check current row range
                IF WkRow < UlCelRow OR WkRow > UlCelRow + Rows - 3 THEN
                                                'out of bounds, set upper left
                   UlCelRow = MinInt(WkRow, UBOUND(Wks$, 1) - Rows + 3)
                   DoWork = -1                  '  row number and flag to reprint
                END IF
                                                'check current column range
                IF WkCol < UlCelCol OR WkCol >= C THEN
                                                'out of bounds, set upper left
                   UlCelCol = WkCol
                   GOSUB ChkUlCelCol
                   GOSUB QPPrintHdr             '  col. number and flag to
                   DoWork = -1                  '  re-print
                END IF
                IF DoWork THEN GOSUB QPPrintWork  're-print worksheet
                GOSUB QPHiLite                    'hi-lite current cell
               
             '----- HOME key pressed
             CASE 71                            'erase the cell hi-lite
                PaintBox0 OUlR, OUlC, OUlR, OUlC + ColWdths(OWkCol) - 1, WorkClr
                UlCelRow = 1                    'set upper left address to 1
                UlCelCol = 1
                WkRow = 1                       'set current cell address to 1
                WkCol = 1
                GOSUB QPPrintHdr                're-print the header
                GOSUB QPPrintCell               'display new cell's contents
                GOSUB QPPrintWork               're-print the worksheet
                GOSUB QPHiLite                  'hi-lite the new cell

             '----- F9 function key (Re-Calc.)
             CASE 67
                GOSUB QPCalcAll                 're-calculate whole worksheet
               
             CASE ELSE                          'no other keys valid
               'BEEP                            'unREM to beep at bad keys

           END SELECT
        END IF

    LOOP UNTIL Ky$ = "/" OR Ky$ = CHR$(27)      'go back for more unless the
                                                '  "/" key or Escape pressed
    EXIT SUB                                    'bail out


'----- Hi-lite the current cell and save coordinates for later
QPHiLite:
    UlR = WkRow - UlCelRow + UlRow + 3          'screen row number
                                                'left character column number
    UlC = ColPtrs(WkCol) - ColPtrs(UlCelCol) + UlCol + 5
                                                'paint the hi-lite
    PaintBox0 UlR, UlC, UlR, UlC + ColWdths(WkCol) - 1, HiClr
   
    OUlR = UlR                                  'save row number
    OUlC = UlC                                  'save column number
    OWkCol = WkCol                              'save worksheet column number

RETURN


'----- Compose a cell address string from the row and column numbers
QPMakeCellAd:
    IF WkCol > 26 THEN                          '2 character label
       Ltr$ = CHR$(((WkCol - 1) \ 26) + 64) + CHR$(((WkCol - 1) MOD 26) + 65)
    ELSE
       Ltr$ = CHR$(WkCol + 64)                  '1 character label
    END IF
    CellAddr$ = Ltr$ + LTRIM$(STR$(WkRow))      'add row # to column letter
RETURN


'----- Print the column header labels
QPPrintHdr:
    LOCATE UlRow + 2, UlCol + 5
    QPrint0 MID$(Head$, ColPtrs(UlCelCol), BrCol - UlCol - 7), -1
RETURN


'----- Print the current cell's contents on top line of window
QPPrintCell:
    LOCATE UlRow + 1, UlCol + 1                 'move to top line of window

    GOSUB QPMakeCellAd                          'make the cell address string
    LSET Lin$ = CellAddr$                       'add cell contents to it
    MID$(Lin$, LEN(CellAddr$) + 2) = Wks$(WkRow, WkCol)
    QPrint0 Lin$, -1                            'print it
RETURN


'----- Check a new right cell for out of bounds
ChkUlCelCol:
    FOR C = UlCelCol + 1 TO UBOUND(Wks$, 2) ' that page.
        LnPs = ColPtrs(C) - ColPtrs(UlCelCol) + 5
        IF LnPs > LnLin THEN EXIT FOR
    NEXT
    IF C > UBOUND(Wks$, 2) THEN     'if past end of array, work
       LnWdth = 0                   '  backwards from there.
       FOR C = UBOUND(Wks$, 2) TO 1 STEP -1
           LnWdth = LnWdth + ColWdths(C)
           IF LnWdth + 5 > LnLin THEN EXIT FOR
       NEXT
       UlCelCol = C + 1             'reset upper left column
    END IF                          'erase the cell hi-lite
RETURN




'----- Print a page of the worksheet's contents
QPPrintWork:
    LSET Status$ = ""                           'clear the status box
    LOCATE UlRow, BrCol - 6, 0
    QPrint0 Status$, BorderClr

    ScrRow = UlRow + 3                          'calc. the screen row to start
    LnLin = LEN(Lin$)                           'get the length of a line
    FOR R = UlCelRow TO UlCelRow + Rows - 3     'for each worksheet row,
        GOSUB QPComposeLn                       'compose a line of data
        LOCATE ScrRow, UlCol + 1
        QPrint0 Lin$, -1                        'print the row
        ScrRow = ScrRow + 1                     'increment the screen row #
    NEXT
RETURN


'----- Compose a line of spread sheet data
QPComposeLn:
    LSET Lin$ = LTRIM$(STR$(R))                 'clear line to worksheet row #
    FOR C = UlCelCol TO UBOUND(Wks$, 2)         'start at upper left column
                                                'calculate offset into line
        LnPs = ColPtrs(C) - ColPtrs(UlCelCol) + 5
                                                'if it's past line the length,
        IF LnPs + ColWdths(C) - 1 > LnLin THEN EXIT FOR ' bail out
        IF LEN(Wks$(R, C)) THEN                 'if anything in cell array,
           LSET ColBuf$(C) = ""                 '  clear the column's buffer
           MID$(Lin$, LnPs, ColWdths(C)) = ColBuf$(C) 'clear it's part of $

           SELECT CASE LEFT$(Wks$(R, C), 1)     'branch according to left char

              CASE "'"                          'left justified string
                 MID$(Lin$, LnPs) = MID$(Wks$(R, C), 2)

              CASE "^"                          'centered string
                 Offset = (ColWdths(C) - LEN(Wks$(R, C))) \ 2
                 IF Offset < 0 THEN Offset = 0
                 MID$(Lin$, LnPs + Offset) = MID$(Wks$(R, C), 2)

              CASE CHR$(34), "`"                'right justified string
                 Offset = ColWdths(C) - LEN(Wks$(R, C))
                 IF Offset < 0 THEN Offset = 0
                 MID$(Lin$, LnPs + Offset) = MID$(Wks$(R, C), 2)

              CASE ELSE                         'must be a number
                 IF LEN(Frmt$(R, C)) THEN       'is there a formatting string?
                    Fmt$ = FUsing$(Wks$(R, C), Frmt$(R, C))  'yes, format it
                                                'see if it fits in cell
                    IF LEFT$(Fmt$, 1) = "%" OR ColWdths(C) - LEN(Fmt$) < 0 THEN
                       Fmt$ = STRING$(ColWdths(C) - 1, "*")
                    END IF                      'put it in line
                    MID$(Lin$, LnPs + ColWdths(C) - LEN(Fmt$) - 1) = Fmt$
                 ELSE                           'no formatting string
                    Temp$ = LTRIM$(Wks$(R, C))
                    MPos = ColWdths(C) - LEN(Temp$) - 1'Does it fit?
                    IF MPos <= 0 THEN           'no make it all stars
                       MID$(Lin$, LnPs) = STRING$(ColWdths(C) - 1, "*")
                    ELSE                        'put it in the line
                       MID$(Lin$, LnPs + MPos) = Temp$
                    END IF
                 END IF
           END SELECT
        END IF
    NEXT
RETURN


'----- Process edited cell
QPCellEdit:
    Ky$ = ""                                    'clear the key pressed
    IF XCode <> 2 THEN                          'if user didn't press Escape
       Ed$ = LTRIM$(RTRIM$(Ed$))                'chop up the edited string
       IF FRE(Wks$(1, 1)) < LEN(Ed$) + 400 THEN 'if there isn't enough string
          BEEP                                  '  space, inform the user
          LSET Lin$ = "Out of memory!  Press any key to continue."
          LOCATE UlRow + 1, UlCol + 1
          QPrint0 Lin$, -1
          K$ = INPUT$(1)                        'wait for a key press
       ELSE
          IF LEN(Ed$) = 0 THEN                  'if it's a nul $ make cell nul
             Wks$(WkRow, WkCol) = ""
                                                'is it a number?
          ELSEIF INSTR(NumTable$, LEFT$(Ed$, 1)) THEN
             Wks$(WkRow, WkCol) = STR$(VAL(Ed$))'yes, make a numeric string
                                                'no justification string?
          ELSEIF INSTR(DispCode$, LEFT$(Ed$, 1)) = 0 THEN
             Wks$(WkRow, WkCol) = "'" + Ed$     'make it left justified
          ELSE
             Wks$(WkRow, WkCol) = Ed$           'all set, just assign it
          END IF
   
          GOSUB QPPrintCell                     'display contents in window
          GOSUB QPCalc1                         'recalculate based on this cell
       END IF
      
       SELECT CASE XCode                        'branch according to editor
                                                '  exit code
         CASE 0, 4                              'Enter, Tab - do nothing
         CASE 1                                 'Up arrow,
            Ky$ = CHR$(0) + CHR$(72)            'make "Ky$" into an Up arrow
         CASE 3                                 'Down arrow
            Ky$ = CHR$(0) + CHR$(80)            'make "Ky$" into a Down arrow
         CASE ELSE                              'nothing else valid
           'BEEP                                'unREM to beep at bad keys
       END SELECT

    ELSE
       GOSUB QPPrintCell                        'Escape pressed, reprint old
    END IF                                      '  cell contents
GOTO QPExtKey                                   'go back to extended key
                                                '  processing


'----- Re-calculate the entire worksheet
QPCalcAll:
    LSET Status$ = "WAIT"                       'put "WAIT" in status string
    LOCATE UlRow, BrCol - 6, 0
    QPrint0 Status$, 192                        'print the status message

    '************************************************************************
    '* Put the calculations for your spreadsheet here.  You could also read *
    '* them from an $INCLUDE file, perhaps called "CalcAll.Bas".  The code  *
    '* in this section is executed each time the Calc key (F9) is pressed.  *
    '* The following is an example for this spreadsheet:                    *
    '************************************************************************
    '                                                                       *
    REDIM TotValue#(25)                         'make array for totals      *
    GrandTotal# = 0                             'clear the grand total      *
    FOR R = 6 TO 30                             'read each row of values    *
        Quant# = VAL(Wks$(R, 2))                'get the quantity           *
        UnitPrice# = VAL(Wks$(R, 4))            'get the unit price         *
        TotValue#(R - 6) = Quant# * UnitPrice#  'calc. the current Value    *
        Wks$(R, 5) = STR$(TotValue#(R - 6))     'assign it to its column    *
        GrandTotal# = GrandTotal# + TotValue#(R - 6) 'add to grand total    *
    NEXT                                        '                           *
    Wks$(32, 5) = STR$(GrandTotal#)             'assign the grand total$    *
    '                                                                       *
    '************************************************************************

    GOSUB QPPrintWork                           're-print the worksheet page
    GOSUB QPPrintCell                           'and the cell at the top line

RETURN


'----- Re-calculate the worksheet based on a change in one cell
QPCalc1:
    '************************************************************************
    '* Put the calculations for your spreadsheet here.  You could also read *
    '* them from an $INCLUDE file if you prefer.  This block of code is     *
    '* executed each time a cell has been edited.  The following is an      *
    '* example for this spreadsheet.                                        *
    '*                                                                      *
    '* Notice that the variables WkRow and WkCol hold the coordinates for   *
    '* the cell that has just been edited, and may be examined to determine *
    '* which cells need to be updated.                                      *
    '************************************************************************
    '
    IF WkRow >= 6 AND WkRow <= 30 THEN          'if edited cell is in range *
       Quant# = VAL(Wks$(WkRow, 2))             'get the quantity           *
       UnitPrice# = VAL(Wks$(WkRow, 4))         'get the unit price         *
       TotValue#(WkRow - 6) = Quant# * UnitPrice#  'calculate total value   *
       Wks$(WkRow, 5) = STR$(TotValue#(WkRow - 6)) 'assign a string version *
       GrandTotal# = 0                             'init grand total        *
       FOR R = 0 TO 25                             'add up grand total      *
           GrandTotal# = GrandTotal# + TotValue#(R) '                       *
       NEXT                                     '                           *
       Wks$(32, 5) = STR$(GrandTotal#)          'assign grand total         *
    END IF                                      '                           *
    '                                                                       *
    '************************************************************************

    GOSUB QPPrintWork                           'reprint the worksheet page
    GOSUB QPPrintCell                           'and the cell at the top line
      
RETURN

END SUB

