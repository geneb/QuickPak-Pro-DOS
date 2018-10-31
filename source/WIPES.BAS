'********* Wipes.Bas - demonstrates various text screen wipes and fades

'by Don Malin
'Copyright (c) 1988 Crescent Software


DEFINT A-Z

'----- BASIC subprograms
DECLARE SUB CloseCurtain (Orig(), El)
DECLARE SUB Dissolve (Scr(), El)
DECLARE SUB Dissolve2 (UlRow%, UlCol%, LrRow%, LrCol%, Scr%(), El%)
DECLARE SUB ExplodBox (UlRow, UlCol, LrRow, LrCol, Scr(), El)
DECLARE SUB HorBlinds (Scr(), El)
DECLARE SUB OpenCurtain (Orig(), OE, NewScr(), NE)
DECLARE SUB PauseKey (Scr())
DECLARE SUB PushDown (Scr(), El)
DECLARE SUB PushL2R (Scr(), El)
DECLARE SUB PushR2L (Scr(), El)
DECLARE SUB PushUp (Scr(), El)
DECLARE SUB Puzzle (Scr(), El)
DECLARE SUB Radar (Scr(), El)
DECLARE SUB RoleAway (Orig%(), OE%, NewScr%(), NE%)
DECLARE SUB VertBlinds (Scr(), El)
DECLARE SUB WindowClean (Scr(), El)
DECLARE SUB WipeL2R (Scr(), El)

'----- Assembler subroutines
DECLARE SUB MakeMono (SEG Element, NumEls)
DECLARE SUB MPRestore (UlRow, UlCol, LrRow, LrCol, OrigWidth, SEG ArrayEl)
DECLARE SUB MQPrint (Text$, Clr)
DECLARE SUB MScrnSave (ULR, ULC, LRR, LRC, SEG Adderss)
DECLARE SUB Pause (Ticks)
DECLARE SUB Pause3 (MSeconds, Fudge&)
DECLARE SUB ScrollD (UlRow, UlCol, BrRow, BrCol, NLines, Page)
DECLARE SUB ScrollL (UlRow, UlCol, BrRow, BrCol, NLines, Page)
DECLARE SUB ScrollR (UlRow, UlCol, BrRow, BrCol, NLines, Page)
DECLARE SUB ScrollU (UlRow, UlCol, BrRow, BrCol, NLines, Page)

'----- Assembler functions
DECLARE FUNCTION FudgeFactor& ()
DECLARE FUNCTION MaxInt (Var1, Var2)
DECLARE FUNCTION MinInt (Var1, Var2)
DECLARE FUNCTION Peek1% (Segment, Address)
DECLARE FUNCTION TrapInt% (Value%, LoLimit%, HiLimit%)

DIM SHARED Fudge&                       'so all the subprograms can use it



'---- If you add these subprograms to your main program, remove the following:

REDIM Dos(2000)
MScrnSave 1, 1, 25, 80, Dos(0)

REDIM Sc1(2000)
DEF SEG = VARSEG(Sc1(0))
BLOAD "CSDEMO.SCR", VARPTR(Sc1(0))      'Load the File into a Buffer

REDIM Sc2(2000)
DEF SEG = VARSEG(Sc2(0))
BLOAD "ABOUT.SCR", VARPTR(Sc2(0))       'Load the File into a Buffer

IF Peek1%(0, &H463) = &HB4 THEN         'if we're running on a mono monitor
   MakeMono Sc1(0), 2000                'strip the screen colors
   MakeMono Sc2(0), 2000
END IF

DO

   Curt$ = SPACE$(80)
   FOR N = 1 TO 76 STEP 5
       MID$(Curt$, N) = "°±²±°"
   NEXT
   FOR Row = 1 TO 25
       LOCATE Row, 1
       MQPrint Curt$, 7
       Pause 1
   NEXT
   REDIM Curt(2000)
   MScrnSave 1, 1, 25, 80, Curt(0)

   Pause 3

   OpenCurtain Curt(), 0, Sc1(), 0
   PauseKey Dos()

   ExplodBox 1, 1, 25, 80, Sc2(), 0
   PauseKey Dos()

   PushL2R Sc1(), 0
   PauseKey Dos()

   Dissolve Sc2(), 0
   'Dissolve2 1, 1, 25, 80, Sc2(), 0
   PauseKey Dos()

   RoleAway Sc2(), 0, Sc1(), 0
   PauseKey Dos()

   Radar Sc2(), 0
   PauseKey Dos()

   PushR2L Sc1(), 0
   PauseKey Dos()

   VertBlinds Sc2(), 0
   PauseKey Dos()

   PushUp Sc1(), 0
   PauseKey Dos()

   WindowClean Sc2(), 0
   PauseKey Dos()

   WipeL2R Sc1(), 0
   PauseKey Dos()

   HorBlinds Sc2(), 0
   PauseKey Dos()

   Puzzle Sc1(), 0
   PauseKey Dos()

   CloseCurtain Curt(), 0
   Pause 3
   OpenCurtain Curt(), 0, Dos(), 0

