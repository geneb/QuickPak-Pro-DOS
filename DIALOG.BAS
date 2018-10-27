'********** DIALOG.BAS - complete dialog box subprogram

'Copyright (c) 1990 Crescent Software
'written by Phil Cramer

DEFINT A-Z

'----BASIC Subs
DECLARE FUNCTION LongestStr1% (Text$(), NumButtons, ItemNum)

'---- Assembler Subs
DECLARE SUB Box0 (ULRow, ULCol, LRRow, LRCol, Char, Colr)
DECLARE SUB ClearScr0 (ULRow, ULCol, LRRow, LRCol, Colr)
DECLARE SUB InitMouse (There)
DECLARE SUB MScrnSave (ULRow, ULCol, LRRow, LRCol, SEG Element)
DECLARE SUB MAMenu (BYVAL Address, Selection, Start, Count, ExitCode, FileColr, HiLiteColr, Rows, Columns, Spacing, Row, Column)
DECLARE SUB MEditor (Ed$, ActiveLength, ScanCode, NumOnly, CapsOn, NormalClr, EditClr, Row, Column, CurrentColumn)
DECLARE SUB MouseRange (SEG Element AS ANY, NumEls, Row, Column, Button, Range)
DECLARE SUB MScrnRest (ULRow, ULCol, LRRow, LRCol, SEG Element)
DECLARE SUB PaintBox0 (ULRow, ULCol, LRRow, LRCol, Colr)
DECLARE SUB QPrint0 (X$, Colr)
DECLARE SUB ShowCursor ()
DECLARE SUB SplitColor (Colr, FG, BG)
DECLARE SUB StuffBuf (Char$)
DECLARE SUB InstallKeyDown ()

'---- ASM functions
DECLARE FUNCTION ArraySize% (ULRow, ULCol, LRRow, LRCol)
DECLARE FUNCTION OneColor% (FG, BG)
DECLARE FUNCTION KeyDown% ()


TYPE DLog
  DType AS INTEGER           'Type i.e. 0=Plain Text, 1=Button 2=Check Box,
                             ' 3=Option Box 4=Text Input Box, 5=List Box
  TextLen AS INTEGER         'Length of text to be entered
  NumFlag AS INTEGER         'Num only flag for MEditor
  Row AS INTEGER             'Starting row
  Col AS INTEGER             'Starting column
END TYPE

TYPE Area                    'Type definition for MouseRange
  ULRow AS INTEGER
  ULCol AS INTEGER
  LRRow AS INTEGER
  LRCol AS INTEGER
  NumWindow AS INTEGER
END TYPE

CONST Check$ = "X"           'Character for Check boxes
CONST Cancel$ = "CANCEL"

'Change the constants below for the screen mode that you will be using
CONST VMid = 13              'Center of screen for 25 row mode                                                                                         -+               'Center of screen for 50 line mode
CONST HMid = 41              'Center of screen for 80 column mode

SUB Dialog (Choice1, Text$(), Response$(), Menu$(), ScrnRow, Style, BClr, Action) STATIC
                        '^
                        'ÀÄÄÄ Insert a "1" for TextCopy [change to Text1$()]

'****************************************************************************
'* Note: Dialog internally modifies the Text$() array. Depending on how you
'*       set up your program, this may or may not be a problem. If you do not
'*       want the array modified, search for "TextCopy" and do as comments
'*       indicate. This will cause Dialog to work on a copy of the Text$()
'*       array instead of the actual Text$() array.                       
'****************************************************************************

'TYPE DLog                    'Type for Dialog Box data
'  DType AS INTEGER           'Type i.e. 0=Plain Text, 1=Button 2=Check Box,
'                             ' 3=Option Box 4=Text Input Box, 5=List Box
'  TextLen AS INTEGER         'Length of text to be entered
'  NumFlag AS INTEGER         'Num only flag for MEditor
'  Row AS INTEGER             'Starting row
'  Col AS INTEGER             'Starting column
'END TYPE

CALL InstallKeyDown           'Install routine to check for keys held down

Choice = Choice1
IF Action = 5 AND Choice = -1 THEN GOTO Escape
IF Action = 5 THEN GOTO Done
IF Action = 4 THEN Action = 3
IF Action = 3 GOTO KeyLoop
IF Action = 2 THEN
  Temp$ = INKEY$
  GOTO DispResponse
END IF
IF Action = 1 THEN Action = 3

