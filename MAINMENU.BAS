'*********** MAINMENU.BAS - scroll bar menu subprogram

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z

DECLARE SUB QPrint0 (X$, Colr)
DECLARE SUB SplitColor (Colr, FG, BG)
DECLARE FUNCTION OneColor% (FG, BG)

SUB MainMenu (Item$(), Choice, Colr) STATIC     'Item$() has one dimension
                                                'Choice is the value returned

    CALL SplitColor(Colr, FG, BG)               'break out the menu colors

'----- determine how many choices to display, and how long the longest one is

    MaxNum = UBOUND(Item$)                      'find number of items
    IF MaxNum > 9 THEN MaxNum = 9               'only nine items allowed

    WHILE Item$(MaxNum) = ""                    'seek last valid item
        MaxNum = MaxNum - 1
    WEND

    MaxLen = 50                                 'set minimum border width
    FOR X = 1 TO MaxNum
        L = LEN(Item$(X))
        IF L > 70 THEN L = 70                   'cut to 70 chars if necessary
        IF L > MaxLen THEN MaxLen = L           'find length of longest item
    NEXT


'----- draw border and display items on the screen

    CLS
    Top = 11 - MaxNum                           'define top line
    LeftMargin = 38 - MaxLen / 2                'define left margin
    RightMargin = LeftMargin + MaxLen + 6       'and right margin

    LOCATE Top, LeftMargin                      'draw top line
    CALL QPrint0("É" + STRING$(5 + MaxLen, "Í") + "»", Colr)

    FOR X = 2 TO 2 + MaxNum * 2                         'draw the sides and
        PRINT
        LOCATE , LeftMargin                             'display the items
        CALL QPrint0("º", Colr)
        IF X MOD 2 THEN
           LOCATE , POS(0) + 1
           CALL QPrint0(STR$((X - 1) / 2) + ") " + LEFT$(Item$((X - 1) / 2), 70), Colr)
        END IF
        LOCATE , RightMargin
        CALL QPrint0("º", Colr)
    NEXT

    PRINT
    LOCATE , LeftMargin                         'draw the bottom
    CALL QPrint0("È" + STRING$(5 + MaxLen, "Í") + "¼", Colr)

    PRINT
    LOCATE , LeftMargin + 2
    CALL QPrint0("Please Enter Your Choice: ", Colr)
    LOCATE , LeftMargin + 28
    CALL QPrint0(CHR$(22), Colr OR 128)         'simulate cursor


'----- make inverse cursor bar over Items

    Choice = 1                                  'select Choice 1 initially

DO

    GOSUB Display                               'make inverse bar on item

    DO
       LOCATE 1, 1: CALL QPrint0(DATE$, Colr)   'update the time and date
       LOCATE , 72: CALL QPrint0(TIME$, Colr)
       X$ = INKEY$                              'get a keypress
    LOOP UNTIL LEN(X$)

    IF X$ = CHR$(13) THEN EXIT SUB              'Enter key
    IF X$ = CHR$(27) THEN                       'Escape key
       Choice = 0
       EXIT SUB
    END IF

    GOSUB Display                               'restore old item
    X = VAL(X$)                                 'set X to new item

        IF X > 0 AND X <= MaxNum THEN Choice = VAL(X$)  'numeric key

        IF X$ = CHR$(0) + "H" THEN                      'Up arrow
           Choice = Choice - 1
           IF Choice < 1 THEN Choice = MaxNum
        END IF

        IF X$ = CHR$(0) + "P" THEN                      'Down arrow
           Choice = Choice + 1
           IF Choice > MaxNum THEN Choice = 1
        END IF

        IF X$ = CHR$(0) + "G" THEN Choice = 1           'Home key

        IF X$ = CHR$(0) + "O" THEN Choice = MaxNum      'End key

LOOP                                                    'get again


'----- Mark/Unmark cursor bar Item - depending on current FG and BG colors

Display:

    SWAP FG, BG                                         'hilight/un-hilight
    LOCATE Top + 2 * Choice, LeftMargin + 1             'print choice inverse
    CALL QPrint0(STR$(Choice) + ") " + LEFT$(Item$(Choice), 70) + " ", OneColor%(FG, BG))
    RETURN

END SUB