LOOP WHILE INKEY$ = ""

'---- If you add these subprograms to your main program remove the above code.

SUB CloseCurtain (Orig(), El) STATIC

    IF Fudge& = 0 THEN Fudge& = FudgeFactor&    'do this once only

    FOR L = 1 TO 39
        MPRestore 1, 1, 25, L, 80, Orig(40 - L + El)
        R = 81 - L
        MPRestore 1, R, 25, 80, 80, Orig(40 + El)
        Pause3 L, Fudge&
    NEXT

    MPRestore 1, 1, 25, 80, 80, Orig(El)

END SUB

SUB Dissolve (Scr(), El) STATIC

    LastLine = UBOUND(Scr) \ 80

    FOR CO = 3 TO 0 STEP -1
        FOR Row = 1 TO LastLine STEP 4
            FOR RO = 3 TO 0 STEP -1
                R = Row + RO
                IF R <= LastLine THEN
                   FOR Col = 1 TO 77 STEP 4
                       C = Col + CO + RO
                       IF C > 80 THEN C = C - 80
                       MPRestore R, C, R, C, 80, Scr((R - 1) * 80 + C - 1 + El)
                   NEXT
                END IF
            NEXT
        NEXT
    NEXT

END SUB

SUB Dissolve2 (UlRow, UlCol, LrRow, LrCol, Scr(), El) STATIC

    LineSize = LrCol - UlCol + 1
    NumEls = LineSize * (LrRow - UlRow + 1)
    First = 1
    REDIM ScrBuf(1 TO NumEls)
    CALL InitInt(SEG ScrBuf(First), 1, NumEls)
    RANDOMIZE TIMER

    FOR N = NumEls TO 1 STEP -1
       Element = INT(RND * N) + First
       R = ScrBuf(Element) \ LineSize + UlRow
       C = ScrBuf(Element) MOD LineSize + UlCol - 1
       IF C < UlCol THEN R = R - 1: C = LrCol
       MPRestore R, C, R, C, 80, Scr((R - 1) * 80 + C - 1 + El)
       SWAP ScrBuf(First), ScrBuf(Element)
       First = First + 1
    NEXT

END SUB

SUB ExplodBox (UlRow, UlCol, BrRow, BrCol, Scr(), El) STATIC

    IF Fudge& = 0 THEN Fudge& = FudgeFactor&

    MidRow = (UlRow + BrRow) \ 2
    MidCol = (UlCol + BrCol) \ 2

    MSec = MinInt(90 \ MidRow, 360 \ MidCol)

    FOR Col = MidCol TO UlCol STEP -2
        Row = MaxInt((MidRow * Col) \ MidCol, 1)

        BRow = Row + (MidRow - Row) * 2
        BCol = Col + (MidCol - Col) * 2

        MPRestore Row, Col, BRow, BCol, 80, Scr((Row - 1) * 80 + Col - 1 + El)
        Pause3 MSec, Fudge&
    NEXT

    MPRestore UlRow, UlCol, BrRow, BrCol, 80, Scr((UlRow - 1) * 80 + UlCol - 1 + El)

END SUB

SUB HorBlinds (Scr(), El) STATIC

    FOR N = 0 TO 4
        FOR Row = 1 TO 21 STEP 5
            MPRestore Row, 1, Row + N, 80, 80, Scr((Row - 1) * 80 + El)
        NEXT
        Pause 2
    NEXT

END SUB

SUB OpenCurtain (Orig(), OE, NewScr(), NE) STATIC

    IF Fudge& = 0 THEN Fudge& = FudgeFactor&    'do this once only
    LastLine = UBOUND(Orig) \ 80

    FOR L = 40 TO 2 STEP -1
        Pause3 L, Fudge&
        MPRestore 1, 1, LastLine, L - 1, 80, Orig(41 - L + OE)
        R = 81 - L
        MPRestore 1, R + 1, LastLine, 80, 80, Orig(40 + OE)
        MPRestore 1, L, LastLine, R, 80, NewScr(L - 1 + NE)
    NEXT

    MPRestore 1, 1, LastLine, 80, 80, NewScr(NE)

END SUB

