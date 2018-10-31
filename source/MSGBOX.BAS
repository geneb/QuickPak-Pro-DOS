'********** MSGBOX.BAS

'Copyright (c) 1988 Crescent Software

DEFINT A-Z

DECLARE SUB CSMsgBox (Message$, Wdth, Cnf AS ANY)
DECLARE SUB MQPrint (X$, Colr)
DECLARE SUB MPaintBox (ULRow, ULCol, LRRow, LRCol, Colr)
DECLARE SUB MScrnSave (ULRow, ULCol, LRRow, LRCol, SEG Address)
DECLARE SUB MScrnRest (ULRow, ULCol, LRRow, LRCol, SEG Address)

'$INCLUDE: '\pro2\DEFCNF.BI'

SUB CSMsgBox (Message$, Wdth, Cnf AS Config) STATIC

    IF LEN(Message$) THEN
       Row = CSRLIN                             'Get the Row Position

       REDIM Temp$(23)                          'Make a temporary array to
                                                '  hold the parsed up lines
       MesLen = LEN(Message$)                   'Get the total length of the
                                                '  help message

       LN = 0                                   'Line number
       Strt = 1                                 'Starting parse position
       '*** Parse the message into lines
       DO
           WHILE MID$(Message$, Strt, 1) = " "  'Skip over blanks
              Strt = Strt + 1
           WEND
           ND = Strt + Wdth                     'Guess at the end of line
                                                'Loop backwards to find
           WHILE MID$(Message$, ND, 1) <> " " AND ND <= MesLen AND ND > Strt
               ND = ND - 1                      '  blank space
           WEND

           LN = LN + 1                          'Increment the Line number
                                                'Pull out the new line
           Temp$(LN) = MID$(Message$, Strt, ND - Strt)
           Strt = ND + 1                        'Reset starting posit. for
                                                '  next line
       LOOP UNTIL ND >= MesLen                  'Get more unless @ end of mes

       BotRow = Row + LN + 1                    'Find the bottom row #
       IF BotRow > 24 THEN BotRow = 24          'No farther than line 24

       ArraySize = 80 * (BotRow - Row + 2)      'Find the array size to use
       REDIM ScrBuf(ArraySize)                  '  for the background screen
       MScrnSave Row, 1, BotRow + 1, 80, ScrBuf(0)

       BoxWdth = Wdth + 4                       'Find the outer box width
       ColPos = 40 - (BoxWdth \ 2)              'Starting posit for centered
                                                '  box
       LOCATE Row, ColPos                       'Print the top of box
       CALL MQPrint("É" + STRING$(Wdth + 2, "Í") + "»", Cnf.MenBox)
       Box$ = "º" + SPACE$(Wdth + 2) + "º"      'Make the box sides

       FOR N = 1 TO LN                          'Print message lines
           LOCATE N + Row, ColPos
           CALL MQPrint(Box$, Cnf.MenBox)
           LOCATE , ColPos + 2
           CALL MQPrint(Temp$(N), Cnf.ActivCh)
       NEXT

       LOCATE N + Row, ColPos                   'Print the bottom of box
       CALL MQPrint("È" + STRING$(Wdth + 2, "Í") + "¼", Cnf.MenBox)

       CALL MPaintBox(Row + 1, ColPos + BoxWdth, N + Row, ColPos + BoxWdth + 1, 8)
       CALL MPaintBox(N + Row + 1, ColPos + 2, N + Row + 1, ColPos + BoxWdth + 1, 8)

       Pass = 1                                 'Set flag say we've been here
       ERASE Temp$                              'Don't need this anymore

    ELSEIF Pass = 1 THEN                        'If we've been here before,
                                                '  restore the screen
       MScrnRest Row, 1, BotRow + 1, 80, SEG ScrBuf(0)
       ERASE ScrBuf                             'Clean up memory
       Pass = 0                                 'Reset flag for next call
    END IF

END SUB

