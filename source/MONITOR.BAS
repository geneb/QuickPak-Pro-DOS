'********** Monitor.Bas - determines the currently active monitor

'Copyright (c) 1989 Crescent Software


DEFINT A-Z
DECLARE FUNCTION Monitor% ()
DECLARE FUNCTION EGAMem% ()

CLS
M = Monitor%            'get the monitor type
Memory = EGAMem% * 64   'if it's an EGA, get its memory

SELECT CASE M
    
    CASE 1
         PRINT "It is a plain old monochrome adapter"

    CASE 2
         PRINT "It is a Hercules card"

    CASE 3
         PRINT "It is a plain old CGA adapter"

    CASE 4
         PRINT "It is an EGA card with a monochrome monitor,"
         PRINT "And it has"; Memory; "K of memory on board"

    CASE 5
         PRINT "It is an EGA card with a color monitor,"
         PRINT "And it has"; Memory; "K of memory on board"

    CASE 6
         PRINT "It is a VGA adapter with a monochrome monitor"

    CASE 7
         PRINT "It is a VGA adapter with a color monitor"

    CASE 8
         PRINT "It is an MCGA adapter with a monochrome monitor"

    CASE 9
         PRINT "It is an MCGA adapter with a color monitor"

    CASE 10
         PRINT "It is an EGA emulating a CGA, capable of SCREEN 8,"
         PRINT "And it has"; Memory; "K of memory on board"

    CASE 11
         PRINT "It is an 8514/A adapter"

    CASE ELSE
         PRINT "I give up -- what the heck kind of video adapter is it?"

END SELECT