SUB PauseKey (Scr()) STATIC

    T! = TIMER + 1
    DO
       IF LEN(INKEY$) THEN
          CloseCurtain Scr(), 0
          END
       END IF
    LOOP UNTIL TIMER > T!

END SUB

SUB PushDown (Scr(), El) STATIC

    LastLine = UBOUND(Scr) \ 80

    FOR Row = 1 TO LastLine - 1
        ScrollD Row, 1, LastLine, 80, 1, 0
        MPRestore 1, 1, Row, 80, 80, Scr((LastLine - Row) * 80 + El)
        Pause 1
    NEXT

    MPRestore 1, 1, Row, 80, 80, Scr((LastLine - Row) * 80 + El)

END SUB

SUB PushL2R (Scr(), El) STATIC

    LastLine = UBOUND(Scr) \ 80

    FOR Col = 2 TO 80 STEP 2
        ScrollR 1, Col - 1, LastLine, 80, 1, 0
        MPRestore 1, 1, LastLine, Col, 80, Scr(81 - Col - 1 + El)
    NEXT

END SUB

SUB PushR2L (Scr(), El) STATIC

    LastLine = UBOUND(Scr) \ 80

    FOR Col = 77 TO 1 STEP -2
        ScrollL 1, 1, LastLine, Col + 2, 1, 0
        MPRestore 1, Col, LastLine, 80, 80, Scr(El)
    NEXT
 
END SUB

SUB PushUp (Scr(), El) STATIC

    LastLine = UBOUND(Scr) \ 80

    FOR Row = LastLine TO 2 STEP -1
        ScrollU 1, 1, Row, 80, 1, 0
        MPRestore Row, 1, LastLine, 80, 80, Scr(El)
        Pause 1
    NEXT

    MPRestore Row, 1, LastLine, 80, 80, Scr(El)

END SUB

SUB Puzzle (Scr(), El) STATIC

    RANDOMIZE TIMER
    REDIM ScrBuf(2001)

    PRows = 5
    PCols = 10
    Rows = 25 \ PRows
    Cols = 80 \ PCols

    Size = PRows * PCols
    Pieces = (2000 \ Size)
    REDIM Table(Pieces)

    FOR N = 1 TO Pieces

        DO
            Piece = INT(Pieces * RND + 1)

            IF NOT Table(Piece) THEN
               Table(Piece) = -1
               Row = ((Piece - 1) \ Cols) * PRows + 1
               Col = ((Piece - 1) MOD Cols) * PCols + 1

               GOSUB MovePiece
               '*****  Replace the GOSUB with the following line to eliminate
               '***** the shooting boxes.
               'MPRestore Row, Col, Row + PRows - 1, Col + PCols - 1, 80, Scr((Row - 1) * 80 + Col - 1 + El)

               EXIT DO
            END IF
        LOOP
    NEXT

    ERASE ScrBuf
    EXIT SUB


'----- Used for shooting boxes
MovePiece:

    MScrnSave 1, 1, 25, 80, ScrBuf(1)

    DR = 25 - Row
    DC = 80 - Col
    RO = 0
    CO = RO

    Rad = SQR(DC ^ 2 + DR ^ 2)
    Slope! = DC / DR
    Ang! = ATN(Slope!)

    FOR M = Rad TO 0 STEP -3

        R = M * COS(Ang!) + Row
        C = M * SIN(Ang!) + Col

        R2 = MinInt(25, R + PRows - 1)
        C2 = MinInt(80, C + PCols - 1)

        MPRestore R, C, R2, C2, 80, Scr((Row - 1) * 80 + Col - 1 + El)

        IF RO > R2 THEN MPRestore R2 + 1, C, RO, CO, 80, ScrBuf((R2) * 80 + C)
        IF CO > C2 THEN MPRestore R, C2 + 1, RO, CO, 80, ScrBuf((R - 1) * 80 + C2 + 1)

        RO = R2
        CO = C2

    NEXT

    R2 = Row + PRows - 1
    C2 = Col + PCols - 1

    MPRestore Row, Col, R2, C2, 80, Scr((Row - 1) * 80 + Col - 1 + El)

    IF RO > R2 THEN MPRestore R2 + 1, Col, RO, CO, 80, ScrBuf((R2) * 80 + Col)
    IF CO > C2 THEN MPRestore Row, C2 + 1, RO, CO, 80, ScrBuf((Row - 1) * 80 + C2 + 1)

RETURN

END SUB

