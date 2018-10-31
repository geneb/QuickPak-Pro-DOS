'********** CALC.BAS - pop-up calculator from BASIC

'Copyright (c) 1988 Don Resnick
'Copyright (c) 1988 Crescent Software


DEFINT A-Z

'----- BASIC subprograms
DECLARE SUB TextEntry (Colr, ExitCode, Number$, Row, Col)
DECLARE SUB Calc (ULRow, ULCol, FG, BG)


'----- assembler routines
DECLARE SUB Box (TopRow, LeftCol, BotmRow, RightCol, Style, Colr, Page)
DECLARE SUB ClearScr (TopRow, LeftCol, BotmRow, RightCol, Colr, Page)
DECLARE SUB PaintBox (ULRow, ULCol, LRRow, LRCol, Colr, Page)
DECLARE SUB QPrint0 (X$, Colr)
DECLARE SUB ReadScrn0 (Row, Col, X$)
DECLARE SUB ScrnSave0 (TopRow, LeftCol, BotmRow, RightCol, SEG Address)
DECLARE SUB ScrnRest0 (TopRow, LeftCol, BotmRow, RightCol, SEG Address)
DECLARE SUB ScrollU (TopRow, LeftCol, BotmRow, RightCol, Lines, Page)


'----- assembler functions

DECLARE FUNCTION PRNReady% (LPTNumber)
DECLARE FUNCTION OneColor% (FG, BG)

SUB Calc (TopRow, LeftCol, CF, CB) STATIC

    OldRow = CSRLIN: OldCol = POS(0)            'save cursor position
    BotmRow = TopRow + 17                       'calc bottom row from top row
    RightCol = LeftCol + 21                     'ditto for right column
    FirstRow = TopRow + 2                       'first row for data entry
    Colr = OneColor%(CF, CB)                    'combine colors into one byte
   
    'CalcWndo() holds the saved screen under the calculator
    DIM CalcWndo(((BotmRow - TopRow + 1) * (RightCol - LeftCol + 1)) * 2)
    CALL ScrnSave0(TopRow, LeftCol, BotmRow, RightCol, CalcWndo(0))
   
    CALL ClearScr(TopRow, LeftCol, BotmRow, RightCol, Colr, -1) 'clear window
    CALL Box(TopRow, LeftCol, BotmRow, RightCol, 2, Colr, -1)   'make a box
   
    Title$ = "µ Calculator Æ"                   'change this if you'd like
    LOCATE TopRow, ((RightCol - LeftCol + 1) / 2 - LEN(Title$) / 2) + LeftCol
    CALL QPrint0(Title$, Colr)

    LOCATE BotmRow, LeftCol + 2
    CALL QPrint0("µ F7 for Printer Æ", Colr)
    F7 = 0                                      'F7 flags if also LPRINTing

Init:
    Operand# = 0: Result# = 0: Row = FirstRow

