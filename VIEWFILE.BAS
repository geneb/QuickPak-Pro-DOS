'********** ViewFile.Bas - View (browse) the contents of a file.
'Copyright (c) 1988 Don Malin & Crescent Software

'08-03-1990 Fixed search problem when file was smaller than the window.

DEFINT A-Z

'*** ASM routines used by ViewFile

DECLARE SUB APrint0 (BYVAL Address, NumEls, StartChar, NumChars, Colr)
DECLARE SUB Box0 (ULRow%, ULCol%, LRRow%, LRCol%, Char%, Colr%)
DECLARE SUB ClearScr0 (ULRow, ULCol, LRRow, LRCol, Colr)
DECLARE SUB Editor (Ed$, ALen%, ScanCode%, NumOnly%, CapsOn%, NormClr%, EditClr%, Row%, Column%)
DECLARE SUB FClose (Handle)
DECLARE SUB FOpen (FileName$, Handle)
DECLARE SUB FSeek (Handle, Offset&)
DECLARE SUB LowASCII (Text$)
DECLARE SUB MQPrint (Label$, Clr)
DECLARE SUB RemCtrl (Text$, Replace$)
DECLARE SUB MPaintBox (ULRow%, ULCol%, LRRow%, LRCol%, Colr%)
DECLARE SUB MScrnSave (ULRow, ULCol, LRRow, LRCol, SEG Address)
DECLARE SUB MScrnRest (ULRow, ULCol, LRRow, LRCol, SEG Address)
DECLARE SUB DeleteStr (BYVAL Address, NumEls)
DECLARE SUB InsertStr (BYVAL Address, Inserted$, NumEls)
DECLARE SUB SetError (ErrCode%)
DECLARE SUB SpecChars (Text$, HiBit)
DECLARE FUNCTION ArraySize% (ULRow, ULCol, LRRow, LRCol)
DECLARE FUNCTION DosError% ()
DECLARE FUNCTION ExpandTab$ (Text$, NumSpaces)
DECLARE FUNCTION FEof% (Handle)
DECLARE FUNCTION FLInput$ (Handle, Buffer$)
DECLARE FUNCTION FLof& (Handle)
DECLARE FUNCTION InCount% (LookIn$, Char$)
DECLARE FUNCTION MaxInt% (Var1%, Var2%)
DECLARE FUNCTION OneColor% (Bg, Fg)
DECLARE FUNCTION QPLen% (Work$)
DECLARE FUNCTION WhichError% ()

'----- Expand CHR$(9) TAB characters to the appropriate number of spaces
FUNCTION ExpandTab$ (X$, NumSpaces) STATIC

    Count = InCount(X$, CHR$(9))                'find number of Tab characters
    IF Count THEN                               'are there any?
                                                'make room for new string
       Work$ = SPACE$(QPLen%(X$) + 1 + (NumSpaces - 1) * Count)

       LSET Work$ = X$ + CHR$(0)                'put existing string in it
                                                '  and a char. 0 for later
       Where = 1                                'set search position to 1

       FOR X = 1 TO Count                       'do each tab
                                                'find the next Tab character
           Where = INSTR(Where, Work$, CHR$(9)) + 1

           Length = Where - 2                   'calc length of left part
                                                'calc spaces to next tab stop
           Sp = Length + NumSpaces - (Length MOD NumSpaces) - Length
                                                'insert the spaces
           IF Where > 1 THEN MID$(Work$, Where - 1) = SPACE$(Sp) + MID$(Work$, Where)
       NEXT                                     'assign the function looking
                                                '  for the char. 0
       ExpandTab$ = LEFT$(Work$, INSTR(Work$, CHR$(0)) - 1)
    ELSE                                        'no tabs, just assign the
       ExpandTab$ = X$                          '  function
    END IF

END FUNCTION

