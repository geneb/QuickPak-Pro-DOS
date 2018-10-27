'********** TEXTIN.BAS - text input subprogram

'Copyright (c) 1987 - 1990 Ethan Winer

DEFINT A-Z

DECLARE FUNCTION Peek1% (Segment, Address)
DECLARE FUNCTION QPTrim$ (X$)
DECLARE SUB CapNum ()
DECLARE SUB QPrint (X$, Colr, Page)

'----- entry parameters
'
'T$  = string to be input or edited (use the name of your choice)
'Max = maximum number of characters allowed
'Colr is the combined foreground and background colors that will be used
'CapsOn = force automatic conversion to upper case if 1
'NumOnly = allow only numeric input if 1
'
'----- exit parameters
'
'T$ = final edited string (whatever name was passed as input to the function)
'ExitCode indicates how editing was terminated -
'   0 = Enter, Tab, Down-Arrow, Right-Arrow past end, or field filled
'   1 = Shift-Tab, Up-Arrow, or Left-Arrow past beginning
'   2 = Esc key pressed
'
'----- local variables
'
'X$ is a copy of the string while being input or edited
'Insert holds status of insert mode
'Curpo holds current cursor position relative to the beginning of the line
'Length keeps track of the current length of the string
'Clr = 1 if the monitor is a color monitor, for setting cursor size
'A and A$ are temporary scratch variables
'
SUB TextIn (T$, Max, NumOnly, CapsOn, ExitCode, Colr) STATIC

TInitialize:
   Clr = 0                                      'determine monitor type
   IF Peek1%(0, &H463) <> &HB4 THEN Clr = 1

   X$ = T$                                      'work on a copy of the string
'  X$ = QPTrim$(T$)                             'use this if the incoming
                                                '  string is fixed-length
TC:
   ExitCode = 0: Insrt = 0: Curpo = 1           'initialize flags

   Length = LEN(X$)
   IF Length > Max THEN EXIT SUB                'already to big to edit

   X$ = X$ + SPACE$(Max - Length)               'pad with trailing spaces
   CALL QPrint(X$, Colr, -1)
   LOCATE , , 1                                 'turn on the cursor

   GOSUB TInsertOff                     'set cursor size according to display

  
TGetKey:
   CALL CapNum                          'display Cap/Num if active

   'disallow insert if cursor past end
   IF Curpo > Length AND Insrt <> 0 THEN GOSUB TInsertOff
   IF Curpo > Max GOTO TEnter           'field is filled, handle as Enter key

   A$ = INKEY$
   IF A$ = "" GOTO TGetKey
   IF LEN(A$) = 1 GOTO TRegularKey

   A$ = RIGHT$(A$, 1)                   'it was an extended key, get the code
   ON INSTR(CHR$(15) + ".GHKMOPRSstu" + CHR$(19), A$) GOTO TShiftTab, TClear, THome, TUp, TLeft, TRight, TEndKey, TDown, TIns, TDel, TCtrlLeft, TCtrlRight, TCtrlEnd, TRestore
   GOTO TGetKey                         'none of the above, get again
  

TShiftTab:
   ExitCode = 1                         'user wants to go back a field
   GOTO TEnter                          'handle as if it were the Enter key
         

TClear:
   X$ = ""                              'Alt-C, erase the current string
   GOSUB TInsertOff                     'clear insert mode and restore cursor
   LOCATE , POS(0) - (Curpo - 1)
   GOTO TC                              'and start all over again
  

THome:
   LOCATE , POS(0) - (Curpo - 1)        'put cursor at beginning of line
   Curpo = 1                            'show cursor as being on 1st character
   GOTO TGetKey

     
TUp:
   ExitCode = 1                         'user wants to go back a field
   GOTO TEnter                          'handle as if it were the Enter key
   

TLeft:
   IF Curpo = 1 GOTO TShiftTab          'cursor is on the first character,
                                        'handle as if it were a Shift-Tab
   Curpo = Curpo - 1                    'update Curpo
   LOCATE , POS(0) - 1                  'back up the cursor
   GOTO TGetKey

     
TRight:
   Curpo = Curpo + 1                    'update Curpo
   LOCATE , POS(0) + 1                  'advance the cursor on the screen
   GOTO TGetKey
      

TEndKey:
   LOCATE , POS(0) + (Length - Curpo) + 1 'put cursor at the end of the line
   Curpo = Length + 1                   'update Curpo
   GOTO TGetKey

  
TDown:
   GOTO TEnter
     

TIns:
   IF Insrt THEN                        'insert is already on, turn it off
      GOSUB TInsertOff
      GOTO TGetKey
   END IF

   IF Curpo > Length GOTO TGetKey       'ignore Ins if cursor is past the end
   IF Length = Max GOTO TGetKey         'also ignore if field is full

   Insrt = 1                            'set the insert flag
   IF Clr THEN                          'set cursor size according to display
      LOCATE , , , 0, 7
   ELSE
      LOCATE , , , 0, 13
   END IF

   GOTO TGetKey

     
TDel:
   IF Curpo > Length GOTO TGetKey       'ignore Del if cursor is past end

   'slide all characters left one position, add a trailing space and re-print
   MID$(X$, Curpo) = MID$(X$, Curpo + 1) + " "
   CALL QPrint(MID$(X$, Curpo), Colr, -1)

   Length = Length - 1                  'show string as one character shorter
   GOTO TGetKey

  
