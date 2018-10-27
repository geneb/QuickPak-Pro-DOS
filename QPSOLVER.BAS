'********** QPSOLVER.BAS - it may not be MathCad, but what the hey...

'Copyright (c) 1990 Ethan Winer


DEFINT A-Z

'----- assembly language subs
DECLARE SUB ClearEOL (Colr)
DECLARE SUB DeleteStr (BYVAL Address, NumEls)
DECLARE SUB Editor (Ed$, ALen, SCode, Num, Cap, NormColor, EditColr, Row, Col)
DECLARE SUB FindExact (BYVAL Address, NumEls, Search$)

'----- assembly language functions
DECLARE FUNCTION ASCII% (Work$)
DECLARE FUNCTION Exist% (FileName$)
DECLARE FUNCTION Null% (Work$)
DECLARE FUNCTION InstrTbl% (Start, Source$, Table$)

'----- BASIC subs
DECLARE SUB AddWatch (Watch$)
DECLARE SUB GetInput (Action$)
DECLARE SUB LoadFile (FileName$)
DECLARE SUB PrintError ()
DECLARE SUB SaveFile (FileName$)
DECLARE SUB UpdateWatch ()

'----- BASIC functions
DECLARE FUNCTION Evaluate# (Equation$)
DECLARE FUNCTION FindVar% (VarName$)
DECLARE FUNCTION Legal% (Work$)
DECLARE FUNCTION Var2Value$ (Expression$)

'----- initialization and setup stuff
CONST MaxVars% = 100                    'maximum number of variables
CONST MaxWatch% = 10                    'maximum number of Watch expressions
CONST MaxHist% = 20                     'maximum commands remembered
REDIM SHARED Variable$(1 TO MaxVars%)   'holds the variable names
REDIM SHARED Variable#(1 TO MaxVars%)   'holds the variable values
REDIM SHARED Watch$(1 TO MaxWatch%)     'holds the Watch expressions
REDIM SHARED History$(1 TO MaxHist% + 1)'holds the command line history
DIM SHARED CurVars                      'holds current number of variables
DIM SHARED ErrorCode                    'holds the error codes
DIM SHARED Colr                         'the ClearEOL color
Colr = 7                                'white on black

'----- Sign-on and title
CLS
LOCATE 1, 31
PRINT "QP - S o l v e r"
LOCATE 3, 21
PRINT "Copyright (c) 1990 Crescent Software"
LOCATE 18
PRINT "Commands:";
PRINT " var = [expression]; PRINT or ? [expression]; LOAD or SAVE [filename]"
PRINT "          WATCH [expression]; KILL [watch number]; EDIT [watch number]; END"
PRINT "          Use the arrow keys for command history, or Ctrl-Home and Ctrl-End"