SUB Radar (Scr(), El) STATIC

    E = -1 + El

    FOR Col = 40 TO 80 STEP 8
        Slope! = (Col - 40) / 12
        FOR Row = 1 TO 12
            SCol = INT((13 - Row) * Slope!) + 40
            MPRestore Row, 40, Row, SCol, 80, Scr((Row - 1) * 80 + 40 + E)
        NEXT
    NEXT

    FOR Row = 2 TO 12 STEP 1
        Slope! = 40 / (13 - Row)
        FOR R = Row TO 12
            SCol = INT((13 - R) * Slope!) + 40
            IF SCol > 80 THEN SCol = 80
            MPRestore 1, 40, R, SCol, 80, Scr(40 + E)'Scr((R - 1) * 80 + 40+E)
        NEXT
    NEXT

    FOR Row = 13 TO 25 STEP 1
        Slope! = 40 / (Row - 12)
        FOR R = 13 TO Row
            SCol = INT((R - 12) * Slope!) + 40
            IF SCol > 80 THEN SCol = 80
            MPRestore R, SCol, R, 80, 80, Scr(((R - 1) * 80) + SCol + E)
        NEXT
    NEXT

    FOR Col = 73 TO 1 STEP -8
        Slope! = (Col - 39) / 13
        FOR Row = 13 TO 25
            SCol = INT((Row - 12) * Slope!) + 39
            MPRestore Row, SCol, Row, 80, 80, Scr((Row - 1) * 80 + SCol + E)
        NEXT
    NEXT

    FOR Row = 24 TO 13 STEP -1
        Slope! = 39 / (Row - 12)
        FOR R = 13 TO Row
            SCol = 39 - INT((R - 12) * Slope!)
            IF SCol < 1 THEN SCol = 1
            MPRestore R, SCol, R, 39, 80, Scr((R - 1) * 80 + SCol + E)
        NEXT
    NEXT

    FOR Row = 12 TO 1 STEP -1
        Slope! = 39 / (Row - 13)
        FOR R = 12 TO Row STEP -1
            SCol = 39 - INT((R - 13) * Slope!)
            IF SCol < 1 THEN SCol = 1
            MPRestore R, 1, R, SCol, 80, Scr((R - 1) * 80 + 1 + E)
        NEXT
    NEXT

    FOR Col = 8 TO 40 STEP 8
        Slope! = (39 - Col) / 12
        FOR Row = 1 TO 12
            SCol = 39 - INT((13 - Row) * Slope!)
            MPRestore Row, 1, Row, SCol, 80, Scr((Row - 1) * 80 + 1 + E)
        NEXT
    NEXT

END SUB

SUB RoleAway (Orig(), OE, NewScr(), NE) STATIC

    IF Fudge& = 0 THEN Fudge& = FudgeFactor&

    FOR C = 79 TO 1 STEP -1
        Wide = TrapInt%(80 - C + 1, 1, 10)
        MPRestore 1, C, 25, C, 80, Orig(C + OE)

        Pause3 9, Fudge&

        IF C > 2 THEN ScrollL 1, MaxInt(1, C - Wide), 25, C, 2, 0
        MPRestore 1, C, 25, C + 1, 80, NewScr(C - 1 + NE)
    NEXT

END SUB

SUB VertBlinds (Scr(), El) STATIC

    LastLine = UBOUND(Scr) \ 80

    FOR N = 0 TO 9
        FOR Col = 1 TO 71 STEP 10
            MPRestore 1, Col, LastLine, Col + N, 80, Scr(Col - 1 + El)
        NEXT
        Pause 1
    NEXT

END SUB

SUB WindowClean (Scr(), El) STATIC

    Da = 21
    LRad = 3
    DO

        FOR Ad = 0 TO 360 STEP Da

            Theta! = Ad * (3.14156 / 180)

            Rad = (11 / 360) * Ad + LRad
            RadRow = Rad * .3125

            Row = RadRow * COS(Theta!) + 10
            Col = Rad * SIN(Theta!) + 39

            Row2 = Row + 4
            Col2 = Col + 10

            Row = MinInt(MaxInt(Row, 1), 25)
            Col = MinInt(MaxInt(Col, 1), 80)
            Row2 = MinInt(MaxInt(Row2, 1), 25)
            Col2 = MinInt(MaxInt(Col2, 1), 80)

            MPRestore Row, Col, Row2, Col2, 80, Scr((Row - 1) * 80 + Col - 1 + El)

        NEXT

        LRad = Rad
        Da = Da - 4

    LOOP UNTIL Rad >= 50

END SUB

SUB WipeL2R (Scr(), El) STATIC

    IF Fudge& = 0 THEN Fudge& = FudgeFactor&    'do this once only
    LastLine = UBOUND(Scr) \ 80

    FOR Col = 2 TO 80 STEP 2
        MPRestore 1, 1, LastLine, Col, 80, Scr(80 - Col + El)
        Pause3 10, Fudge&
    NEXT

END SUB