SUB SpecChars (Text$, HiBit) STATIC

    IF QPLen%(Text$) THEN
       Text$ = ExpandTab$(Text$, 8)
       IF HiBit THEN
          LowASCII Text$                'clear the hi-bit
          RemCtrl Text$, ""             'replace Ctrl characters with spaces
       END IF
    END IF

END SUB

'****************************************************************************
'  Title: ViewFile
'     by: Don Malin  5/04/88
'
'Purpose: Displays a files contents in a window which can be scrolled up,
'         down, left or right.  The underlying screen is saved on entry and
'         restored again on exit.
'
' Syntax: Call ViewFile(Arg1$, Arg2%, Arg3%, Arg4%, Arg5%, Arg6%)
'
' Inputs: Arg1$ - Name of the file to view conforming to DOS conventions
'         Arg2% - Number of file characters to display horizontally (<= 78)
'         Arg3% - Number of file lines (rows) to display vertically
'         Arg4% - Color attribute number for window - coded as for QPrint
'         Arg5% - Flag to strip hi-bit and Ctrl chars from WordStar type files
'         Arg6% - Action Flag:
'                 Action = 0 - save screen, browse file, clean up upon Escape
'                 Action = 1 - as above, but leave file open/set Action = 3
'                 Action = 3 - re-enter program from Action = 1 earlier
'                 Action = 5 - close file, restore underlying screen upon Esc.
'
'  Notes: The maximum number of lines that can be read is 16,384 which is
'         the size of the array used to keep track of line positions in the
'         file.  This program is intended for use with standard text files.
'****************************************************************************
SUB ViewFile (FileName$, NumChars, Rows, Clr, HiBit, Action) STATIC

    IF Action < 2 THEN
       IF MID$(FileName$, 2, 1) = ":" THEN      'See if there's a drive letter
          Drive$ = LEFT$(FileName$, 1)
       ELSE
          Drive$ = ""
       END IF
       
       MidFirst = 1                             'Start printing at Col 1
       OldBar = 0                               'Init scroll bar history buf
       OldVrtPtr = 0
       DoneWithTable = 0
      
       Buf$ = SPACE$(82)                        'assume 80 characters + CRLF
       REDIM Array$(Rows)                       'Display array for APrint

       MaxLines = 16383
       REDIM Ptrs&(1 TO MaxLines)               'Holds byte position pointers
                                                '  for each line of file

       ULRow = CSRLIN                           'Save current cursor line
       ULCol = POS(0)                           '  and column positions
       LOCATE , , 0                             'Turn cursor off

       CALL SplitColor(Clr, Fg, Bg)             'Split color into Fg & Bg
       InvClr = OneColor%(Bg, Fg)               'Calc inverse color number

       '----- Save the screen
                                                'Make array for screen contents
       REDIM ScrBuf(1 + ArraySize%(ULRow, ULCol, ULRow + Rows + 1, ULCol + NumChars + 1))
                                                'Save underlying screen
       MScrnSave ULRow, ULCol, ULRow + Rows + 1, ULCol + NumChars + 1, ScrBuf(1)

       '----- Print the window box
       ClearScr0 ULRow, ULCol, ULRow + Rows + 1, ULCol + NumChars + 1, Clr

       FileName$ = UCASE$(LTRIM$(RTRIM$(FileName$))) 'Trim and Cap file name
       Top$ = "É" + STRING$(NumChars, "Í") + "»"   'Make top line of window
       IF QPLen%(Top$) > QPLen%(FileName$) + 6 THEN
          MID$(Top$, (QPLen%(Top$) - QPLen%(FileName$) - 4) \ 2) = "[ " + FileName$ + " ]"
       END IF
       IF LEN(Top$) > LEN(FileName$) + 17 THEN
          MID$(Top$, 3) = "[F3-Search]"
       END IF

    END IF

    IF Action = 5 THEN
                                                'Restore the screen
       MScrnRest ULRow, ULCol, ULRow + Rows + 1, ULCol + NumChars + 1, ScrBuf(1)
       ERASE Ptrs&, Array$, ScrBuf              'Clean up memory
       Top$ = "": Inserted$ = ""
       FClose Handle                            'Close the file
       EXIT SUB                                 'Bail out
    END IF
               
    IF Action < 3 THEN
       MQPrint Top$, Clr                        'Print the top line
       FOR N = 1 TO Rows                        'Print the window sides
           LOCATE N + ULRow, ULCol: MQPrint "º", Clr
           LOCATE , ULCol + NumChars + 1
           IF Rows > 2 THEN
              IF N = 1 THEN                     'If there is enough room for
                 MQPrint CHR$(24), InvClr       '  a scroll bar, print one on
              ELSEIF N = Rows THEN              '  the right side of window
                 MQPrint CHR$(25), InvClr
              ELSEIF N = 2 THEN
                 MQPrint CHR$(4), InvClr
              ELSE
                 MQPrint CHR$(177), InvClr
              END IF
           ELSE                                 'Window too small for scroll
              MQPrint "º", Clr                  '  bar, print double line
           END IF
       NEXT

       BotRow = N + ULRow                       'Save the bottom row #
       LOCATE BotRow, ULCol                     'Print horizontal scroll bar
       MQPrint "È" + CHR$(27) + CHR$(4) + STRING$(NumChars - 3, CHR$(177)) + CHR$(26) + "¼", Clr
       CALL PaintBox0(BotRow, ULCol + 1, BotRow, ULCol + NumChars, InvClr)

       OClr = Clr
    END IF

    IF Action < 2 THEN
       '----- Open the file
       FOpen FileName$, Handle                  'Open file for QP Binary
       IF DosError% THEN EXIT SUB               'exit if error

       MaxLen = 0                               'Keeps record of longest line
       Count = 1                                'Pointer into the byte pointer
                                                '  array
       Ptrs&(Count) = 1                         'Init first element of array

       '----- Read the first screen of data
       DO UNTIL DosError% OR Count > Rows       'Read a screen full of file
          LToDo = Count                         'specify the line to read
          GOSUB GetLine                         'and go get a line
                                                'Save the byte count for line
          Ptrs&(Count + 1) = Ptrs&(Count) + QPLen%(Array$(Count)) + 2
          SpecChars Array$(Count), HiBit
                                                'See if its longer than MaxLen
          IF QPLen%(Array$(Count)) > MaxLen THEN MaxLen = QPLen%(Array$(Count))
          Count = Count + 1
       LOOP
       LastLine = Count

       FLen& = FLof&(Handle)                    'Save the length of the file
    END IF

    IF Action THEN Action = 3
       
    '----- Main processing loop
    DO
        LOCATE ULRow + 1, ULCol + 1             'Print the display array
        APrint0 VARPTR(Array$(1)), Rows, MidFirst, NumChars, Clr

        Clr = OClr

        DO                                      'Wait for keyboard input
            IF NOT DoneWithTable THEN
               GOSUB ReadPointer
            END IF

            X$ = INKEY$
        LOOP WHILE QPLen%(X$) < 2 AND X$ <> CHR$(27)
                                                
        SELECT CASE ASC(RIGHT$(X$, 1))              'Process keys
                                                
           '----- Down arrow key
           CASE 80                                  'If not at end of file
              IF NOT FEof%(Handle) AND Count < MaxLines THEN
                 DeleteStr VARPTR(Array$(1)), Rows - 1 'Shift array up
                 FSeek Handle, Ptrs&(Count) - 1     'Seek to beginning of
                                                    '  next line
                 LastLine = MaxInt(LastLine, Count)
                 LToDo = Rows
                 GOSUB GetLine
                                                    'Save pointer into file
                 Ptrs&(Count + 1) = Ptrs&(Count) + QPLen%(Array$(Rows)) + 2
                 SpecChars Array$(Rows), HiBit
                                                    'Compare length to MaxLen
                 IF QPLen%(Array$(Rows)) > MaxLen THEN MaxLen = QPLen%(Array$(Rows))
                 Count = Count + 1
              END IF

           '----- Page Down key
           CASE 81
              IF NOT FEof%(Handle) THEN         'If not already at end of file
                 GOSUB DoPage
              END IF

           '----- Up arrow key
           CASE 72
              IF Count - Rows > 1 THEN          'If not already at top, back
                 Count = Count - 1              '  up pointer to previous line
                 FSeek Handle, Ptrs&(Count - Rows) - 1'Seek to previous line
                 Inserted$ = FLInput$(Handle, Buf$)
                 WHILE WhichError% = 83
                    IF FRE("") < 2048 THEN
                       SetError (14)
                       EXIT SUB
                    END IF
                    Inserted$ = Inserted$ + FLInput$(Handle, Buf$)
                 WEND

                 SpecChars Inserted$, HiBit
                                                   'Compare length to MaxLen
                 IF QPLen%(Inserted$) > MaxLen THEN MaxLen = QPLen%(Inserted$)
                                                'Insert line into display array
                 InsertStr VARPTR(Array$(1)), Inserted$, Rows - 1
              END IF
                                            
           '----- Page Up key
           CASE 73
              Count = Count - Rows              'Back up counter a page
              IF Count - Rows < 1 THEN Count = Rows + 1 'Check for past line 1
              FSeek Handle, Ptrs&(Count - Rows) - 1 'Seek to start of page
              FOR N = 1 TO Rows                     'Read a screen full
                  IF FEof%(Handle) THEN EXIT FOR
                  LToDo = N
                  GOSUB GetLine
                  SpecChars Array$(N), HiBit
                  IF QPLen%(Array$(N)) > MaxLen THEN MaxLen = QPLen%(Array$(N))
              NEXT

           '----- Left arrow
           CASE 75
              IF MidFirst > 1 THEN              'If not at first column,
                 MidFirst = MidFirst - 1        '  back up column pointer
              END IF

           '----- Right Arrow
           CASE 77
              IF MidFirst <= MaxLen THEN        'If not at end of longest
                 MidFirst = MidFirst + 1        '  line, increment column
              END IF

           '----- Home key
           CASE 71
              Count = Rows + 1                  'Backup cntr to end of window
              FSeek Handle, Ptrs&(Count - Rows) - 1 'Seek to first line
              FOR N = 1 TO Rows                     'Read a screen full
                  IF FEof%(Handle) THEN EXIT FOR
                  LToDo = N
                  GOSUB GetLine
                  SpecChars Array$(N), HiBit
              NEXT
              MidFirst = 1                      'Set column position to 1

           '----- End Key
           CASE 79
              DO WHILE NOT DoneWithTable
                 GOSUB ReadPointer
              LOOP

              Count = MaxInt(LastLine - Rows, 1)  'backup and re-read so
              FOR N = 1 TO Rows                   '  screen ends on last line
                  FSeek Handle, Ptrs&(Count) - 1
                  LToDo = N
                  GOSUB GetLine
                  SpecChars Array$(N), HiBit
                  Count = Count + 1
              NEXT

           '----- Ctrl-left key
           CASE 115
              MidFirst = 1

           '----- F3 Search for text
           CASE 61
              REDIM F3Scr(7 * 80)
              MScrnSave 4, 1, 9, 80, F3Scr(1)
              ClearScr0 4, 10, 8, 70, 112
              Box0 4, 10, 8, 70, 2, 112
              MPaintBox 5, 71, 8, 72, 8
              MPaintBox 9, 12, 9, 72, 8
              Box0 5, 31, 7, 69, 1, 112
              LOCATE 6, 11
              MQPrint " Enter Search Text: ", 112
              Answer$ = SPACE$(37)
              LSET Answer$ = Srch$
                                                'Call Edit Routine
              DO
                 Editor Answer$, ALen, ExitCode%, 0, 0, 112, 112, 6, 32
              LOOP UNTIL ExitCode = 13 OR ExitCode = 27
              MScrnRest 4, 1, 9, 80, F3Scr(1)
              ERASE F3Scr

              IF ExitCode = 13 AND ALen THEN

                 IF LEFT$(Answer$, ALen) <> Srch$ OR OldCount <> Count THEN
                    Srch$ = UCASE$(LEFT$(Answer$, ALen))
                    SCount = MaxInt(Count - Rows, 1)
                    Found = 0
                    Pass = 0
                    Inst = 0
                 END IF
                 Answer$ = ""

                 Origin = SCount

                 DO
                    IF Inst = 0 THEN
                       IF DoneWithTable OR SCount < LastLine THEN
                          FSeek Handle, Ptrs&(SCount) - 1
                          Work$ = FLInput$(Handle, Buf$)
                          WHILE WhichError% = 83
                             IF FRE("") < 2048 THEN
                                SetError 14
                                EXIT SUB
                             END IF
                             Work$ = Work$ + FLInput$(Handle, Buf$)  'get more
                          WEND
                       ELSE
                          GOSUB ReadPointer
                          Work$ = Temp$
                       END IF
                    END IF

                    Work$ = UCASE$(Work$)
                    SpecChars Work$, HiBit

                    Inst = INSTR(Inst + 1, Work$, Srch$)

                    IF Inst = 0 THEN
                       SCount = SCount + 1
                       IF DoneWithTable AND SCount > LastLine THEN
                          Pass = 1
                          SCount = 1
                       END IF
                    END IF
                 LOOP UNTIL (Pass = 1 AND SCount > Origin AND Found = 0) OR Inst

                 IF Inst THEN
                    Found = Inst <> 0

                    IF SCount > Count - 1 OR SCount < Count - Rows THEN
                       IF FEof(Handle) THEN
                          Count = SCount + 1
                       ELSE
                          Count = SCount - 1
                          IF Count < 1 THEN Count = 1
                       END IF

                       GOSUB DoPage
                    END IF
                   
                    IF Count < Rows THEN
                       RW = SCount
                    ELSE
                       RW = Rows - (Count - SCount - 1)
                    END IF
                    IF Inst <= MidFirst THEN MidFirst = 1
                    Col = Inst - MidFirst + 1

                    IF Col > NumChars - LEN(Srch$) THEN
                       MidFirst = Col - (NumChars \ 2)
                       Col = Col - MidFirst + 1
                    END IF

                    LOCATE ULRow + 1, ULCol + 1
                    APrint0 VARPTR(Array$(1)), Rows, MidFirst, NumChars, Clr

                    Clr = -1
                
                    MPaintBox RW + ULRow, Col + ULCol, RW + ULRow, Col + ULCol + LEN(Srch$) - 1, 112
                    OldCount = Count
                 ELSE
                    REDIM F3Scr(5 * 80)
                    MScrnSave 4, 1, 7, 80, F3Scr(1)
                    ClearScr0 4, 30, 6, 49, 112
                    Box0 4, 30, 6, 49, 2, 112
                    LOCATE 5, 32
                    MQPrint "Match not found!", 112
                    MPaintBox 5, 50, 6, 51, 8
                    MPaintBox 7, 32, 7, 51, 8
                    K$ = INPUT$(1)
                    MScrnRest 4, 1, 7, 80, F3Scr(1)
                    ERASE F3Scr
                 END IF
              END IF

           CASE ELSE
        END SELECT
        GOSUB ScrlBar                           'Update the scroll bars

    LOOP UNTIL X$ = CHR$(27)                    'Go back for more unless Esc
                                                '  pressed

    IF Action = 0 THEN
                                                'Restore the screen
       MScrnRest ULRow, ULCol, ULRow + Rows + 1, ULCol + NumChars + 1, ScrBuf(1)
       ERASE Ptrs&, Array$, ScrBuf              'Clean up memory
       Top$ = "": Inserted$ = "": Buf$ = ""
       FClose Handle                            'Close the file
    END IF

    EXIT SUB                                    'Bail out



