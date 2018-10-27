'********** GetEquip.Bas - use GetEquip to report one the installed equipment

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION GetCPU% ()
DECLARE FUNCTION MathChip% ()

DEF FnTrim$ (X) = LTRIM$(STR$(X))       'strips that damn leading blank

DEF FnPlural$ (Number, Message$)        'this avoids dumb messages such as
    IF Number = 1 THEN                  '  "1 floppy drive(s)"
       FnPlural$ = STR$(Number) + " " + Message$
    ELSE
       FnPlural$ = STR$(Number) + " " + Message$ + "s"
    END IF
END DEF

PRINT : PRINT
CALL GetEquip(Floppies, Parallels, Serials)

PRINT "This PC has";
PRINT FnPlural$(Floppies, "floppy disk drive"); ",";
PRINT FnPlural$(Parallels, "parallel printer"); ", and";
PRINT FnPlural$(Serials, "serial port"); "."
PRINT
PRINT "The installed CPU is an 80"; FnTrim$(GetCPU%);

IF GetCPU% = 486 THEN
   IF MathChip% THEN
      PRINT "DX"
   ELSE
      PRINT "SX"
   END IF
ELSE
   IF MathChip% THEN
      PRINT
      PRINT "A math coprocessor is also installed."
   END IF
END IF