DO
  CALL UpdateWatch                              'update the Watch display
  LOCATE 22, 1                                  'position the cursor
  CALL ClearEOL(Colr)                           'clean up the prompt line

  PRINT "What? ";                               'prompt for input
  CALL GetInput(Action$)                        'go get it

  LOCATE 23, 1                                  'clean up the display line
  IF NOT Null%(Action$) THEN CALL ClearEOL(Colr)'unless they hit Enter alone

  IF LEFT$(Action$, 1) = "?" THEN               'substitute "PRINT" for "?"
     Action$ = "PRINT" + MID$(Action$, 2)
  END IF

  IF LEFT$(Action$, 5) = "PRINT" THEN           'they want to print it
    Expression$ = LTRIM$(MID$(Action$, 6))      'skip past the word PRINT
    PRINT Expression$; " = ";                   'else print it
    PRINT Evaluate#(Var2Value$(Expression$))

  ELSEIF LEFT$(Action$, 5) = "WATCH" THEN       'they want to watch it
    Expression$ = LTRIM$(MID$(Action$, 6))      'skip past the word WATCH
    CALL AddWatch(Expression$)                  'add the expression
    IF ErrorCode THEN GOSUB ErrorMsg            'there was an error

  ELSEIF LEFT$(Action$, 4) = "KILL" THEN        'they want to delete a Watch
    WatchNum = VAL(MID$(Action$, 5))            'see which, trap bad entries
    IF WatchNum < 1 OR WatchNum > MaxWatch% THEN
       ErrorCode = 4                            'set "Watch not found"
       GOSUB ErrorMsg                           'and print that
    ELSE
       IF LEN(Watch$(WatchNum)) THEN
         CurWatch = CurWatch - 1
         Watch$(WatchNum) = ""                  'else, clear the Watch
       END IF
    END IF

  ELSEIF LEFT$(Action$, 4) = "EDIT" THEN        'they want to edit a Watch
    WatchNum = VAL(MID$(Action$, 5))            'see which, trap bad entries
    IF WatchNum < 1 OR WatchNum > MaxWatch% OR LEN(Watch$(WatchNum)) = 0 THEN
      ErrorCode = 4                             'set "Watch not found"
      GOSUB ErrorMsg                            'and print that
    END IF
    Temp$ = SPACE$(70)                          'make a string to edit
    LSET Temp$ = Watch$(WatchNum)               'assign the Watch expression
    CALL Editor(Temp$, ALen, SCode, Zero, Zero, Colr, Colr, 22, 7)
    Watch$(WatchNum) = Temp$                    'copy it back to the Watch
   
  ELSEIF LEFT$(Action$, 4) = "SAVE" THEN        'save the data in a file
    FileName$ = LTRIM$(MID$(Action$, 5))        'isolate the name
    CALL SaveFile(FileName$)                    'and go save it

  ELSEIF LEFT$(Action$, 4) = "LOAD" THEN        'load the data from a file
    FileName$ = LTRIM$(MID$(Action$, 5))        'isolate the name
    CALL LoadFile(FileName$)                    'and go load it
    IF ErrorCode THEN GOSUB ErrorMsg            'report any errors
   
  ELSE                                          'it must be an assignment
    Equals = INSTR(Action$, "=")                'find the equals sign
    IF Equals THEN                              'we found it
      ThisVar$ = LEFT$(Action$, Equals - 1)     'isolate the variable name
      ThisVar$ = RTRIM$(ThisVar$)               'strip trailing blanks
      ThisVar = FindVar%(ThisVar$)              'find the variable's element
      IF ErrorCode THEN GOSUB ErrorMsg          'there was an error
      Expression$ = MID$(Action$, Equals + 1)   'isolate what's past the "="
      Variable#(ThisVar) = Evaluate#(Var2Value$(Expression$))     'assign it

    ELSE                                        'it may be an illegal entry
      IF LEN(Action$) AND Action$ <> "END" THEN 'if it's not a null string
        ErrorCode = 2                           'and they're not ending
        GOSUB ErrorMsg                          'print "Syntax error"
      END IF
    END IF
  END IF

Redo:
LOOP WHILE Action$ <> "END"                     'until they type END
END


ErrorMsg:
  CALL PrintError                               'print the error message
  RETURN Redo                                   'and bail out

SUB AddWatch (Expression$) STATIC               'adds a Watch expression

    FOR X = 1 TO MaxWatch%                      'find the first open slot
      IF LEN(Watch$(X)) = 0 THEN                'we found one
        Watch$(X) = Expression$                 'add it to the list
        EXIT FOR
      END IF
    NEXT

    IF X > MaxWatch% THEN ErrorCode = 3         'if we exhausted the loop,
                                                'return "Out of Watch space"
END SUB

