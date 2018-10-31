'******** SRCHPATH.BAS

'Copyright (c) 1991 Crescent Software

'This functions accepts an incoming executable file name, and locates it
'in your system's PATH.  It returns the complete path to the specified file
'name if it is found, otherwise it returns a null string.

DEFINT A-Z

DECLARE FUNCTION ASCII% (Work$)
DECLARE FUNCTION Exist% (FileName$)
DECLARE FUNCTION ParseString$ (CurPos, Work$, Delimit$)
DECLARE FUNCTION SearchPath$ (FileName$)

FUNCTION SearchPath$ (FileName$) STATIC

   SearchPath$ = ""                     'assume we won't find it
   Path$ = ";" + ENVIRON$("PATH")       'the leading ";" forces searching to
                                        '  start in the current directory
   Dot = INSTR(FileName$, ".")          'see if they gave an extension
   Ext$ = ""                            'default to none given
   Found = 0                            'assume it won't be found
   CurPos = 1                           'start at the beginning of the path
  
   DO

     ThisPath$ = ParseString$(CurPos, Path$, ";")  'get the next path name
     Temp = ASCII%(RIGHT$(ThisPath$, 1))           'tack on a "\" if needed
     IF Temp <> -1 AND Temp <> 58 AND Temp <> 92 THEN
       ThisPath$ = ThisPath$ + "\"
     END IF
     ThisName$ = ThisPath$ + FileName$          'build a complete name

     IF Dot THEN                                'they gave an extension
       GOSUB DoExist
     ELSE
       Ext$ = ".COM"
       GOSUB DoExist
       Ext$ = ".EXE"
       GOSUB DoExist
       Ext$ = ".BAT"
       GOSUB DoExist
     END IF

   LOOP WHILE CurPos < LEN(Path$)
   EXIT FUNCTION

DoExist:                                'a GOSUB to a CALL is low code
   Temp$ = ThisName$ + Ext$             'build the string to try
   IF Exist%(Temp$) THEN                'if it's there
     SearchPath$ = Temp$                'assign the function
     EXIT FUNCTION                      'and leave
   END IF
   RETURN

END FUNCTION
