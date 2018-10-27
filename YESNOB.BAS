'********** YESNOB.BAS - BASIC yes/no input subprogram

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z

DECLARE SUB CapNum ()
DECLARE SUB QPrint (X$, Colr, Page)

'----- entry parameters
'
'YN$ = string to be input or edited (use the name of your choice)
'Colr is the combined foreground and background colors that will be used
'
'----- exit parameters
'
'YN$  = final edited amount
'ExitCode indicates how editing was terminated -
'   0 = Enter, Tab, Down-Arrow, Right-Arrow past end, or field filled
'   1 = Shift-Tab, Up-Arrow, or Left-Arrow past beginning
'   2 = Escape key pressed
'
'----- local variables
'
'X$ is a string version of the number while it is being input or edited
'
SUB YesNoB (YN$, ExitCode, Colr) STATIC

   ExitCode = 0                                 'initialize flag

   X$ = YN$
   IF X$ = "" THEN X$ = " "
   CALL QPrint(X$, Colr, -1)
   LOCATE , , 1


YGetKey:
   CALL CapNum                                  'print Cap/Num if active
   X$ = INKEY$
   IF X$ = "" GOTO YGetKey

   IF UCASE$(X$) = "Y" OR UCASE$(X$) = "N" GOTO YDone

   IF X$ = CHR$(9) OR X$ = CHR$(13) GOTO YD2    'Tab or Enter
   IF X$ = CHR$(27) THEN                        'Escape
      ExitCode = 2
      GOTO YD2
   END IF

   IF LEN(X$) = 2 THEN                          'extended key
      X$ = RIGHT$(X$, 1)
      IF X$ = "P" OR X$ = "M" THEN GOTO YD2     'Down arrow, Right arrow
      IF X$ = "H" OR X$ = "K" OR X$ = CHR$(15) THEN
         ExitCode = 1                           'Up, Left, Shift-Tab
         GOTO YD2
      END IF
   END IF

   GOTO YGetKey

  
YDone:
   IF X$ > "Y" THEN X$ = CHR$(ASC(X$) - 32)     'capitalize if necessary
   YN$ = X$
   CALL QPrint(YN$, Colr, -1)

YD2:
   LOCATE , , 0

END SUB