Begin:
    Col = LeftCol + 5
    LOCATE , , 1
    ZeroFlag = 0                                'clear "divide by zero" flag
   
    CALL TextEntry(112, XCod, Number$, Row, Col)'use inverse colors

    Operand# = VAL(Number$)

    SELECT CASE XCod                            'TextEntry returns XCod
      CASE 7                                    'check if printer is on
        IF F7 = 0 THEN                          '----------------------
          DO
            X$ = INKEY$
            PrinterStatus = PRNReady%(1)
            LOCATE BotmRow, LeftCol + 2, 0
            CALL QPrint0("µ Turn printer on Æ", Colr)
            IF X$ <> "" THEN EXIT DO            'any key to exit loop
          LOOP WHILE PrinterStatus = 0          'keep checking printer
          IF X$ = "" THEN
            F7 = 1                              'turn printer flag on
            LOCATE BotmRow, LeftCol + 2
            CALL QPrint0("ÍÍÍÍÍµ Print ÆÍÍÍÍÍ", Colr)
          END IF
        ELSE
          F7 = 0                                'turn printer flag off
          LOCATE BotmRow, LeftCol + 2
          CALL QPrint0("µ F7 for Printer Æ", Colr)
        END IF
        GOTO Begin

      CASE 27
        GOTO QuitCalc                           'get operator for display

      CASE 1
        Y$ = "+"                                'add

      CASE 2
        Y$ = "-"                                'subtract

      CASE 3
        Y$ = "*"                                'multiply

      CASE 4
        Y$ = "/"                                'divide

      CASE 13, 5
        Y$ = "="                                'result

      CASE ELSE
    END SELECT

    LOCATE Row, LeftCol + 5                     'print operand
    PRINT USING "##########.##"; Operand#;      'then paint in chosen color
    CALL PaintBox(Row, LeftCol + 3, Row, LeftCol + 19, Colr, -1)
    IF F7 THEN LPRINT TAB(12); USING "##########.##"; Operand#

    IF Row = FirstRow THEN                      'must handle first entry
       Result# = Operand#: Operand# = 0#        '  differently from rest
       X$ = Y$: Row = FirstRow - 1
       GOSUB DisplayResult
       GOSUB PrintOperator
       GOTO Begin
    END IF

    SELECT CASE X$                              'perform calculation
       CASE "+"
         Result# = Result# + Operand#
       CASE "-"
         Result# = Result# - Operand#
       CASE "*"
         Result# = Result# * Operand#
       CASE "/"
         IF Operand# <> 0# THEN                 'trap "divide by zero"
           Result# = Result# / Operand#         'okay to divide
         ELSE
           Result# = 0#                         'clear the result
           ZeroFlag = -1                        'flag it for display routine
         END IF
       CASE "="
         GOSUB DisplayResult
         GOTO StopCalc
       CASE ELSE
    END SELECT

    GOSUB DisplayResult
    IF XCod = 13 OR XCod = 5 GOTO StopCalc
    GOSUB PrintOperator
    GOTO Begin

DisplayResult:
    LOCATE Row + 1, LeftCol + 3
    IF Row + 1 = FirstRow THEN                  'don't print = first row
       CALL QPrint0(" ", Colr)
    ELSE
       CALL QPrint0("=", Colr)
    END IF

    LOCATE , POS(0) + 1                         'go to next column
    IF Result# > 9.99E+10 THEN                  'largest result possible
       PLAY "L16N40N36"
       CALL QPrint0("%%%%%%%%%%%%%%", Colr)
    ELSE
       IF NOT ZeroFlag THEN
         PRINT USING "###########.##"; Result#; 'print result, then paint
       ELSE
         CALL QPrint0("             ì", Colr)   'display infinity
       END IF
       CALL PaintBox(Row + 1, LeftCol + 2, Row + 1, LeftCol + 19, Colr, -1)
    END IF

    IF F7 THEN
       IF Row + 1 = FirstRow THEN               'don't print = first row
         LPRINT TAB(9); "  ";
       ELSE
         LPRINT TAB(9); "= ";
       END IF
       IF NOT ZeroFlag THEN
         LPRINT USING "###########.## *"; Result#
       ELSE
         LPRINT "             ì"
       END IF
    END IF
RETURN

PrintOperator:
    Row = Row + 2: X$ = Y$
    IF Row > BotmRow - 2 THEN                   'scroll if at bottom of window
       CALL ScrollU(TopRow + 2, LeftCol + 1, BotmRow - 1, RightCol - 1, 2, -1)
       Row = BotmRow - 2                        'adjust to new row
    END IF

    IF Row < BotmRow - 2 THEN                   'row for new operator
       NewRow = Row
    ELSE
       NewRow = BotmRow - 2
    END IF

    LOCATE NewRow, LeftCol + 3
    CALL QPrint0(Y$, Colr)                      'print operator
    IF F7 THEN LPRINT TAB(9); Y$;
RETURN

StopCalc:                                       'end the calculation
    LOCATE BotmRow, LeftCol + 1, 0              'can either start another
    CALL QPrint0("µ(A)nother / (Q)uitÆ", Colr)  'or quit out of calculator

    Y$ = UCASE$(INKEY$)
    WHILE Y$ = ""
       Y$ = UCASE$(INKEY$)
       IF Y$ = "Q" OR Y$ = CHR$(27) THEN
         GOTO QuitCalc
       ELSEIF Y$ = "A" THEN
         CALL ClearScr(TopRow + 1, LeftCol + 1, BotmRow - 1, RightCol - 1, Colr, -1)
         LOCATE BotmRow, LeftCol + 1
         CALL QPrint0("Íµ F7 for Printer ÆÍ", Colr)
         GOTO Init
       ELSE
         Y$ = ""
       END IF
    WEND