MenuCount = UBOUND(Menu$, 1)
MenuCols = 1                              'Default number of menu columns
MCount = UBOUND(Menu$, 1)
StartItem = 1                             'Place item one at top of menu
Dot$ = CHR$(7)                            'Ascii character for option buttons

'----Hilite color will be Bright White unless foreground color is Bright White
FFg = 15
CALL SplitColor(BClr, FG, BG)
IF FG = 15 THEN FFg = 0'If foreground color is Bright White, make hilite Black
HiLite = OneColor%(FFg, BG)
HiClr = HiLite
 
'----These variables need to be re-initialized each time Dialog is called
NumXBoxes = 0          'Number of Option buttons
LastXBox = 0           'Re-init LastXBox
NumChoices = 0         'Number of selectable choices
NumButtons = 0         'Number of buttons on bottom row
Button$ = ""
BWidth = 0
BHite = 0
MenuHite = 0
MenuWidth = 0
MOS = 0
TLen = 0
ItemNum = 0
ButtonsOnly = 0
Choice1 = 0
Found = 0

Choice = 1             'Choice keeps track of which button is active
WindowNum = 1          'First mouse range window
UpperBound = UBOUND(Text$, 1)               'TextCopy--Change Text$ to Text1$
UpBound = UBOUND(Response$, 1)
Selection = 1          'Menu will start on item 1

'*** Un-Rem for TextCopy ***
'REDIM Text$(UpperBound)                    'Make a copy of the Text$() Array
'FOR i = 1 TO UpperBound                    ' since it gets modified
'  Text$(i) = Text1$(i)
'NEXT

REDIM Dial(UpperBound) AS DLog
REDIM TResponse$(UpBound)                  'Keep an un-edited version
FOR i = 1 TO UpBound                       ' of the Response$()
  TResponse$(i) = Response$(i)             ' in case of Cancel/Esc
NEXT

BHite = 4                                  'Minimum box height
FOR i = 1 TO UpperBound
  Temp = ASC(Text$(i))
  SELECT CASE Temp
  
    CASE 60                                '** "<" Command button
      NumChoices = NumChoices + 1
      NumButtons = NumButtons + 1
      Dial(i).DType = 1                    'Type identifier
  
    CASE 91                                '** "[" Check Box
      BHite = BHite + 1                    'Inc overall box height
      NumChoices = NumChoices + 1          'inc number of choices
      Dial(i).DType = 2                    'Type identifier
  
    CASE 40                                '** "(" Option Button
      BHite = BHite + 1                    'Inc overall box height
      NumChoices = NumChoices + 1          'Inc number of choices
      Dial(i).DType = 3                    'Type identifier
      LastXBox = i
      NumXBoxes = NumXBoxes + 1            'Keep track of num Option buttons

    CASE 124                               '** "|" Menu
      MenuWidth = LEN(Menu$(1))
      NumChoices = NumChoices + 1
      Dial(i).DType = 5
      MenuRows = INSTR(2, Text$(i), "|")
      ItemNum = i
      MOS = 4

    SELECT CASE MenuRows                   'Check for Menu Height

      CASE 3                               'Single digit
        MenuHite = VAL(MID$(Text$(i), 2, 1)) + 8
        Text$(i) = RIGHT$(Text$(i), LEN(Text$(i)) - 3)

      CASE 4                               'Two digits
        MenuHite = VAL(MID$(Text$(i), 2, 2)) + 8
        Text$(i) = RIGHT$(Text$(i), LEN(Text$(i)) - 4)

      CASE 5                               'Three digits
        MenuHite = VAL(MID$(Text$(i), 3, 2)) + 8
        MenuCols = VAL(MID$(Text$(i), 2, 1))
        MenuWidth = MenuWidth * MenuCols + (MenuCols - 1) * 2
        Text$(i) = RIGHT$(Text$(i), LEN(Text$(i)) - 5)
      CASE ELSE

    END SELECT

    CASE 123                               '** "{" Text input box
    BHite = BHite + 4                      ' takes up 4 screen rows
    NumChoices = NumChoices + 1            'Inc number of choices
    Dial(i).DType = 4                      'Type identifier
    NumEnd = INSTR(Text$(i), "}")
   
    SELECT CASE NumEnd                     'Check for input length
    
      CASE 3                               'Single digit
        Dial(i).TextLen = VAL(MID$(Text$(i), 2, 1))
        Text$(i) = RIGHT$(Text$(i), LEN(Text$(i)) - 3)
        Dial(i).NumFlag = 0                  'Set Num only flag for Editor OFF

      CASE 4                               'Two digits
        Dial(i).TextLen = VAL(MID$(Text$(i), 2, 2))
        Text$(i) = RIGHT$(Text$(i), LEN(Text$(i)) - 4)
        Dial(i).NumFlag = 0                  'Set Num only flag for Editor OFF

      CASE 5                               'Three digits
        Dial(i).TextLen = VAL(MID$(Text$(i), 3, 2))
        Text$(i) = RIGHT$(Text$(i), LEN(Text$(i)) - 5)
        Dial(i).NumFlag = 1                  'Set Num only flag for Editor ON
           
      CASE ELSE
      
    END SELECT

                        'Trim the passed string if its longer than edit length
    IF LEN(Response$(i)) > Dial(i).TextLen THEN Response$(i) = LEFT$(Response$(i), Dial(i).TextLen)
                        'Left justify Response$ in edit field for later
    Response$(i) = Response$(i) + SPACE$(Dial(i).TextLen - LEN(Response$(i)))
                       
    IF Dial(i).TextLen + 4 > BWidth THEN BWidth = Dial(i).TextLen + 4

  CASE ELSE                                'Plain string
    Dial(i).DType = 0                      'Type identifier
    BHite = BHite + 1
    IF Text$(i) = " " THEN Text$(i) = ""
  END SELECT
 
