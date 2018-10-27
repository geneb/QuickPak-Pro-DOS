'********** ReadSect.Bas - a callable sector reading utility

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION ASCII% (Work$)
DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION GetDrive% ()
DECLARE FUNCTION QPHex$ (Value, Digits)
DECLARE FUNCTION QPRepl$ (Char)

DECLARE SUB APrint0 (BYVAL Address, NumEls, FirstChar, NumChars, Clr)
DECLARE SUB Chime (Number)
DECLARE SUB DiskInfo (Drive$, Bytes, Sectors, Clusters, Total)
DECLARE SUB QPrint0 (X$, Colr)
DECLARE SUB ReadSect (Drive$, Info$, Sector&)

FUNCTION QPRepl$ (Char)

    IF Char = 0 OR Char = 255 THEN
       QPRepl$ = "."
    ELSE
       QPRepl$ = CHR$(Char)
    END IF

END FUNCTION

SUB ReadSector

QPReDo:
    CLS
    REDIM Display$(22)                  'holds the screen display
    FOR X = 1 TO 22
	Display$(X) = SPACE$(80)
    NEXT

    PRINT "Enter Drive to read from: ";
    LOCATE , , 1

    DO
       Drive$ = UCASE$(INKEY$)
    LOOP UNTIL LEN(Drive$)

    IF Drive$ = CHR$(13) THEN Drive$ = CHR$(GetDrive%)
    PRINT Drive$; ":"
   
    DiskInfo Drive$, Bytes, Sectors, Clusters, Total
    IF DOSError% THEN
       PRINT
       PRINT "Invalid drive or drive error"
       PRINT "Press ENTER to continue ";
       INPUT "", X$
       GOTO QPReDo
    END IF

    TotalSectors& = CLNG(Total) * Sectors
   
    PRINT "Enter Sector (0 -"; STR$(TotalSectors&); "): ";
    INPUT "", X$: Sector& = VAL(X$)

    IF Sector& > TotalSectors& OR Sector& < 0 THEN
       PRINT
       PRINT "Invalid Sector"
       PRINT "Press ENTER to continue ";
       INPUT "", X$
       GOTO QPReDo
    END IF
   
    CLS
    LOCATE 24, 1, 0
    QPrint0 STRING$(80, "Í"), 2
    LOCATE 25, 9
    QPrint0 "Use PgUp/PgDn, Esc to Exit, Enter to select new Drive/Sector", 2
    LOCATE 2, 1

    Info$ = SPACE$(512)                 'allocate space for sector data

QPRS:

    LOCATE 23, 70
    QPrint0 "Wait", 137
    ReadSect Drive$, Info$, Sector&

    IF DOSError% THEN
       CLS
       PRINT "Error Reading Drive "; Drive$; ":"
       GOTO ExitSub
    END IF


    FOR X = 0 TO LEN(Info$) - 1         'build sector data for display
	Dat = ASCII%(MID$(Info$, X + 1))
	MID$(Display$(1 + X \ 24), 1 + (X MOD 24) \ 4 + 2 * (X MOD 24)) = QPHex$(Dat, 2)
	MID$(Display$(1 + X \ 24), 57 + (X MOD 24)) = QPRepl$(Dat)
    NEXT

    LOCATE 1, 1
    QPrint0 "Drive " + UCASE$(Drive$) + ":  Sector" + STR$(Sector&) + SPACE$(4), 2
    PRINT
    APrint0 VARPTR(Display$(1)), 22, 1, 80, 7


QPCommand:

    Cmd$ = INKEY$
    IF Cmd$ = "" GOTO QPCommand

    IF Cmd$ = CHR$(0) + "I" THEN        'PgUp key
       Sector& = Sector& - 1
       IF Sector& < 0 THEN Sector& = TotalSectors&      'wrap to last sector
       GOTO QPRS
    END IF


    IF Cmd$ = CHR$(0) + "Q" THEN        'PgDn key
       Sector& = Sector& + 1
       IF Sector& > TotalSectors& THEN Sector& = 0      'wrap to first sector
       GOTO QPRS
    END IF


    IF Cmd$ = CHR$(13) GOTO QPReDo      'Enter key
    IF Cmd$ = CHR$(27) GOTO ExitSub     'Escape key
    Chime 6                             'Invalid key
    GOTO QPCommand

ExitSub:
    ERASE Display$                      'free up the memory
    Info$ = ""


END SUB