TCtrlLeft:
   IF Curpo = 1 GOTO TGetKey            'at the beginning, ignore

   A = Curpo                            'save cursor position

   'we're within a word, find beginning
   IF MID$(X$, Curpo - 1, 1) <> " " GOTO TSeekLeft2

TSeekLeft1:
   IF Curpo = 1 GOTO TCtrlLeftExit      'at the beginning, give up

   IF MID$(X$, Curpo - 1, 1) = " " THEN
      Curpo = Curpo - 1
      GOTO TSeekLeft1                   'seek previous non-blank character
   END IF

TSeekLeft2:
   IF Curpo = 1 GOTO TCtrlLeftExit      'at the beginning, give up
   IF MID$(X$, Curpo - 1, 1) <> " " THEN
      Curpo = Curpo - 1
      GOTO TSeekLeft2                   'seek character preceeded by a blank
   END IF

TCtrlLeftExit:
   LOCATE , POS(0) - (A - Curpo)        'position the cursor
   GOTO TGetKey


TCtrlRight:
   A = Curpo                            'save cursor position

TSeekRight1:
   IF A > Length GOTO TGetKey           'at the end, give up

   IF MID$(X$, A, 1) <> " " THEN
      A = A + 1                         'consider next character
      GOTO TSeekRight1                  'seek next blank space
   END IF

TSeekRight2:
   IF A > Length GOTO TGetKey           'at the end, give up

   IF MID$(X$, A, 1) = " " THEN
      A = A + 1                         'consider next character
      GOTO TSeekRight2                  'seek next non-blank character
   END IF

   LOCATE , POS(0) + (A - Curpo)        'position the cursor

   Curpo = A                            'show cursor as being on the next word
   GOTO TGetKey                         'get another keypress


TCtrlEnd:
   IF Curpo > Length GOTO TGetKey       'cursor is past the end, ignore

   CALL QPrint(SPACE$(Length - Curpo + 1), Colr, -1)'blank from cursor to the end
   MID$(X$, Curpo) = SPACE$(Length - Curpo + 1)     'clear that part of the string
   Length = Curpo - 1                   'show the length being at the cursor
   GOTO TGetKey                         'get another keypress
  

TRestore:
   LOCATE , POS(0) - (Curpo - 1)        'locate cursor at beginning of line,
   GOTO TInitialize                     '  and start all over again


TRegularKey:
   IF A$ < " " THEN                     'a control key
      ON INSTR(CHR$(8) + CHR$(9) + CHR$(13) + CHR$(27), A$) GOTO TBackspace, TTabKey, TEnter, TEscape
      GOTO TGetKey                      'none of the above
   END IF

   IF CapsOn THEN                       'convert to upper case if requested
      IF A$ >= "a" AND A$ <= "z" THEN A$ = CHR$(ASC(A$) AND 95)
   END IF

   IF NumOnly THEN                      'disallow non-numeric if requested
      IF A$ < "0" OR A$ > "9" THEN
         PLAY "L16O3EC"
         GOTO TGetKey
      END IF
   END IF

   CALL QPrint(A$, Colr, -1)            'print character
   LOCATE , POS(0) + 1
   Curpo = Curpo + 1                    'show cursor being ahead

   IF Insrt GOTO THandleInsert

   MID$(X$, Curpo - 1, 1) = A$          'assign the character

   'cursor is past end, increase length
   IF Curpo > Length + 1 THEN Length = Curpo - 1

   'field complete, handle as Enter key
   IF Length = Max AND Curpo > Length GOTO TEnter

   GOTO TGetKey

  
THandleInsert:
   Length = Length + 1                  'show string being 1 character longer
   Temp$ = MID$(X$, Curpo - 1)          'using Temp$ avoids a BASIC 7 bug
   MID$(X$, Curpo) = Temp$              'move characters one position ahead

   MID$(X$, Curpo - 1, 1) = A$          'assign the current character
   CALL QPrint(MID$(X$, Curpo, Length - Curpo + 1), Colr, -1)  're-print X$

   IF Length = Max GOTO TEnter          'field complete, handle as Enter key
   GOTO TGetKey
  

TBackspace:
   IF Curpo = 1 GOTO TGetKey            'can't back up any more, ignore
   Curpo = Curpo - 1                    'show cursor being 1 character before
   LOCATE , POS(0) - 1                  'back up the cursor
   GOTO TDel                            'handle as if it were the Delete key
          

TTabKey:                                'reserved for your Tab routine if you
                                        '  want to handle it differently
TEnter:
   GOSUB TInsertOff                     'clear insert, restore cursor size
   X$ = LEFT$(X$, Length)               'retain only the current length

   T$ = X$                              'assign the string
   LOCATE , , 0                         'turn off the cursor
   EXIT SUB


TEscape:
   ExitCode = 2                         'show that the user pressed Escape
   GOTO TEnter                          'handle as if it were the Enter Key


TInsertOff:
   'clear Insert mode and restore cursor, depending on monitor type

   Insrt = 0
   IF Clr THEN
      LOCATE , , , 6, 7
   ELSE
      LOCATE , , , 12, 13
   END IF
   RETURN

END SUB

