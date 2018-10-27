'********** KeyStat.Bas - demonstrates all of the QuickPak Pro keyboard stuff

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z

DECLARE FUNCTION CapsLock% ()
DECLARE FUNCTION NumLock% ()
DECLARE FUNCTION ScrlLock% ()
DECLARE FUNCTION ShiftKey% ()
DECLARE FUNCTION CtrlKey% ()
DECLARE FUNCTION AltKey% ()
DECLARE SUB QPrint0 (X$, Colr)

CLS
PRINT "Press any of the shift and lock keys, or Escape to end"
LOCATE 25, 1, 0

DO

   LOCATE , 1
   Colr = 0
   IF CapsLock THEN Colr = 112
   QPrint0 " CAP ", Colr

   LOCATE , 10
   Colr = 0
   IF NumLock THEN Colr = 112
   QPrint0 " NUM ", Colr

   LOCATE , 20
   Colr = 0
   IF ScrlLock THEN Colr = 112
   QPrint0 " SCRL ", Colr


   LOCATE , 30
   Colr = 0
   IF ShiftKey THEN Colr = 112
   QPrint0 " SHIFT ", Colr

   LOCATE , 40
   Colr = 0
   IF CtrlKey THEN Colr = 112
   QPrint0 " CTRL ", Colr

   LOCATE , 50
   Colr = 0
   IF AltKey THEN Colr = 112
   QPrint0 " ALT ", Colr

LOOP UNTIL INKEY$ = CHR$(27)

COLOR 7, 0