'----- Given a variable name, FindVar% returns its element number.
'      If the variable is not found, FindVar% will assign it.
'      If there's no more variable entries, FindVar% sets ErrorCode.
'
FUNCTION FindVar% (VarName$) STATIC

  IF NOT Legal%(VarName$) THEN                  'ensure it's a legal name
    ErrorCode = 2                               'it must start with a letter!
    EXIT FUNCTION                               'leave now and avoid the rush
  END IF

  Element = MaxVars% - 1                        'calculate how many to search
  CALL FindExact(VARPTR(Variable$(1)), Element, VarName$)   'try to find it

  IF Element = -1 THEN                          'if it doesn't yet exist
    CurVars = CurVars + 1                       'show that we have another
    Element = CurVars                           'this is the return value
    IF CurVars > MaxVars% THEN                  'do we have room for it?
      Element = 0                               'no, return a value of 0
      ErrorCode = 1                             'and "Out of variable space"
    ELSE
      Variable$(CurVars) = VarName$             'assign the variable name
    END IF
  ELSE
    Element = Element + 1                       'FindExact is zero-based
  END IF

  FindVar% = Element                            'return the element number

END FUNCTION

SUB GetInput (Action$) STATIC

  Action$ = SPACE$(70)                          'start with a clean slate
  IF CurHist = 0 THEN CurHist = 1               'initialization code

  DO
    CALL Editor(Action$, ALen, SCode, Zero, Zero, Colr, Colr, CSRLIN, POS(0))
    
    SELECT CASE SCode                           'see how editing was ended
      CASE 13                                   'Enter
        IF NumHist < MaxHist% THEN              'don't go past the end
          NumHist = NumHist + 1                 'we're remembering another
        ELSE                                    'else, slide 'em down one
          CALL DeleteStr(VARPTR(History$(1)), MaxHist% - 1)
        END IF
        CurHist = NumHist + 1                   'this is the current history
        History$(NumHist) = Action$             'remember this command
        EXIT DO                                 'they're satisfied, leave

      CASE -72                                  'Up arrow
        IF CurHist > 1 THEN                     'back up one level if possible
          CurHist = CurHist - 1
        END IF

      CASE -80                                  'Down arrow
        IF CurHist < NumHist + 1 THEN           'advance a level if possible
          CurHist = CurHist + 1
        END IF
         
      CASE -119                                 'Ctrl-Home
        CurHist = 1                             'go to the first command

      CASE -117                                 'Ctrl-End
        CurHist = NumHist                       'go to last active command

      CASE 27                                   'Escape
        CurHist = NumHist + 1                   'clear by jumping past end

      CASE ELSE                                 'QB 4.0 requires a CASE ELSE
    END SELECT

    LSET Action$ = History$(CurHist)            'assign the current command

  LOOP

  Action$ = UCASE$(LTRIM$(RTRIM$(Action$)))     'clean up the text

END SUB

FUNCTION Legal% (Work$) STATIC                  'ensures a leading letter
 
  Char = ASCII%(Work$)                          'get the first character
  Legal% = -1                                   'assume True
  IF Char < 65 OR Char > 90 THEN Legal% = 0     'not a letter, return False
 
END FUNCTION

SUB LoadFile (FileName$) STATIC

    IF NOT Exist%(FileName$) THEN               'ensure it's there
      ErrorCode = 5                             'if not, return an error

    ELSE
      REDIM Variable$(1 TO MaxVars%)            'start with empty arrays
      REDIM Variable#(1 TO MaxVars%)
      REDIM Watch$(1 TO MaxWatch%)

      OPEN FileName$ FOR INPUT AS #1            'open the file
        INPUT #1, CurVars                       'load the number of variables
        INPUT #1, CurWatch                      'and Watch expressions
        FOR X = 1 TO CurVars                    'load all the variable names
          INPUT #1, Variable$(X)
        NEXT
        FOR X = 1 TO CurVars                    'load all the variable values
          INPUT #1, Variable#(X)
        NEXT
        FOR X = 1 TO CurWatch                   'load the Watch expressions
          INPUT #1, Watch$(X)
        NEXT
      CLOSE #1                                  'all done, close the file
    END IF
     
END SUB

