'********** DATEIN.BAS - date input routine

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z

DECLARE SUB CapNum ()
DECLARE SUB QPrint (X$, Colr, Page)

'----- entry parameters
'
'Dt$ = date to be input or edited (use the name of your choice)
'Colr is the combined foreground and background colors that will be used
'
'----- exit parameters
'
'Dt$ = final edited date
'ExitCode indicates how editing was terminated -
'   0 = Enter, Tab, Down-Arrow, Right-Arrow past end, or field filled
'   1 = Shift-Tab, Up-Arrow, or Left-Arrow past beginning
'   2 = Esc key pressed
'
'----- local variables
'
'X$ is the date being edited
'Curpo holds current cursor position relative to the beginning of the line
'Place indicates where to put the cursor if the entered date is invalid
'A$ is a temporary scratch variable
'
SUB DateIn (Dt$, ExitCode, Colr) STATIC

   X$ = Dt$                             'assign temporary work string

DInitialize:

   ExitCode = 0
   Curpo = 1

   IF X$ = "" THEN X$ = SPACE$(6)       'new string - fill with blanks
   IF LEN(X$) <> 6 THEN EXIT SUB        'invalid date

   X$ = LEFT$(X$, 2) + "/" + MID$(X$, 3, 2) + "/" + RIGHT$(X$, 2)
   CALL QPrint(X$, Colr, -1)            'print the date
   LOCATE , , 1                         'turn on the cursor


DGetKey:
   CALL CapNum                          'display Cap/Num if active
   IF Curpo = 9 GOTO DEnter             'the cursor is past the end, all done

   A$ = INKEY$
   IF A$ = "" GOTO DGetKey
   IF LEN(A$) = 1 GOTO DRegularKey

   A$ = RIGHT$(A$, 1)                   'it was an extended key, get the code
   ON INSTR(CHR$(15) + ".HKMP", A$) GOTO DShiftTab, DClear, DUp, DLeft, DRight, DDown
   GOTO DGetKey                         'none of the above, get again


DShiftTab:                              'put your own Shift-Tab handler here
                                        '  if you'd like
DUp:
   ExitCode = 1                         'user wants to go back a field
   GOTO DEnter                          'handle as if it were the Enter key


DClear:
   X$ = ""                              'Alt-C, clear the date
   LOCATE , POS(0) - (Curpo - 1)        'put the cursor at beginning of field
   GOTO DInitialize                     'and do it all over again
  

DLeft:
   IF Curpo = 1 GOTO DShiftTab          'cursor is on the first character,
                                        'handle as if it were a Shift-Tab
   Curpo = Curpo - 1                    'update Curpo
   LOCATE , POS(0) - 1                  'back the cursor up one

   IF Curpo = 3 OR Curpo = 6 THEN
      Curpo = Curpo - 1
      LOCATE , POS(0) - 1
   END IF

   GOTO DGetKey


DRight:
   IF Curpo = 8 GOTO DEnter             'cursor is past the end, exit

   Curpo = Curpo + 1                    'update Curpo
   LOCATE , POS(0) + 1                  'advance the cursor

   IF Curpo = 3 OR Curpo = 6 THEN       'one more if we're crossing a slash
      Curpo = Curpo + 1
      LOCATE , POS(0) + 1
   END IF

   GOTO DGetKey


DDown:
   GOTO DEnter                          'treat a down arrow as Enter
     

DRegularKey:
   IF A$ < " " THEN                     'a control key
      ON INSTR(CHR$(8) + CHR$(9) + CHR$(13) + CHR$(27), A$) GOTO DBackSpace, DTabKey, DEnter, DEscape
      GOTO DGetKey                      'none of the above
   END IF
  
   'ignore if not a valid digit
   IF A$ <> " " AND (A$ < "0" OR A$ > "9") GOTO DGetKey

   CALL QPrint(A$, Colr, -1)            'print the digit
   LOCATE , POS(0) + 1                  'advance the cursor
   MID$(X$, Curpo, 1) = A$              'assign it to the string

   Curpo = Curpo + 1                    'show the cursor advancing one digit
   IF Curpo = 3 OR Curpo = 6 THEN
      Curpo = Curpo + 1
      LOCATE , POS(0) + 1
   END IF

   GOTO DGetKey

  
DBackSpace:
   GOTO DLeft                           'handle as a Left-Arrow
          

DTabKey:                                'add your own Tab handler if needed

DEnter: 
   GOTO DCheckMonth


DEscape:
   ExitCode = 2
   GOTO DEnter

       
DCheckMonth:
   IF X$ = "  /  /  " GOTO DDone        'blank is okay

   'if month is valid, keep checking
   IF LEFT$(X$, 2) > "00" AND LEFT$(X$, 2) < "13" GOTO DCheckDay

   Place = 1
   GOTO DBadDate                        'error, show where to place the cursor


DCheckDay:
   'if day is valid, keep checking.
   IF MID$(X$, 4, 2) > "00" AND MID$(X$, 4, 2) < "32" GOTO DCheckYear
                                        'You could get fancy here for February
   Place = 4: GOTO DBadDate             'error, show where to place the cursor


DCheckYear:
  'IF RIGHT$(X$, 2) = "00" GOTO DDone   'year is valid, all done
  'Place = 7                            'error, show where to place the cursor
  'GOTO DBadDate
  GOTO DDone            'REMmed and added 11-28-95


DBadDate:
   LOCATE , POS(0) - (Curpo - 1)        'first move the cursor to the beginning
   PRINT STRING$(Place - 1, 28);        'now move the cursor to the bad place
   Curpo = Place                        'show the cursor as being there

   PLAY "L16O3EC"                       'sound the chime
   ExitCode = 0                         'reset ExitCode
   GOTO DGetKey


DDone:
   Dt$ = LEFT$(X$, 2) + MID$(X$, 4, 2) + RIGHT$(X$, 2)
   COLOR 7, 0                           'restore the color
   LOCATE , , 0

END SUB

