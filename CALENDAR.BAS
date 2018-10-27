'********** CALENDAR.BAS - pop-up calendar

'Copyright (c) 1988 by Harald Zoschke
'Copyright (c) 1988 by Crescent Software


'Displaying and removing the calendar is accomplished by the same call,
'the only difference is the contents of the switch variable Action
'(Action = 1 to show calendar, Action = 0 to remove it).
'
'QuickPak assembly routines used: ScrnRest0, ScrnSave0, QPrint0
'
'Important variables:
'
'Mnth -   month (1 ... 12)
'Yr  -   4 places (YYYY)
'Dy   - the day to be highlighted
'ULRow, ULCol - upper left corner of calendar
'Action - indicates whether to show or clear the display: -1=Show, 0=Clear
'Color1 - color to use for the calendar border frame
'Color2 - color to use for the day names and numbers


DEFINT A-Z
DECLARE SUB ScrnSave0 (ULRow, ULCol, LRRow, LRCol, SEG Address)
DECLARE SUB ScrnRest0 (ULRow, ULCol, LRRow, LRCol, SEG Address)
DECLARE SUB QPrint0 (X$, Colr)


QPCName.List:
   DATA January, February, March, April, May, June
   DATA July, August, September, October, November, December

'Calendar subroutine by Harald Zoschke
'Copyright (c) 1988 Crescent Software
'
SUB Calendar (IMonth, IDay, IYear, ULRow, ULCol, Colr1, Colr2, Action) STATIC

Mnth = IMonth: Dy = IDay: Yr = IYear            'preserve incoming variables

ULRow1 = ULRow: LRRow = ULRow + 11                      'frame parameters
ULCol1 = ULCol: LRCol = ULCol + 23
V = CSRLIN: H = POS(0)                                  'save the cursor

IF Action THEN
   REDIM A(288)                                         'holds the screen
   CALL ScrnSave0(ULRow1, ULCol1, LRRow, LRCol, A(0))   'save screen
ELSE
   CALL ScrnRest0(ULRow1, ULCol1, LRRow, LRCol, A(0))   'restore old screen
   ERASE A
   GOTO QPCDone
END IF

GOSUB QPCFrame          'draw frame
GOSUB QPCCalendar       'calculate and display calendar
GOTO QPCDone            'all done

QPCCalendar: 
   GOSUB QPCMonth.Name
   GOSUB QPCCalc
   Mon.First! = NextMon.First!
   LOCATE ULRow1 + 1, ULCol1 + 3, 0
   CALL QPrint0(" " + LEFT$(Moname$ + SPACE$(10), 10) + STR$(Yr) + SPACE$(4), Colr2)
   ULRow1 = ULRow1 + 3
   LOCATE ULRow1, ULCol1 + 1
   CALL QPrint0(" Su Mo Tu We Th Fr Sa", Colr2)  'Germany: " Mo Di Mi Do Fr Sa So"

   DayOfWeek = NextMon.First! - INT(NextMon.First! / 7) * 7 + 1 'Germany: w/o +1
   ULRow1 = ULRow1 + 2
   LOCATE ULRow1, ULCol1 + 1
   IF DayOfWeek <> 7 THEN
      CALL QPrint0(SPACE$(DayOfWeek * 3), Colr1) 'Germany: * 4
      LOCATE , POS(0) + DayOfWeek * 3
   END IF
   Mnth = Mnth - INT(Mnth / 12.1) * 12 + 1
   IF Mnth = 1 THEN Yr = Yr + 1
   GOSUB QPCCalc

   OldColor = (Colr2 AND 112) / 16 + (Colr2 AND 15) * 16 AND 127
   FOR X = 1 TO NextMon.First! - Mon.First!
      CALL QPrint0(" ", Colr2)
      LOCATE , POS(0) + 1
      IF X = Dy THEN
        SWAP Colr2, OldColor           'the day to highlight
      END IF
      CALL QPrint0(RIGHT$(" " + STR$(X), 2), Colr2)
      IF X = Dy THEN SWAP Colr2, OldColor
      LOCATE , POS(0) + 2
      DayOfWeek = DayOfWeek + 1
      IF INT(DayOfWeek / 7) = DayOfWeek / 7 THEN    'new line for next week
         ULRow1 = ULRow1 + 1
         LOCATE ULRow1, ULCol1 + 1
      END IF
   NEXT
RETURN

QPCCalc:                      'calculate calendar
   Temp1 = Mnth + 13
   Temp2 = Yr - 1
   IF Mnth > 2 THEN
       Temp1 = Mnth + 1
       Temp2 = Yr
   END IF
   NextMon.First! = INT(365.25 * Temp2) - 693975 + INT(30.6 * Temp1)
RETURN

QPCMonth.Name:
    RESTORE QPCName.List
    FOR M = 1 TO Mnth
        READ Moname$
    NEXT M
RETURN

QPCFrame:
   LOCATE ULRow1, ULCol1
   CALL QPrint0("…" + STRING$(22, "Õ") + "ª", Colr1)
   LOCATE ULRow1 + 1
   CALL QPrint0("∫" + STRING$(22, " ") + "∫", Colr1)
   LOCATE ULRow1 + 2
   CALL QPrint0("Ã" + STRING$(22, "Õ") + "π", Colr1)
   LOCATE ULRow1 + 3
   CALL QPrint0("∫" + STRING$(22, " ") + "∫", Colr1)
   LOCATE ULRow1 + 4
   CALL QPrint0("Ã" + STRING$(22, "Õ") + "π", Colr1)
   FOR X = ULRow1 + 5 TO ULRow1 + 10
      LOCATE X
      CALL QPrint0("∫" + SPACE$(22) + "∫", Colr1)
   NEXT
   LOCATE ULRow1 + 11
   CALL QPrint0("»" + STRING$(22, "Õ") + "º", Colr1)
RETURN

QPCDone:
   LOCATE V, H, 0               'Alte Werte fÅr Screen-Restore wiederhFirst.

END SUB