QuitCalc:
    CALL ScrnRest0(TopRow, LeftCol, BotmRow, RightCol, CalcWndo(0))
    ERASE CalcWndo
    LOCATE OldRow, OldCol               'restore original cursor position

END SUB

SUB TextEntry (Colr, ExitCode, Number$, Row, Col) STATIC

    BegCol = Col: EndCol = BegCol + 12
    InsFlag = 7                                 'use scan lines to flag Insert
  
    LOCATE Row, Col, 0
    CALL QPrint0(SPACE$(13), Colr)              'print entry window

StartPass:
    Number$ = SPACE$(EndCol - BegCol + 1)       'read current line directly
    CALL ReadScrn0(Row, BegCol, Number$)        '  of the screen

CheckLimits:                                    'stay within window
    IF Col > EndCol THEN Col = EndCol
    IF Col < BegCol THEN Col = BegCol

    LOCATE Row, Col, 1, InsFlag, 7

    DO                                  'get a key press
      X$ = INKEY$
    LOOP UNTIL LEN(X$)

    IF INSTR("+-/*=", X$) > 0 THEN      'look for operator
       SELECT CASE X$                   'calculator key entries
      CASE "+"
         ExitCode = 1
      CASE "-"
         ExitCode = 2
      CASE "*"
         ExitCode = 3
      CASE "/"
         ExitCode = 4
      CASE "="
         ExitCode = 5
       END SELECT
       GOTO EndText
    END IF
                                        
    IF X$ = CHR$(0) + CHR$(65) THEN     'F7 - send to printer
       ExitCode = 7
       GOTO EndText
    END IF
                                                                            
    IF X$ = CHR$(0) + CHR$(79) THEN     'End
       FOR W = LEN(Number$) TO 1 STEP -1
       IF MID$(Number$, W, 1) <> " " THEN EXIT FOR
       NEXT
       Col = W + BegCol
       GOTO StartPass
    END IF

    IF X$ = CHR$(0) + CHR$(71) THEN     'Home
       Col = BegCol
       GOTO StartPass
    END IF

    IF X$ = CHR$(0) + CHR$(82) THEN     'Insert
       IF InsFlag = 0 THEN
         InsFlag = 7
       ELSE
         InsFlag = 0
       END IF
       LOCATE , , , InsFlag, 7
    END IF

    IF X$ = CHR$(0) + CHR$(83) THEN     'Delete
       LOCATE Row, Col
       CALL QPrint0(RIGHT$(Number$, EndCol - Col) + " ", Colr)
       GOTO StartPass
    END IF
                                        'Arrow keys
    IF X$ = CHR$(0) + CHR$(77) THEN Col = Col + 1       'Right
    IF X$ = CHR$(0) + CHR$(75) THEN Col = Col - 1       'Left
   
    IF LEN(X$) = 2 GOTO CheckLimits

    IF X$ = CHR$(27) THEN               'Escape
       ExitCode = 27
       GOTO EndText
    END IF
                
    IF X$ = CHR$(13) THEN               'Enter
       ExitCode = 13
       GOTO EndText
    END IF

    IF X$ = CHR$(8) THEN                'Backspace
       IF Col = BegCol THEN
         GOTO StartPass
       ELSEIF Col = EndCol THEN
         IF SCREEN(Row, Col) = 32 THEN Col = Col - 1
         LOCATE Row, Col
         CALL QPrint0(" ", Colr)
         GOTO StartPass
       ELSE
         LOCATE Row, Col - 1
         CALL QPrint0(" ", Colr)
         Col = Col - 1
         GOTO StartPass
       END IF
    END IF

PrintText:
    IF (X$ < "0" OR X$ > "9") AND X$ <> "." GOTO StartPass 'trap non-digits

    LOCATE Row, Col
    CALL QPrint0(X$, Colr)
    Col = Col + 1
    IF InsFlag = 0 THEN
       IF Col <> EndCol + 1 THEN
         LOCATE Row, Col
         CALL QPrint0(MID$(Number$, Col - BegCol, EndCol - Col), Colr)
       END IF
    END IF
    GOTO StartPass

EndText:
    IF VAL(Number$) > 1E+10 THEN
       PLAY "L16N40N36"
       GOTO CheckLimits
    END IF

END SUB