SUB PrintError STATIC

    SELECT CASE ErrorCode                       'see which error happened
      CASE 1                                    'and print as appropriate
        PRINT "Out of variable space"
      CASE 2
        PRINT "Syntax error"
      CASE 3
        PRINT "Out of Watch space"
      CASE 4
        PRINT "Watch variable not found"
      CASE 5
        PRINT "File not found"
      CASE ELSE                                 'QB 4.0 needs a CASE ELSE
    END SELECT
   
    ErrorCode = 0                               'regardless, clear the error
                                                'for the next time through
END SUB

SUB SaveFile (FileName$) STATIC

    CurWatch = 0                                'count the Watch expressions
    FOR X = 1 TO MaxWatch%
      IF LEN(Watch$(X)) THEN CurWatch = CurWatch + 1
    NEXT

    OPEN FileName$ FOR OUTPUT AS #1             'open the file
      PRINT #1, CurVars                         'save the number of variables
      PRINT #1, CurWatch                        'and Watch expressions
      FOR X = 1 TO CurVars                      'save all the variable names
        PRINT #1, Variable$(X)
      NEXT
      FOR X = 1 TO CurVars                      'save all the variable values
        PRINT #1, Variable#(X)
      NEXT
      FOR X = 1 TO CurWatch                     'save the Watch expressions
        IF LEN(Watch$(X)) THEN                  'but only the live ones
          PRINT #1, Watch$(X)
        END IF
      NEXT
    CLOSE #1                                    'all done, close the file

END SUB

SUB UpdateWatch STATIC

    LOCATE 6, 1                                 'start on the top line
    Active = 0                                  'assume no Watches are active

    FOR X = 1 TO MaxWatch%                      'print each Watch expression
      Watch$(X) = LTRIM$(RTRIM$(Watch$(X)))
      IF LEN(Watch$(X)) THEN                    'if this one is live, do it
        Active = Active + 1                     'show we have another one
        CALL ClearEOL(Colr)                     'clear any junk on the line
        PRINT Active; CHR$(29); ": ";           'number the watch expressions
        PRINT Watch$(X); " = ";                 'print the expression itself
        PRINT Evaluate#(Var2Value$(Watch$(X)))  'and finally its value
      END IF
    NEXT

    FOR X = 1 TO MaxWatch% - Active             'clear all obsolete Watches
      CALL ClearEOL(Colr)
      PRINT
    NEXT

END SUB

'----- This function replaces all occurrences of all variable names with
'      the current variable values.
'
FUNCTION Var2Value$ (Expression$) STATIC
   
    Table$ = " +-/*\^()="                       'recognized delimiters
    Work$ = Expression$ + " "                   'force an ending delimiter
    Pointer = 1                                 'start at the beginning

Again:
    SavePtr = Pointer                           'save where we are for later
    Pointer = InstrTbl%(Pointer, Work$, Table$) 'search for a delimiter
    IF Pointer = SavePtr THEN                   'trap two delimiters in a row
      Pointer = Pointer + 1                     'bump past this one
      GOTO Again                                'and continue
    END IF

    IF Pointer THEN                             'we found one, isolate the
      VarName$ = MID$(Work$, SavePtr, Pointer - SavePtr)     'variable name
      VarLen = LEN(VarName$)                                 'save the length
      Element = MaxVars% - 1                    'calculate how many to search
      CALL FindExact(VARPTR(Variable$(1)), Element, VarName$) 'try to find it
      Element = Element + 1                     'FindExact is zero-based
      IF Element THEN                           'it's in there
        ThisVal$ = STR$(Variable#(Element))     'make a string of its value
        ThisLen = LEN(ThisVal$)                 'calc the replacement length
        Work$ = LEFT$(Work$, SavePtr - 1) + ThisVal$ + MID$(Work$, Pointer)
        Pointer = Pointer + (ThisLen - VarLen) + 1  'bump past this delimiter
      END IF
      GOTO Again                                'and keep searching
    END IF

    Var2Value$ = Work$                          'assign the function output

END FUNCTION

