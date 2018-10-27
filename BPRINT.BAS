'********** BPRINT.BAS - prints BASIC strings through DOS

'Copyright (C) 1988


DEFINT A-Z

DECLARE SUB BPrint (X$)
DIM FixLen AS STRING * 30

FixLen$ = "This string has a fixed length..."   'dots show how assigning to a
                                                'fixed length string truncates
Normal$ = "This is a normal BASIC string"
Value! = 143.801

CLS
CALL BPrint(FixLen$ + CHR$(13) + CHR$(10))
CALL BPrint(Normal$ + CHR$(13) + CHR$(10))
CALL BPrint("This is a number:" + STR$(Value!) + CHR$(13) + CHR$(10))
LOCATE 20, 20
CALL BPrint("This shows that BPrint honors the current cursor location")