ScrlBar: '----- Update the scroll bars
    IF MidFirst <> OldMid THEN                  'If column position changed
       IF MidFirst < MaxLen THEN                '  and not off right edge
                                                'Calc. Horizontal position %
          HorPtr = MidFirst * (NumChars - 2) \ MaxLen

          LOCATE BotRow, ULCol + OldHorPtr + 2  'Erase old pointer
          MQPrint CHR$(177), InvClr
          LOCATE , ULCol + HorPtr + 2           'Print the new pointer
          MQPrint CHR$(4), InvClr
          OldHorPtr = HorPtr                    'Save pointer for next pass
       END IF
       OldMid = MidFirst                        'Save column position for next
    END IF
                                               
    IF Count > Rows THEN                        'Calc the Vertical position %
       VrtPtr = (Count - Rows) * (Rows - 2&) \ LastLine

       IF VrtPtr <> OldVrtPtr AND DoneWithTable THEN 'If pointer has changed,
                                                '  Erase old pointer
          LOCATE ULRow + OldVrtPtr + 2, ULCol + NumChars + 1
          MQPrint CHR$(177), InvClr
          LOCATE ULRow + VrtPtr + 2             'Print the new pointer
          MQPrint CHR$(4), InvClr
          OldVrtPtr = VrtPtr                    'Save old pointer for later
       END IF
    END IF
