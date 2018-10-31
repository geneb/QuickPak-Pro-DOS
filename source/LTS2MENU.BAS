'********* LTS2MENU.BAS - a Lotus(tm) style menu with prompt information

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE SUB ClearEOL (Colr)
DECLARE FUNCTION OneColor% (FG, BG)
DECLARE SUB QPrint (X$, Colr, Page)
DECLARE SUB SplitColor (Both, FG, BG)
DECLARE SUB ScrnSave0 (TRow, LCol, BRow, RCol, SEG Address)
DECLARE SUB ScrnRest0 (TRow, LCol, BRow, RCol, SEG Address)

SUB Lts2Menu (Item$(), Prompt$(), Choice, Colr)

   'Item$() and Prompt$() have one dimension
   'Choice is the value returned, or zero if Escape is pressed
   'Colr is the packed color to use for the display
   '
   'NOTE: The foreground and background portions of Colr are reversed for
   '      the highlighted item.  Also, a new color is derived from Colr
   '      for the prompt message - change this to suit by searching for
   '      the string "prompt color".
   '
   'NOTE: A comment near the end shows how to modify this menu to exit
   '      when a letter key is pressed, without also needing to press Enter.
   '      If you do this, each item should start with a unique first letter.
   '      Search for the string "having" to find where.

    LOCATE , , 0                        'turn off the cursor
    CALL SplitColor(Colr, FG, BG)       'split color into FG and BG

    REDIM ScrBuf(0 TO 159)
    TRow = CSRLIN
    CALL ScrnSave0(TRow, 1, TRow + 1, 80, ScrBuf(0))
    CALL ClearEOL(7)                    'clear any old prompt information

'-- determine how many choices there are

    NumItems = UBOUND(Item$)      'get the number of items passed

    WHILE Item$(NumItems) = ""    'seek the last non-blank item
       NumItems = NumItems - 1
    WEND

    REDIM Break(NumItems + 1)   'remembers which items start on a new screen
    Break(NumItems + 1) = -2    'mark one past the end as a flag
    Col = 1                     'tracks the accumulated line width and columns
    Page = 1                    'tracks which item begins a new screen page

  
'-- Build a table of starting columns and page breaks for each item.
'   For each item that begins a new page, use a negative version of the
'   page number as a flag.  we don't need the starting column for those
'   anyway, because the first item on each pagwe always is in column 1.
'   For all other items, the equivalent Break() element will hold the
'   column in which this item is located.

    FOR X = 1 TO NumItems
        Break(X) = Col          'assume we're not starting a new screen page
        IF X = 1 THEN Break(X) = -1
        Col = Col + LEN(Item$(X)) + 2   'add two for a small border
        IF Col > 80 THEN
           Page = Page + 1      'we advanced to the next page
           Break(X) = -Page     'this item starts a page, remember which one
           Col = LEN(Item$(X)) + 3
        END IF
    NEXT

  
'-- print a page-full of items

    Choice = 1                  'start with item 1 the first time

QPPrintLt2:
    X = Choice                  'assume we'll start at the current item
    WHILE Break(X) > 0          'seek the first item on this page
        X = X - 1
    WEND

    DO                          'print until the negative Break() flag
       C = Colr                 'assume the item being printed is NOT current
       IF X = Choice THEN       'we were wrong, reverse the FG and BG colors
          C = OneColor%(BG, FG AND 7)
          LOCATE CSRLIN + 1, 1  'go down a line and to the first column
          CALL ClearEOL(7)      'clear any old prompt information
          'you may adjust the prompt color by changing the line below
          CALL QPrint(" " + Prompt$(X) + " ", ((NOT Colr) AND 7) OR 2, -1)
          LOCATE CSRLIN - 1     'return to the line above
       END IF

       IF Break(X) < 0 THEN     'if it's the first item on this page
          LOCATE , 1            'locate to the first column
          IF ClearFlag THEN         'if we just crossed a page boundary
             CALL ClearEOL(Colr)    '  clear any old items that may still show
             ClearFlag = 0
          END IF
       ELSE                     'otherwise
          LOCATE , Break(X)     '  locate to the correct column
       END IF
     
       CALL QPrint(" " + Item$(X) + " ", C, -1)
       X = X + 1                'advance to the next item
    LOOP UNTIL Break(X) < -1

    DO
       X$ = INKEY$
    LOOP UNTIL LEN(X$)

    IF LEN(X$) = 2 THEN         'extended key
       SELECT CASE ASC(RIGHT$(X$, 1))
          CASE 71               'Home Key
             Choice = 1         'set to the first item in the list
             ClearFlag = 1      'flag to clear old items

          CASE 75               'Left Arrow
             IF Choice > 1 THEN
                Choice = Choice - 1
                IF Break(Choice) < 0 THEN ClearFlag = 1
             ELSE
                Choice = NumItems
                ClearFlag = 1
             END IF

          CASE 77               'Right Arrow
             IF Choice < NumItems THEN
                Choice = Choice + 1
                IF Break(Choice) < 0 THEN ClearFlag = 1
             ELSE
                Choice = 1
                ClearFlag = 1
             END IF
            

          CASE 79               'End Key
             Choice = NumItems
             ClearFlag = 1

          CASE ELSE
       END SELECT

    ELSE
       SELECT CASE X$
          CASE CHR$(13)         'Enter Key
             GOTO QPExitLt2     'exit with the current choice

          CASE CHR$(27)         'Escape Key
             Choice = 0         'set the choice to zero as an Escape flag
             GOTO QPExitLt2

          CASE ELSE             'they must be typing a choice's first letter
             X = Choice         'scan through each item looking for a match
             DO                 'starting at the item after the current one
                IF X = NumItems THEN X = 0  'wrap past the last one
                X = X + 1                   'consider the next item

                IF ASC(UCASE$(Item$(X))) = ASC(UCASE$(X$)) THEN
                   Choice = X               'we found one, save where
                   ClearFlag = 1            'set flag to clear old stuff
                   EXIT DO                  '  and stop searching
                   'change the EXIT DO above to GOTO QPExitLt2 to exit without
                   '  having to press Enter
                END IF
                IF X = Choice THEN EXIT DO  'we already went around once
             LOOP
       END SELECT
    END IF

    GOTO QPPrintLt2

QPExitLt2:
    CALL ScrnRest0(TRow, 1, TRow + 1, 80, ScrBuf(0))
    ERASE Break, ScrBuf

END SUB