NEXT

IF MenuHite > BHite THEN BHite = MenuHite
IF BHite < 9 AND ItemNum THEN BHite = 9    'Minimum Height for Menu is 2
LS = LongestStr1(Text$(), NumButtons, ItemNum) 'Compare longest string from
IF LS + 6 > BWidth THEN BWidth = LS + 6    ' text array with Title + 6
FOR i = 1 TO NumButtons
  TLen = TLen + LEN(Text$(i)) + 2          'Buttons will always have at
NEXT                                       ' least 2 spaces between them

IF ItemNum = UpperBound AND NumButtons + 1 = UpperBound THEN BWidth = BWidth - 6
BWidth = BWidth + MenuWidth + MOS

IF TLen > BWidth THEN BWidth = TLen        'Compare to total button width

IF ScrnRow THEN
  ULRow = CSRLIN                           'Locate corners of box
ELSE
  ULRow = VMid - (BHite \ 2)
END IF

ULCol = HMid - (BWidth \ 2)
LRRow = BHite + ULRow - 1
LRCol = BWidth + ULCol - 1

TLen = 0
FOR i = 1 TO NumButtons                    'Find spacing for buttons
  TLen = LEN(Text$(i)) + TLen              'Accumulate string length
NEXT
AvgSpc = (LRCol - ULCol + 1 - TLen) \ (NumButtons + 1)
IF NumButtons = 1 THEN OS = 1

REDIM MouseBox(NumChoices) AS Area

FOR i = 1 TO NumButtons                    'Make button string
  Button$ = Button$ + STRING$(AvgSpc, CHR$(32)) + Text$(i)
  MouseBox(i).ULRow = LRRow - 1            'Define mouse windows for buttons
  MouseBox(i).LRRow = MouseBox(i).ULRow
  MouseBox(i).ULCol = ULCol + LEN(Button$) - (LEN(Text$(i)) - 1 + OS)
  MouseBox(i).LRCol = MouseBox(i).ULCol + (LEN(Text$(i)) - 1)
  MouseBox(i).NumWindow = i
  Dial(i).Row = MouseBox(i).ULRow        'Define row
  Dial(i).Col = MouseBox(i).ULCol + 2    'Define column
  WindowNum = WindowNum + 1
NEXT

REDIM Scrn(ArraySize(ULRow, ULCol, LRRow + 1, LRCol + 2))
CALL MScrnSave(ULRow, ULCol, LRRow + 1, LRCol + 2, SEG Scrn(0))
                     
                       'Draw the basic dialog box

CALL ClearScr0(ULRow, ULCol, LRRow, LRCol, BClr)
IF Style > 4 THEN      'Paint drop shadow
  CALL PaintBox0(LRRow + 1, ULCol + 3, LRRow + 1, LRCol + 1, 8)
  CALL PaintBox0(ULRow + 1, LRCol + 1, LRRow + 1, LRCol + 2, 8)
END IF

