'********* InstrTbl.Bas - demonstrates InstrTbl.Asm

DEFINT A-Z

DECLARE FUNCTION InstrTbl% (Start, Source$, Table$)


CLS
Start = 1                               'start looking at the beginning
Source$ = "Ethan Winer"                 'this is the string to search
Table$ = "e123"                         'find the first match from this table

PRINT InstrTbl%(Start, Source$, Table$) 'this will find the "e" at position 10

