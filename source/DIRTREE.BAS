'********* DIRTREE.BAS - returns an entire directory tree in a string array

'Copyright (c) 1990 Crescent Software
'written by Don Malin

DEFINT A-Z

TYPE Dirs
  DName AS STRING * 12
END TYPE

DECLARE FUNCTION DCount% (DirSpec$)
DECLARE FUNCTION NotInstr% (StPos%, Text$, Table$)

DECLARE SUB DirTree (Tree$(), FullPath$(), Ptr%)
DECLARE SUB InsertStr (BYVAL Address, Ins$, NumEls)
DECLARE SUB ReadDirT (Spec$, SEG Element AS Dirs)

CONST MaxDirs = 250                     'this sets the maximum levels

DIM Tree$(MaxDirs)
DIM FullPath$(MaxDirs)

Tree$(1) = "C:\"                        'you MUST seed the first element
Levels = 1                              'and the number of directory levels

DirTree Tree$(), FullPath$(), Levels    'DirTree returns the number of levels

FOR X = 1 TO Levels                     'print the directory tree
  PRINT Tree$(X); TAB(40); FullPath$(X)'show both arrays DirTree returns
  IF X MOD 23 = 0 THEN                  'if the screen is full
     LOCATE 25, 1                       'prompt for more on the bottom
     PRINT "Press a key to see more";   'and wait for a key press
     WHILE INKEY$ = "": WEND
     LOCATE CSRLIN - 1, 1               'nudge the cursor to where it was
  END IF
NEXT

SUB DirTree (Tree$(), FullPath$(), Ptr)
   
    STATIC Spec$, Pad$, Temp$, N, Last, Level, Segment
   
    IF LEN(Spec$) = 0 THEN              'if we haven't been here before
       Level = 1                        'do some initializing
       Last = MaxDirs
       Pad$ = SPACE$(63)
       Spec$ = SPACE$(65)
       N = 1
    ELSE
       N = INSTR(Spec$, "*")
       LSET Spec$ = LEFT$(Spec$, N - 1)
    END IF

    MID$(Spec$, N) = RTRIM$(MID$(Tree$(Ptr), NotInstr%(1, Tree$(Ptr), " ³ÃÀÄ")))
    N = INSTR(Spec$, " ")
    IF MID$(Spec$, N - 1, 1) <> "\" THEN
       MID$(Spec$, N) = "\*.*"
    ELSE
       MID$(Spec$, N) = "*.*"
    END IF

    PrevSpec$ = Spec$

    DirCnt = DCount%(RTRIM$(Spec$))

    IF DirCnt THEN
       REDIM DArray(1 TO DirCnt) AS Dirs
       ReadDirT RTRIM$(Spec$), DArray(1)

       Temp$ = LEFT$(Spec$, INSTR(Spec$, "*") - 1)

       FOR N = 1 TO DirCnt
          LSET Pad$ = ""
          FOR Temp = 0 TO Level - 2
             Temp2 = ASC(MID$(Tree$(Ptr + N - 1), Temp * 4 + 1, 1))
             IF Temp2 = 179 OR Temp2 = 195 THEN
                MID$(Pad$, Temp * 4 + 1) = "³"
             END IF
          NEXT

          IF N = DirCnt THEN
             MID$(Pad$, Temp * 4 + 1) = "ÀÄÄÄ"
          ELSE
             MID$(Pad$, Temp * 4 + 1) = "ÃÄÄÄ"
          END IF

          MID$(Pad$, Level * 4 + 1) = DArray(N).DName
          Ins$ = RTRIM$(Pad$)
          InsertStr VARPTR(Tree$(Ptr + N)), Ins$, Last - N - Ptr
          
          LSET Pad$ = Temp$ + DArray(N).DName
          Ins$ = RTRIM$(Pad$)
          InsertStr VARPTR(FullPath$(Ptr + N)), Ins$, Last - N - Ptr

       NEXT

       ERASE DArray
    
       Temp = Ptr
       DO
          Level = Level + 1
          LSET Spec$ = PrevSpec$
          Ptr = Ptr + 1
          Temp2 = Ptr
          DirTree Tree$(), FullPath$(), Ptr
          DirCnt = DirCnt + Ptr - Temp2
       LOOP UNTIL Ptr > DirCnt + Temp - 1

    END IF

    Level = Level - 1

    IF Level = 0 THEN                   'if this is the highest level, free
       Spec$ = ""                       'up the memory used by these strings
       PrevSpec$ = ""
       Pad$ = ""
    END IF

END SUB

