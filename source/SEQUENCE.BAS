'********** Sequence.Bas - demonstrates Sequence.Asm

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE SUB Sequence (Work$)
DECLARE SUB Pause (Ticks)

CLS
Work$ = "AAA-50"                'this is our "seed" string

DO
    LOCATE , 1
    PRINT Work$;                'print the string to show it working
    Sequence Work$              'increment the string in sequence
    Pause 2                     'slow the display to make this all visible
LOOP UNTIL INKEY$ = CHR$(27)    'quit if Escape

