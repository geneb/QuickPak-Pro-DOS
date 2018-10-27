'********** WindoMgr.Bas - complete multi-level window manager

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z

DECLARE FUNCTION ArraySize% (ULRow, ULCol, LRRow, LRCol)
DECLARE SUB Box (ULRow, ULCol, LRRow, LRCol, BoxStyle, Colr, Page)
DECLARE SUB ClearScr (ULRow, ULCol, LRRow, LRCol, Colr, Page)

'DECLARE SUB ScrnSave (ULRow, ULCol, LRRow, LRCol, BYVAL Segment, BYVAL Address, Page)
'DECLARE SUB ScrnRest (ULRow, ULCol, LRRow, LRCol, BYVAL Segment, BYVAL Address, Page)
'
'These DECLARE statements are REM'd out because some of the other QuickPak
'Professional subprograms use ScrnSave and ScrnRest with the alternate SEG
'Element syntax.  Attempting to use both in the same program confuses the QB
'environment.  If you receive an "Argument count mismatch" error on ScrnSave
'or ScrnRest in another program, you will have to REM out the DECLARE
'statements there as well, and add the CALL keyword.  This is not a problem
'once programs have been compiled, because each module is truly separate.

'********** WindoMgr.Bas - "front end" to simplify accessing multiple windows
'
'Copyright (c) 1987 Ethan Winer
'
'WindowNumber% can range from 1 to 10, but 0 means open/close next/prior
'Action% is 1 to open a window, 0 to close it
'ULRow%, ULCol%, etc. define the window boundaries
'Colr% is the color for the box border, if the color is zero no box is drawn
'
'If any corner parameters are zero when closing, the original corners are
'used, so you don't have to keep specifying the same parameters each time.
'
'
SUB WindowMgr (WindowNumber%, Action%, ULRow%, ULCol%, LRRow%, LRCol%, Colr%) STATIC

STATIC CurWindow%                               'the last open window
STATIC Init%                                    'tells if we've been here yet
STATIC Table%()                                 'saves original corners

    IF Init% = 0 THEN                           'manager hasn't been used yet
       Init% = 1                                'now it has
       REDIM Table%(10, 4)                      'saves corner parameters
    END IF

    W% = WindowNumber%                                  'work with a copy
    IF Action% = 1 THEN CurWindow% = CurWindow% + 1     'open next window

    IF W% > CurWindow% THEN             'they went past the last active window
       CurWindow% = W%                  '  so make the current window last
    ELSEIF W% = 0 THEN                  'no window specified, so use
       W% = CurWindow%                  '  the next available window
    END IF
                                                        'in case they weren't
    IF CurWindow% < 1 OR CurWindow% > 10 THEN EXIT SUB  '  paying attention
      
    IF Action% = 1 THEN                         'opening a window

       'calculate the memory needed to save this portion of the screen
       Size% = ArraySize%(ULRow%, ULCol%, LRRow%, LRCol%)

       Table%(W%, 1) = ULRow%                   'save the corners so
       Table%(W%, 2) = ULCol%                   '  we can close the
       Table%(W%, 3) = LRRow%                   '  window later, even
       Table%(W%, 4) = LRCol%                   '  if the corners are
                                                '  omitted in the call
       IF W% = 1 THEN                           'make array to hold the screen
          REDIM A1%(Size%)
       ELSEIF W% = 2 THEN
          REDIM A2%(Size%)
       ELSEIF W% = 3 THEN
          REDIM A3%(Size%)
       ELSEIF W% = 4 THEN
          REDIM A4%(Size%)
       ELSEIF W% = 5 THEN
          REDIM A5%(Size%)
       ELSEIF W% = 6 THEN
          REDIM A6%(Size%)
       ELSEIF W% = 7 THEN
          REDIM A7%(Size%)
       ELSEIF W% = 8 THEN
          REDIM A8%(Size%)
       ELSEIF W% = 9 THEN
          REDIM A9%(Size%)
       ELSEIF W% = 10 THEN
          REDIM A10%(Size%)
       ELSE
          EXIT SUB
       END IF
    END IF
      
    IF W% = 1 THEN
       Segment% = VARSEG(A1%(0))
       Address% = VARPTR(A1%(0))
    ELSEIF W% = 2 THEN
       Segment% = VARSEG(A2%(0))
       Address% = VARPTR(A2%(0))
    ELSEIF W% = 3 THEN
       Segment% = VARSEG(A3%(0))
       Address% = VARPTR(A3%(0))
    ELSEIF W% = 4 THEN
       Segment% = VARSEG(A4%(0))
       Address% = VARPTR(A4%(0))
    ELSEIF W% = 5 THEN
       Segment% = VARSEG(A5%(0))
       Address% = VARPTR(A5%(0))
    ELSEIF W% = 6 THEN
       Segment% = VARSEG(A6%(0))
       Address% = VARPTR(A6%(0))
    ELSEIF W% = 7 THEN
       Segment% = VARSEG(A7%(0))
       Address% = VARPTR(A7%(0))
    ELSEIF W% = 8 THEN
       Segment% = VARSEG(A8%(0))
       Address% = VARPTR(A8%(0))
    ELSEIF W% = 9 THEN
       Segment% = VARSEG(A9%(0))
       Address% = VARPTR(A9%(0))
    ELSEIF W% = 10 THEN
       Segment% = VARSEG(A10%(0))
       Address% = VARPTR(A10%(0))
    END IF
      
    IF Action% = 1 THEN
       CALL ScrnSave(ULRow%, ULCol%, LRRow%, LRCol%, BYVAL Segment%, BYVAL Address%, -1)
       ClearScr ULRow%, ULCol%, LRRow%, LRCol%, Colr%, -1
       IF Colr% THEN Box ULRow%, ULCol%, LRRow%, LRCol%, 2, Colr%, -1
    ELSE   'change this 2 to a 1 for a single line box --^
       IF ULRow% = 0 OR ULCol% = 0 OR LRRow% = 0 OR LRCol% = 0 THEN
          CALL ScrnRest(Table%(W%, 1), Table%(W%, 2), Table%(W%, 3), Table%(W%, 4), BYVAL Segment%, BYVAL Address%, -1)
       ELSE
          CALL ScrnRest(ULRow%, ULCol%, LRRow%, LRCol%, BYVAL Segment%, BYVAL Address%, -1)
       END IF
    END IF
      
    IF Action% = 0 THEN

       IF W% = 1 THEN
          ERASE A1%
       ELSEIF W% = 2 THEN
          ERASE A2%
       ELSEIF W% = 3 THEN
          ERASE A3%
       ELSEIF W% = 4 THEN
          ERASE A4%
       ELSEIF W% = 5 THEN
          ERASE A5%
       ELSEIF W% = 6 THEN
          ERASE A6%
       ELSEIF W% = 7 THEN
          ERASE A7%
       ELSEIF W% = 8 THEN
          ERASE A8%
       ELSEIF W% = 9 THEN
          ERASE A9%
       ELSEIF W% = 10 THEN
          ERASE A10%
       END IF

       CurWindow% = CurWindow% - 1      'show the prior window as being
                                        '  the active one for next time
    END IF

END SUB