Style = Style MOD 10
CALL Box0(ULRow, ULCol, LRRow, LRCol, Style, BClr)  'Draw the box
TLen = LEN(Text$(0))
LOCATE ULRow, HMid - (TLen \ 2)
CALL QPrint0(Text$(0), BClr)    'Print the box title if there is one

SELECT CASE Style               'Determine appropriate line types for divider
  CASE 1                      'Ã
    L = 195
    R = 180
    Char = 196
  CASE 2                      'Ì
    L = 204
    R = 185
    Char = 205
  CASE 3                      'Æ
    L = 198
    R = 181
    Char = 205
  CASE 4                      'Ç
    L = 199
    R = 182
    Char = 196
END SELECT
              'Draw divider between button line and the rest of the Dialog box
Divider$ = CHR$(L) + STRING$(LRCol - ULCol - 1, Char) + CHR$(R)
LOCATE LRRow - 2, ULCol
CALL QPrint0(Divider$, BClr)

IF OS THEN Button$ = RIGHT$(Button$, (LEN(Button$) - 1))
LOCATE LRRow - 1, ULCol + 1
CALL QPrint0(Button$, BClr)

RowPtr = 1
FOR i = (NumButtons + 1) TO UpperBound
  SELECT CASE Dial(i).DType                'Display based on type
    
    CASE 0            'Plain text
      RowPtr = RowPtr + 1

    CASE 2, 3         'Check box
      LOCATE ULRow + RowPtr, ULCol + 3
      CALL QPrint0(Text$(i), BClr)
      MouseBox(WindowNum).ULRow = ULRow + RowPtr    'Define mouse window
      MouseBox(WindowNum).LRRow = MouseBox(WindowNum).ULRow
      MouseBox(WindowNum).ULCol = ULCol + 4
      MouseBox(WindowNum).LRCol = MouseBox(WindowNum).ULCol + LEN(Text$(i)) - 2
      MouseBox(WindowNum).NumWindow = i
      Dial(i).Row = MouseBox(WindowNum).ULRow         'Define row
      Dial(i).Col = MouseBox(WindowNum).ULCol         'Define column
      WindowNum = WindowNum + 1
      RowPtr = RowPtr + 1

    CASE 4            'Text in
      MW = (MenuWidth + MOS) \ 2
      LOCATE ULRow + RowPtr, HMid - MW - 1 - (Dial(i).TextLen \ 2)
      CALL QPrint0(Text$(i), BClr)
      CALL Box0(ULRow + RowPtr + 1, HMid - MW - 1 - (Dial(i).TextLen \ 2), ULRow + RowPtr + 3, HMid - MW - (Dial(i).TextLen \ 2) + Dial(i).TextLen, 1, BClr)
      MouseBox(WindowNum).ULRow = ULRow + 2 + RowPtr
      MouseBox(WindowNum).LRRow = MouseBox(WindowNum).ULRow
      MouseBox(WindowNum).ULCol = HMid - (Dial(i).TextLen \ 2) - ((MenuWidth + MOS) \ 2)
      MouseBox(WindowNum).LRCol = MouseBox(WindowNum).ULCol + Dial(i).TextLen - 1
      MouseBox(WindowNum).NumWindow = i
      Dial(i).Row = MouseBox(WindowNum).ULRow
      Dial(i).Col = MouseBox(WindowNum).ULCol
      WindowNum = WindowNum + 1
      RowPtr = RowPtr + 4
   
    CASE 5            'Menu
      Dial(i).Row = ULRow + 4
      Dial(i).Col = LRCol - MenuWidth - 1
      LOCATE Dial(i).Row - 2, Dial(i).Col - 1
      CALL QPrint0(Text$(i), BClr)
      CALL Box0(Dial(i).Row - 1, Dial(i).Col - 1, LRRow - 3, Dial(i).Col + MenuWidth, 1, BClr)
      MouseBox(WindowNum).ULRow = Dial(i).Row
      MouseBox(WindowNum).LRRow = Dial(i).Row + BHite - 9
      MouseBox(WindowNum).ULCol = Dial(i).Col
      MouseBox(WindowNum).LRCol = Dial(i).Col + MenuWidth - 1'MouseBox(WindowNum).ULCol + Dial(i).TextLen - 1
      MouseBox(WindowNum).NumWindow = i
      WindowNum = WindowNum + 1

    CASE ELSE

  END SELECT
NEXT


DispResponse:
RowPtr = 1

