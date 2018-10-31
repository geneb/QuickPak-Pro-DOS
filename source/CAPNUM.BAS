'********** CAPNUM.BAS - prints status of Cap and NumLock keys

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z

DECLARE FUNCTION Peek1% (Segment, Address)
DECLARE SUB QPrint (X$, Colr, Page)

SUB CapNum STATIC

   CapStatus = Peek1%(0, &H417) AND &H40        'get BIOS status of Caps Lock
   NumStatus = Peek1%(0, &H417) AND &H20        'get BIOS status of Num Lock
   H = POS(0): V = CSRLIN                       'save cursor position

   IF Cap = CapStatus GOTO QNumCheck            'no change since last check

   Cap = CapStatus                              'save Caps status
   LOCATE 25, 69                                'position to print status msg

   IF CapStatus THEN                            'print or erase message
      CALL QPrint(" CAP ", 112, -1)             '112 = black on white
   ELSE
      CALL QPrint(SPACE$(5), 7, -1)             '7 = white on black
   END IF

QNumCheck:
   IF Num = NumStatus GOTO QCapNumExit          'no change since last check

   Num = NumStatus                              'save Num status
   LOCATE 25, 75                                'position to print status msg

   IF NumStatus THEN                            'print or erase message
      CALL QPrint(" NUM ", 112, -1)
   ELSE
      CALL QPrint(SPACE$(5), 7, -1)
   END IF

QCapNumExit:
   LOCATE V, H                                  'restore cursor position

END SUB