RETURN

GetLine:
    Array$(LToDo) = ""
    DO
        IF FRE("") < 2048 THEN
           SetError (14)
           EXIT SUB
        END IF
        Array$(LToDo) = Array$(LToDo) + FLInput$(Handle, Buf$)  'get more
    LOOP WHILE WhichError% = 83
    LastLine = MaxInt(LastLine, LToDo)
RETURN

             
ReadPointer:
    IF NOT FEof%(Handle) AND LastLine < MaxLines THEN
       FSeek Handle, Ptrs&(LastLine) - 1
       Temp$ = ""
       DO
           IF FRE("") < 2048 THEN
              SetError (14)
              EXIT SUB
           END IF
           Temp$ = Temp$ + FLInput$(Handle, Buf$)  'get more
       LOOP WHILE WhichError% = 83                 'if "Buffer too small" error
      
       Ptrs&(LastLine + 1) = Ptrs&(LastLine) + QPLen%(Temp$) + 2
                                                'Compare length to MaxLen
       SpecChars Temp$, HiBit
       IF QPLen%(Temp$) > MaxLen THEN MaxLen = QPLen%(Temp$)
       LastLine = LastLine + 1

    ELSE
       DoneWithTable = -1
       FSeek Handle, Ptrs&(Count)
    END IF
RETURN


DoPage:
    FOR N = 1 TO Rows              '  Read the next page
                                                'Check for end of file
        IF NOT FEof%(Handle) AND Count < MaxLines THEN
           FSeek Handle, Ptrs&(Count) - 1 'Seek to next line
           LToDo = N
           GOSUB GetLine           'Read a line
                                                'Save pointers into file
           Ptrs&(Count + 1) = Ptrs&(Count) + QPLen%(Array$(N)) + 2
           SpecChars Array$(N), HiBit
                                                'Compare length to MaxLen
           IF QPLen%(Array$(N)) > MaxLen THEN MaxLen = QPLen%(Array$(N))
           Count = Count + 1
        END IF
    NEXT

    IF FEof%(Handle) OR Count >= MaxLines THEN  'If we reached end of file,
       Count = Count - Rows        '  backup and re-read so
       FOR N = 1 TO Rows           '  screen ends on last line
           FSeek Handle, Ptrs&(Count) - 1
           LToDo = N
           GOSUB GetLine
           Ptrs&(Count + 1) = Ptrs&(Count) + QPLen%(Array$(N)) + 2
           SpecChars Array$(N), HiBit
           Count = Count + 1
       NEXT
    END IF
RETURN


     
END SUB