LOCATE , , 0
FOR i = NumButtons TO UpperBound
  SELECT CASE Dial(i).DType                'Display Response$()

    CASE 0            'Plain text
      LOCATE ULRow + RowPtr, HMid - (LEN(Text$(i)) \ 2) - ((MenuWidth + MOS) \ 2)
      CALL QPrint0(Text$(i), BClr)
      RowPtr = RowPtr + 1

    CASE 2, 3         'Check box
      IF LEN(Response$(i)) THEN
        LOCATE ULRow + RowPtr, ULCol + 4
        CALL QPrint0(Response$(i), BClr)
        IF Response$(i) = Dot$ THEN DotEl = i
      END IF
      RowPtr = RowPtr + 1
   
    CASE 4            'Text in

      LOCATE ULRow + 2 + RowPtr, HMid - (Dial(i).TextLen \ 2) - ((MenuWidth + MOS) \ 2)
      CALL QPrint0(Response$(i), BClr)
      RowPtr = RowPtr + 4

    CASE 5            'Menu

      CALL StuffBuf(CHR$(13))
      HClr = BClr
      IF Action = 2 THEN
        HClr = 15
        IF Selection > UBOUND(Menu$, 1) THEN Selection = 1
        IF StartItem > UBOUND(Menu$, 1) THEN StartItem = 1
      END IF
      CALL MAMenu(BYVAL VARPTR(Menu$(1)), Selection, StartItem, UBOUND(Menu$, 1), MenuScanCode, BClr, HClr, BHite - 8, MenuCols, 2, Dial(ItemNum).Row, Dial(ItemNum).Col)
      MCount = UBOUND(Menu$, 1)
      Response$(i) = ""                        'Clear last choice
    CASE ELSE

  END SELECT
NEXT
LOCATE , , 1

IF Action <> 2 THEN
  LCount = NumButtons
  IF NumChoices > NumButtons THEN        'If we have more choices than buttons
    DO                                   'Find and locate the cursor at the
      LCount = LCount + 1                ' first editable field
    LOOP UNTIL Dial(LCount).DType
    LOCATE Dial(LCount).Row, Dial(LCount).Col, 1, 0, 7
    El = LCount
  ELSE                                   'Else locate cursor at first button
    ButtonsOnly = -1
    El = 1
  END IF
               'If we only have button choices, locate cursor on first button
  IF ButtonsOnly THEN LOCATE Dial(1).Row, Dial(1).Col, 1, 0, 7
  CALL StuffBuf(CHR$(245))               'Fall through loop first time
ELSE           'If were re-displaying, locate cursor in previous field
  IF LEN(Temp$) THEN
    CALL StuffBuf(Temp$)
  ELSE
    CALL StuffBuf(CHR$(245))             'Fall through loop
  END IF
  Action = 3
  LOCATE Dial(El).Row, Dial(El).Col
END IF

GOSUB HiLite                           'HiLite Button 1 (Usually < OK >)
CALL ShowCursor                        'Turn on mouse cursor
CurCol = Dial(El).Col

KeyLoop:
DO
  DO
    Ky$ = INKEY$
    IF LEN(Ky$) THEN MFlag = 0
  
    'MButton = 0   EW: no longer needed
    CALL MouseRange(SEG MouseBox(1), NumChoices, MRow, MCol, MButton, RangeNum)
    IF MButton > 0 AND RangeNum THEN   'If mouse down and its in a valid range
      IF RangeNum <> El THEN           'If we havent already turned off hilite,
        HiLite = BClr                  ' turn off old HiLite
        GOSUB HiLite
      END IF
      El = RangeNum
      IF El <= NumButtons THEN         'If we've clicked on a button
        Choice = El                    ' choice = button selected
        ButtonDown = -1                'Remember that mouse button was pressed
        CALL PaintBox0(LRRow - 1, MouseBox(Choice).ULCol + 1, LRRow - 1, MouseBox(Choice).LRCol - 1, 15)
      END IF
      MFlag = -1                       'Set Mouse flag
      Choice = RangeNum
      Ky$ = "š"                        'Dummy key to exit INKEY$ loop
    END IF
                  'If we've clicked on a button, wait 'till mouse button is up
  IF RangeNum <= NumButtons AND MButton = 0 AND ButtonDown THEN
     ButtonDown = 0
     CALL PaintBox0(LRRow - 1, MouseBox(Choice).ULCol + 1, LRRow - 1, MouseBox(Choice).LRCol - 1, BClr)
     GOTO Done                         'Exit Dialog box
  END IF

  LOOP UNTIL LEN(Ky$) OR Pressed
  
  IF NOT Pressed THEN                  'If a keystroke and not a mouse click
    IF LEN(Ky$) < 2 THEN
      Ky = ASC(Ky$)
    ELSE
      Ky = -ASC(RIGHT$(Ky$, 1))
    END IF
  END IF

