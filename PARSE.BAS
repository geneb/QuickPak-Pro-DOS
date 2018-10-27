'********* Parse.Bas - parses elements from a delimited string

'Copyright (c) 1988 Paul Passarelli
'Copyright (c) Crescent Software


'Like the other QuickPak Professional functions, Delimit% and the Parse
'subprogram are intended to be copied into your own programs.  This is
'a demo of parsing the PATH into a series of individual strings.  Comments
'below also show how to parse COMMAND$ for one or more switches.


DEFINT A-Z
DECLARE FUNCTION Delimit% (Work$, Delim$)
DECLARE FUNCTION InCount% (Source$, Search$)
DECLARE SUB Parse (Work$, Delim$, Array$())

'Delimit% returns the value to which the array must be dimensioned
'and Parse unpacks the string into the array

CLS
Work$ = ENVIRON$("PATH")        'use this to parse the current PATH
'Work$ = COMMAND$               'use this for COMMAND$

Delim$ = "+-/,;_ "              'some common delimiters

J = Delimit%(Work$, Delim$) + 1 'first find how big an array we need
REDIM Array$(J)                 '+1 is needed to account for the last item

Parse Work$, Delim$, Array$()   'do it to it

PRINT Work$
PRINT

FOR X = 1 TO J
    PRINT "==>" + Array$(X) + "<=="
NEXT

FUNCTION Delimit% (Work$, Delim$)

   FOR X% = 1 TO LEN(Delim$)
       Counter% = Counter% + InCount%(Work$, MID$(Delim$, X%, 1))
   NEXT X%

   Delimit% = Counter%

END FUNCTION

SUB Parse (Work$, Delim$, Array$())

    BeginPtr% = 1
    Element% = 1

    FOR EndPtr% = 1 TO LEN(Work$)
        IF INSTR(Delim$, MID$(Work$, EndPtr%, 1)) THEN
           Array$(Element%) = MID$(Work$, BeginPtr%, EndPtr% - BeginPtr%)
           Element% = Element% + 1
           BeginPtr% = EndPtr% + 1
        END IF
    NEXT

    Array$(Element%) = MID$(Work$, BeginPtr%)

END SUB

