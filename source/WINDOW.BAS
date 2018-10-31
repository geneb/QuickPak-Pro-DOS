'********* WINDOW.BAS - demonstrates the window managing routines

'Copyright (c) 1991-1992 Ethan Winer

DEFINT A-Z
DECLARE SUB QPWindowInit (BYVAL ULRow, BYVAL ULCol, BYVAL LRRow, BYVAL LRCol)
DECLARE SUB QPWindowCLS (BYVAL Colr)
DECLARE SUB QPWindowLocate (BYVAL Row, BYVAL Column)
DECLARE SUB QPWindowPrint (Work$, BYVAL Colr)
DECLARE SUB QPWindowPrintCR (Work$, BYVAL Colr)
DECLARE SUB QPWindowPrintWrap (Work$, ULCol, LRCol, Colr) 'BASIC in this file
DECLARE FUNCTION QPWindowCol% ()
DECLARE FUNCTION QPWindowRow% ()

CLS                                     'start with a clean slate
Colr = 12 + 16 * 7                      'bright red on white
CALL QPrint0(STRING$(2000, 197), Colr)
LOCATE , , 1                            'turn on the cursor

CALL QPWindowInit(5, 5, 17, 37)         'set the window size
CALL QPWindowCLS(Colr + 20)             'clear the window to this color
CALL PaintBox0(6, 38, 18, 39, 8)        'draw a drop shadow, first the side
CALL PaintBox0(18, 6, 18, 38, 8)        'and then on the bottom
CALL QPWindowLocate(5, 5)               'move the cursor to 5,5 in the window
PRINT QPWindowRow%, QPWindowCol%        'prove (at 1,1) these work correctly

LOCATE 25, 1: PRINT "Windowed printing...";
Colr = 15 + 16 * 2                      'print with bright white on green
FOR X = 1 TO 250
  CALL QPWindowPrint(STR$(X), Colr)     'this shows how the window scrolls
  CALL Pause(1)                         'this lets you see it working
NEXT

LOCATE 25, 1: PRINT "Windowed printing with CRLF every ten numbers...";
CALL QPWindowCLS(Colr)                  'clear the window again
FOR X = 81 TO 180
  CALL QPWindowPrint(STR$(X), Colr)     'this shows how the window scrolls
  IF X MOD 10 = 0 THEN                  'every 10 numbers print a CRLF
    CALL QPWindowPrintCR("", Colr)      'using QPWindowPrintCR with a null $
  END IF
  CALL Pause(1)                         'this lets you see it working
NEXT

Tmp$ = "This demonstrates how to use word-wrapping in the QuickPak Window "
Tmp$ = Tmp$ + "manager.  QPWindowPrintWrap is similar to the regular"
Tmp$ = Tmp$ + " QPWindowPrint routine, except it breaks the string down into"
Tmp$ = Tmp$ + " individual words and prints each without splitting a word "
Tmp$ = Tmp$ + "in the middle.  The QPWindowPrintWrap subprogram is written "
Tmp$ = Tmp$ + "in BASIC and is in this module.  Therefore, you must "
Tmp$ = Tmp$ + "copy it from WINDOW.BAS to your own program to use it."

CALL QPWindowCLS(Colr)                      'first clear the window
CALL QPWindowPrintWrap(Tmp$, 5, 37, Colr)   'then print with word-wrapping
X = 12

SUB QPWindowPrintWrap (Work$, ULCol, LRCol, Colr) STATIC

  Tmp$ = Work$                          'work with a copy of the string

  DO

    Space = INSTR(Tmp$, " ")            'find the next space
    IF Space THEN                       'we found one
      Word$ = LEFT$(Tmp$, Space - 1)    'isolate this word
      Tmp$ = LTRIM$(MID$(Tmp$, Space))  'strip it from what remains
    ELSE
      Word$ = Tmp$                      'no space, so there's only one word
      Tmp$ = ""                         '  (or this was the last), erase Tmp$
    END IF

    Word$ = LTRIM$(RTRIM$(Word$))       'strip leading/trailing blanks

    Have = LRCol - QPWindowCol% - ULCol + 2     'how much room do we have?
    Need = LEN(Word$)                           'and how much do we need?

    IF Have < Need THEN                         'it won't fit
      CALL QPWindowPrintCR("", Colr)            'advance a line
    END IF
    CALL QPWindowPrint(Word$, Colr)             'either way print this word

    'add a trailing space if the last Print didn't wrap to the first column
    IF QPWindowCol% > 1 THEN CALL QPWindowPrint(" ", Colr)

  LOOP WHILE LEN(Tmp$)

END SUB