Again:
  SELECT CASE Ky

    CASE 9     'Tab
Again1:
      IF El <= NumButtons THEN
        HiLite = BClr
        GOSUB HiLite
      END IF
 
      El = El + 1                       'Inc Text$() element subscript
        Choice = Choice + 1             'Keep track of which button is active
      IF El > UpperBound OR NumChoices = NumButtons AND Choice > NumButtons THEN
        El = 1
        Choice = 1
      END IF
  
    CASE -15    'Shift Tab
Again2:
      El = El - 1                       'Dec Text$() element subscript
      IF El <= NumButtons THEN
        HiLite = BClr
        GOSUB HiLite
      END IF

      IF El <= NumButtons THEN
        Choice = El                     'Keep track of which button is active
      END IF
    
      IF El < 1 THEN
        El = UpperBound
        Choice = 1
      END IF
 
    CASE -72, -77   'Up, Right arrows
      IF Dial(El).DType = 3 AND Found THEN   'If we're on an Option button
        LOCATE Dial(El).Row, Dial(El).Col
        Response$(El) = ""
        CALL QPrint0(" ", BClr)              'Clear the last Dot
        El = El - 1
        IF El <= LastXBox - NumXBoxes THEN El = LastXBox
        DotEl = El                           'Remember where the new Dot is
        LOCATE Dial(El).Row, Dial(El).Col
        CALL QPrint0(Dot$, BClr)             'Print the new Dot
        Response$(El) = Dot$
        Found = 0
      END IF

    CASE -75, -80   'Left, Down arrows
      IF Dial(El).DType = 3 AND Found THEN   'If we're on an Option button
        LOCATE Dial(El).Row, Dial(El).Col
        Response$(El) = ""
        CALL QPrint0(" ", BClr)              'Clear the last Dot
        El = El + 1
        IF El > LastXBox THEN El = LastXBox - NumXBoxes + 1
        DotEl = El                           'Remember where the new Dot is
        LOCATE Dial(El).Row, Dial(El).Col
        CALL QPrint0(Dot$, BClr)             'Print the new Dot
        Response$(El) = Dot$
        Found = 0
      END IF

    CASE 32       'SpaceBar
      IF Dial(El).DType = 2 THEN             'If we're in a check box
        LOCATE Dial(El).Row, Dial(El).Col
        CALL HideCursor
        IF Response$(El) <> Check$ THEN      'If its not checked,
          CALL QPrint0(Check$, BClr)         ' check it
          Response$(El) = Check$
        ELSE                                 'If its checked,
          CALL QPrint0(" ", BClr)            ' clear it
          Response$(El) = ""
        END IF
        CALL ShowCursor
      ELSE
        GOTO Done
      END IF

    CASE 27       'Escape
      GOTO Escape

    CASE 13       'Enter
      GOTO Done
  
    CASE ELSE     'Ignore all other keys

  END SELECT
  
  IF Dial(El).DType <> 3 THEN Found = 0 'If were not on an Option button
                                        ' reset Found
  IF El > NumButtons THEN Choice = 1  'If we're off the button line, make
                                        ' make Button #1, < OK > the default
  HiLite = HiClr
  GOSUB HiLite

  IF Dial(El).DType = 3 AND NOT MFlag THEN    'Option button
    IF Found = 0 THEN      'If its the first time we've entered an
      El = DotEl           ' Option button field, locate cursor at dot
      Found = -1
      LOCATE Dial(El).Row, Dial(El).Col, 1, 0, 7
    
                           'If we're already in an XBox field, find the next
    ELSEIF Ky = 9 THEN     ' non-XBox field, and locate the cursor (FORWARD)
      Found = 0
      El = LastXBox
      GOTO Again1
                             'If we're already in an XBox field, find the next
    ELSEIF Ky = -15 THEN     ' non-XBox field, and locate the cursor (BACKWARD)
      Found = 0
      El = LastXBox - NumXBoxes + 1
      GOTO Again2
    END IF
 
  ELSEIF Dial(El).DType = 3 AND MFlag THEN  'If we've clicked on an Option
    CALL HideCursor                         ' button
    LOCATE Dial(DotEl).Row, Dial(DotEl).Col
    CALL QPrint0(" ", BClr)
    Response$(DotEl) = ""
    LOCATE Dial(El).Row, Dial(El).Col
    CALL QPrint0(Dot$, BClr)
    Response$(El) = Dot$
    CALL ShowCursor
    DotEl = El
    Found = -1

  ELSEIF Dial(El).DType = 0 THEN           'Skip plain text lines
    IF Ky = 9 THEN
      GOTO Again1
    ELSEIF Ky = -15 THEN
      GOTO Again2
    END IF

  ELSEIF Dial(El).DType = 2 THEN           'If we've clicked on a Checkbox
    LOCATE Dial(El).Row, Dial(El).Col
    IF MButton THEN Pressed = -1
    IF MButton = 0 AND Pressed THEN
      Pressed = 0
      CALL HideCursor
      IF Response$(El) <> Check$ THEN
        CALL QPrint0(Check$, BClr)
        Response$(El) = Check$
      ELSE
        CALL QPrint0(" ", BClr)
        Response$(El) = ""
      END IF
      CALL ShowCursor
    END IF
      
  ELSEIF Dial(El).DType = 4 THEN           'Text in box
    CurCol = Dial(El).Col
