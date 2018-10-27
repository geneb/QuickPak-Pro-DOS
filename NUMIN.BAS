'********** NUMIN.BAS - numeric input routine

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z

DECLARE SUB CapNum ()
DECLARE FUNCTION FUsing$ (Number$, Mask$)
DECLARE SUB QPrint (X$, Colr, Page)

'----- entry parameters
'
'N# = amount to be input or edited (use the name of your choice)
'
'Max = maximum number of digits to the left of the decimal point
'Places = maximum number of digits to the right of the decimal point
'Colr is the combined foreground and background colors that will be used
'
'----- exit parameters
'
'N# = final edited amount
'ExitCode indicates how editing was terminated -
'   0 = Enter, Tab, Down-Arrow, Right-Arrow past end, or field filled
'   1 = Shift-Tab, Up-Arrow, or Left-Arrow past beginning
'   2 = Escape key pressed
'
'----- local variables
'
'X$ is a string version of the number while it is being input or edited
'Insert indicates that insert mode is active
'Curpo holds current cursor position relative to the beginning of the line
'A and A$ are temporary scratch variables
'
SUB NumIn (N#, Max, Places, ExitCode, Colr) STATIC

NInitialize:
   IF Max = 0 THEN Max = 1                      'leave room for minus sign

   X$ = STRING$(Max, "#")                       'build a formatting string
   IF Places THEN X$ = X$ + "." + STRING$(Places, "#")
   X$ = FUsing$(STR$(N#), X$)                   'let FUsing do the real work
   Zero = INSTR(X$, "0")                        'did FUsing leave a leading 0?
   IF LEFT$(LTRIM$(X$), 1) = "0" THEN MID$(X$, Zero, 1) = " "  'yes, delete it

   ExitCode = 0: Insrt = 1: Curpo = Max         'initialize local variables
   ALength = LEN(STR$(FIX(N#)))                 'active length of leading part

   IF ABS(N#) >= 1# THEN                        'insert only if no leading #'s
      Insrt = 0                                 '  and position cursor over
      Curpo = Max - ALength + 2                 '  first digit
   END IF

   CALL QPrint(X$, Colr, -1)                    'print it
   LOCATE , POS(0) + Max - ALength + 1, 1       'locate and turn on the cursor


NGetKey:
   CALL CapNum                                  'print Cap/Num if active
   IF Curpo > LEN(X$) GOTO NEnter               'field full, handle as Enter
   IF MID$(X$, Curpo, 1) = "." THEN             'cursor is on the point, skip
      LOCATE , POS(0) + 1
      Curpo = Curpo + 1
   END IF

   A$ = INKEY$
   IF A$ = "" GOTO NGetKey
   IF LEN(A$) = 1 GOTO NRegularKey

   A$ = RIGHT$(A$, 1)                           'extended key, get the code
   ON INSTR(CHR$(15) + ".HKMPS", A$) GOTO NShiftTab, NClear, NUp, NLeft, NRight, NDown, NDel
   GOTO NGetKey                                 'none of the above, ignore


NShiftTab:                                      'this space is provided to put
                                                '  your own handler for the

NUp:                                            '  Shift-Tab key if you want
   ExitCode = 1                                 'user wants to go back a field
   GOTO NEnter                                  'handle as if it were Enter


NClear:
   LOCATE , POS(0) - (Curpo - 1)                'position cursor at beginning
   N# = 0#                                      'clear the field
   GOTO NInitialize


NLeft:
   Insrt = 0                                    'cancel insert mode
   IF MID$(X$, Curpo, 1) = " " GOTO NGetKey     'allow only one leading space
   IF MID$(X$, Curpo, 1) = "-" GOTO NGetKey     'disallow digits ahead of "-"

   IF Curpo > 1 THEN
      Curpo = Curpo - 1
      LOCATE , POS(0) - 1                       'back up the cursor
   END IF

   IF Curpo = Max + 1 THEN                      'one more to skip the point
      Curpo = Curpo - 1
      LOCATE , POS(0) - 1
   END IF

   GOTO NGetKey


NRight:
   Insrt = 0                                    'cancel insert mode
   Curpo = Curpo + 1
   LOCATE , POS(0) + 1                          'advance the cursor
   GOTO NGetKey


NDown:
   GOTO NEnter                                  'handle as Enter


NDel:
   GOTO NSB2                                    'handle as a space


NRegularKey:
   IF A$ < " " THEN                             'a control key
      ON INSTR(CHR$(8) + CHR$(9) + CHR$(13) + CHR$(27), A$) GOTO NBackSpace, NTabKey, NEnter, NEscape
      GOTO NGetKey                              'none of the above, get again
   END IF

   IF A$ = "-" THEN
      IF Curpo = 1 GOTO NNumericOkay
      IF INSTR(X$, "-") GOTO NGetKey            'disallow if already a minus
      IF MID$(X$, Curpo - 1, 1) <> " " GOTO NGetKey
      GOTO NNumericOkay
   END IF

   IF A$ = "." THEN
      IF Places = 0 GOTO NGetKey                'disallow if no decimals
      IF Insrt = 0 GOTO NGetKey                 'disallow unless new entry
      LOCATE , POS(0) + 2                       'advance the cursor by two
      Curpo = Curpo + 2
      Insrt = 0                                 'clear the insert flag
      GOTO NGetKey                              'get another keypress
   END IF


NSpaceBar:
   IF A$ = " " THEN
      Insrt = 0

NSB2:
      IF Curpo = 1 GOTO NSpaceOkay              'okay if in first position

      'disallow if not first digit
      IF MID$(X$, Curpo - 1, 1) <> " " GOTO NGetKey

NSpaceOkay:
      MID$(X$, Curpo, 1) = " "                  'assign a space to the string
      CALL QPrint(" ", Colr, -1)                'print a space
      LOCATE , POS(0) + 1                       'advance the cursor
      Curpo = Curpo + 1                         'update Curpo
      GOTO NGetKey

   END IF

   IF A$ < "0" OR A$ > "9" GOTO NGetKey         'invalid character


NNumericOkay:
   CALL QPrint(A$, Colr, -1)                    'print the digit
   IF Insrt GOTO NHandleInsert                  'special treatment for insert
   MID$(X$, Curpo, 1) = A$                      'assign new digit
   Curpo = Curpo + 1                            'show the cursor being forward
   LOCATE , POS(0) + 1
   GOTO NGetKey


NHandleInsert:
   LOCATE , POS(0) - Curpo + 1                  'back the cursor to beginning

   FOR A = 1 TO Max - 1                         'slide all characters left one
       MID$(X$, A, 1) = MID$(X$, A + 1, 1)
       QPrint MID$(X$, A, 1), Colr, -1          'and reprint them in new place
       LOCATE , POS(0) + 1
   NEXT
 
   MID$(X$, Curpo, 1) = A$                      'assign the digit
   CALL QPrint(A$, Colr, -1)
   IF ASC(X$) = 32 GOTO NGetKey                 'field not full, get another
   GOTO NRight                                  'field full, do a cursor right


NBackSpace:
   GOTO NLeft                                   'handle as Left-Arrow key


NEscape:
   ExitCode = 2


NTabKey:                                        'you may handle Tab separately
                                                '  if you'd like
NEnter:
   N# = VAL(X$)                                 'assign returned amount
   LOCATE , , 0                                 'turn off the cursor

END SUB