TextIn:
    EdLen = Dial(El).TextLen
    MERow = Dial(El).Row
    MECol = Dial(El).Col
    CALL MEditor(Response$(El), EdLen, ScanCode, Dial(El).NumFlag, 0, BClr, BClr, MERow, MECol, CurCol)
    CALL MouseRange(SEG MouseBox(1), NumChoices, MRow, MCol, MButton, RangeNum)
  
    IF ScanCode = 13 THEN          'ENTER
      GOTO Done
     
    ELSEIF ScanCode = 27 THEN      'Escape
      GOTO Escape
                            'Escape keys supported by MEditor, but not Dialog
    ELSEIF ScanCode > -132 AND ScanCode < -58 OR ScanCode > 31 AND ScanCode < 127 OR ScanCode = 8 THEN 'Extended key
      ScanCode = 1
      GOTO TextIn

    ELSEIF ScanCode = 1001 OR ScanCode = 1002 THEN     'Middle or Right
      ScanCode = 1                                     ' mouse button
      GOTO TextIn

    ELSEIF ScanCode = 1000 THEN    'Left mouse button pressed outside MEditor
      IF RangeNum THEN             'If clicked in a valid Dialog range        '
        El = RangeNum              ' set element to appropriate field
        IF El <= NumButtons THEN
          HiLite = BClr            'turn off old HiLite
          GOSUB HiLite
          Choice = El
          Choice1 = Choice
          ButtonDown = -1
        END IF
        IF Action = 3 THEN EXIT SUB
      ELSEIF NOT RangeNum THEN     'If not clicked in a valid range
        ScanCode = 1               ' reset ScanCode
        GOTO TextIn                ' go back to TextIn
      END IF
      LOCATE Dial(El).Row, Dial(El).Col, 1, 0, 7
      MFlag = -1
      Ky = 0
      GOTO Again
    ELSEIF ScanCode = -15 THEN
      MFlag = 0
      CALL StuffBuf(CHR$(0) + CHR$(15))
    ELSE
      MFlag = 0
      CALL StuffBuf(CHR$(9))
    END IF

  ELSEIF Dial(El).DType = 5 THEN           'Menu
Menu:
    LOCATE Dial(El).Row, Dial(El).Col
    MenuScanCode = MSCode
    MRow = Dial(ItemNum).Row
    MCol = Dial(ItemNum).Col
   
    LOCATE , , 0  'EW: 12-24-95 turn off cursor for AMenu scrolling menus
    CALL MAMenu(BYVAL VARPTR(Menu$(1)), Selection, StartItem, MCount, MenuScanCode, BClr, 15, BHite - 8, MenuCols, 2, MRow, MCol)
    CALL MouseRange(SEG MouseBox(1), NumChoices, MRow, MCol, MButton, RangeNum)
    Response$(El) = Menu$(Selection)
    LOCATE , , 1   'EW: 12-24-95

    IF MenuScanCode = 13 THEN              'ENTER
      GOTO Done

    ELSEIF MenuScanCode = 1003 THEN        'Double click
      Choice = 101
      Choice1 = Choice
      GOTO Done

    ELSEIF MenuScanCode = 27 THEN          'ESCAPE
      GOTO Escape
                            'Escape keys supported by MEditor, but not Dialog
    ELSEIF MenuScanCode > -132 AND MenuScanCode < -58 OR MenuScanCode > 31 AND MenuScanCode < 127 OR MenuScanCode = 8 THEN 'Extended key
      MSCode = 3
      GOTO Menu

    ELSEIF MenuScanCode = 1001 OR MenuScanCode = 1002 THEN 'Middle or Right
      MSCode = 3                                           ' mouse button
      GOTO Menu

    ELSEIF MenuScanCode = 1000 THEN    'Left mouse button pressed outside MAMenu
      IF RangeNum THEN             'If clicked in a valid Dialog range        '
        El = RangeNum              ' set element to appropriate field
        IF El <= NumButtons THEN
          HiLite = BClr            'turn off old HiLite
          GOSUB HiLite
          Choice = El
          Choice1 = Choice
          ButtonDown = -1
        END IF
        IF Action = 3 THEN EXIT SUB
      ELSEIF NOT RangeNum THEN     'If not clicked in a valid range
        MenuScanCode = 1           ' reset ScanCode
        GOTO Menu                  ' go back to MAMenu
      END IF
      LOCATE Dial(El).Row, Dial(El).Col, 1, 0, 7
      MFlag = -1
      Ky = 0
      GOTO Again
    ELSEIF MenuScanCode = -15 THEN
      MSCode = 3
      CALL StuffBuf(CHR$(0) + CHR$(15))
    ELSE
      MSCode = 3
      CALL StuffBuf(CHR$(9))
    END IF

  END IF

  IF Dial(El).DType = 1 THEN
    LOCATE Dial(El).Row, Dial(El).Col, 1, 0, 7  'Locate cursor at current button
  END IF                                        ' if were on a button

  Choice1 = Choice
  IF Action = 3 THEN EXIT SUB

LOOP

'-----Various GOSUBs

HiLite:                        'Hilites the currently active button
  CALL PaintBox0(LRRow - 1, MouseBox(Choice).ULCol, LRRow - 1, MouseBox(Choice).ULCol, HiLite)
  CALL PaintBox0(LRRow - 1, MouseBox(Choice).LRCol, LRRow - 1, MouseBox(Choice).LRCol, HiLite)
RETURN

Done:
  Choice1 = Choice
  IF INSTR(UCASE$(Text$(Choice MOD 100)), Cancel$) THEN
    GOTO Escape
  END IF
  IF Action = 0 OR Action = 5 THEN
    FirstXBox = (LastXBox + 1) - NumXBoxes
    Dot = DotEl - (FirstXBox - 1)
    FOR i = FirstXBox TO LastXBox  'Return which option button is active
      Response$(i) = STR$(Dot)     ' in all option button elements, so
    NEXT                           ' the programmer need only check one XBox
 
  DO
  LOOP WHILE KeyDown
    
    CALL HideCursor
    CALL MScrnRest(ULRow, ULCol, LRRow + 1, LRCol + 2, SEG Scrn(0))
    ERASE TResponse$ ',Text$    'Un-rem for TextCopy
    Action = 0
  ELSE
    Action = 4
  END IF


  EXIT SUB

Escape:
  Choice = -1
  Choice1 = Choice
  IF Action = 0 OR Action = 5 THEN
    IF NumChoices > NumButtons THEN
      FOR i = 1 TO UpBound
        Response$(i) = TResponse$(i)
      NEXT
    END IF

  DO
  LOOP WHILE KeyDown

    CALL HideCursor
    CALL MScrnRest(ULRow, ULCol, LRRow + 1, LRCol + 2, SEG Scrn(0))
    ERASE TResponse$', Text$    'Un-REM for TextCopy
    Action = 0
  ELSE
    Action = 4
  END IF

END SUB

FUNCTION LongestStr1% (Text$(), NumButtons, ItemNum)

  LongStr = 0
  FOR i = NumButtons + 1 TO UBOUND(Text$, 1)
    IF i = ItemNum THEN GOTO Skip
    IF LEN(Text$(i)) > LongStr THEN
      LongStr = LEN(Text$(i))
    END IF
Skip:
  NEXT
  LongestStr1% = LongStr

END FUNCTION

