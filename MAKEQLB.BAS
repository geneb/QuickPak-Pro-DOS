'ÚÄÄÄÄÄÄÄÄÄ´ MAKEQLB.BAS - .QLB maker utility for BASIC programs ÃÄÄÄÄÄÄÄÄÄÄÄ¿
'³                                                                           ³
'³Copyright (c) 1988 - 1990 Crescent Software                                ³
'³by Don Malin and Chris May with user input enhancements by Ken White       ³
'³support for VB/DOS added 2-16-93 by Bob Simmons                            ³
'³                                                                           ³
'³Notes:                                                                     ³
'³      Source files must be saved in Text format.                           ³
'³                                                                           ³
'³      Five parameters are required for this program -- one or more main    ³
'³      program names, the new .QLB file name, a list file name (NUL for no  ³
'³      list), one or more library names from which to extract the needed    ³
'³      routines, and the BQLB## support library.  As with LIB and LINK, a   ³
'³      semicolon (;) can be used to force MAKEQLB to use its defaults.      ³
'³                                                                           ³
'³      The program will check for routines that were declared but never     ³
'³      used or BASIC procedures that were defined but never used.           ³
'³      Declared unreferenced routines will not be added to the new Quick    ³
'³      Library.                                                             ³
'³                                                                           ³
'³      If a list file (.LST) is given in place of the source file name,     ³
'³      the program will make the quick library from the list instead of     ³
'³      searching the source files for external references.                  ³
'³                                                                           ³
'³MAKEQLB basicprogram1 [Basicprogram2] [Object.obj], quicklib[.qlb],_       ³
'³         listfile[.lst], library[.lib] [library2[.lib], [bqlb##][;]        ³
'³                                                                           ³
'³Example:                                                                   ³
'³      MAKEQLB MyProg,,, Pro, bqlb41                                        ³
'³                                                                           ³
'³Compile and Link as follows:                                               ³
'³>BC makeqlb /ah /s /o;                                                     ³
'³>LINK /e/noe makeqlb [nocom] [nolpt] [smallerr] [tscnionr] [nofltin],,,pro;³
'³                                                                           ³
'³      [] = optional items. "smallerr" is available with BASIC 6 and 7 PDS, ³
'³      "no" object files may not be included with your compiler.            ³
'³                                                                           ³
'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

DEFINT A-Z


'~~~~~ Define Constants
CONST BQLB$ = "BQLB45.LIB"              'QuickBASIC 4.5
'CONST BQLB$ = "QBXQLB.LIB"             'Default BASIC link library (PDS)
'CONST BQLB$ = "VBDOSQLB.LIB"           'Default BASIC link library (VB/DOS)
'CONST BQLB$ = "BQLB41.LIB"             'QuickBASIC 4.00b and BASIC 6.00a
'CONST BQLB$ = "BQLB40.LIB"             'QuickBASIC 4.00

'CONST DefaultLib$ = "PRO7.LIB"         'Default library (PDS and VB/DOS)
CONST DefaultLib$ = "PRO.LIB"           'QuickBASIC 4.00 .. BASIC 6

CONST BASProc = -1                      'Flag for BASIC procedures
CONST RefedProc = -2                    'Flag for referenced procedures
CONST MaxProcs = 300                    'Maximum number of procedures
CONST ProcLen2 = 40                     'Maximum length for a procedure name
CONST ProcLen = 30                      'Maximum length for module level
                                        '  procedure names
                                        '  Must be a power of 2 minus 2
                                        '  [ie. 30 = (2 ^ 5) - 2]
                                        '  because the TYPE below is used to
                                        '  DIM a huge array whose size could
                                        '  span multiple segments.

'~~~~~ Define TYPEs for procedure Info
TYPE ModProcs                           'Module procedure information
   ProcName AS STRING * ProcLen         'Procedure name
   Count AS INTEGER                     'Number of references in module
END TYPE

TYPE ProcInfo                           'Procedure information for program
   ProcName AS STRING * ProcLen2        'Procedure name
   AliasName AS STRING * ProcLen2       'ALIAS'ed name
   BasFlag AS INTEGER                   'Flag field for BASIC procedure
   Refed AS INTEGER                     'Flag field shows referenced proc.
END TYPE


'~~~~~ Declare routines
DECLARE FUNCTION Blanks% (Strng$)
DECLARE FUNCTION CheckSum% (Strg$)
DECLARE FUNCTION Exist% (FileName$)
DECLARE FUNCTION FixPath$ (Path$)
DECLARE FUNCTION MaxInt% (Var1%, Var2%)
DECLARE FUNCTION NoPath$ (FileName$)
DECLARE FUNCTION NoXtn$ (FileName$)
DECLARE FUNCTION Null% (Text$)
DECLARE FUNCTION QInstrB% (Start%, Text$, Find$)
DECLARE FUNCTION UserInp$ (NoSemi, Prompt$, Default$)
DECLARE FUNCTION Valid% (FileName$)

DECLARE SUB CheckExtension (FileName$, DefaultXtn$)
DECLARE SUB CheckName (FileName$)
DECLARE SUB FatalErr (Message$)
DECLARE SUB FindT (SEG Element AS ANY, TypeWidth, NumEls, Search$)
DECLARE SUB GetParms (FileName$, NewLib$, LstFile$, InpLibs$, BASLib$)
DECLARE SUB IncludeResponseFiles (CMD$)
DECLARE SUB MakeObj (Subs, Procs() AS ProcInfo, LstFile$)
DECLARE SUB QPrint0 (Text$, Clr)
DECLARE SUB ReadSource (FileName$, Procs() AS ProcInfo, Subs)
DECLARE SUB SortT (SEG Element AS ANY, NumEls, Dir, TypeWidth, Offset, FieldWidth)
DECLARE SUB SrchPath (FileName$, Paths$, NotFound)



'~~~~~ Dim Procedure information array
DIM Procs(1 TO MaxProcs) AS ProcInfo

DIM SHARED ObjName$, RspName$
                                        'Temporary Object file
ObjName$ = FixPath$(ENVIRON$("TMP")) + "ChrisMay.obj"
                                        'Temporary response file for LINK
RspName$ = FixPath$(ENVIRON$("TMP")) + "DonMalin.rsp"

DIM SHARED Zero, One, Default
Zero = 0
One = 1
Default = -One



'~~~~~ Print Banner
PRINT
PRINT "Quick-Library Maker Utility  Version 1.05"
PRINT "Copyright (c) 1988-1990 Crescent Software, Inc."
PRINT "11 Bailey Avenue, Ridgefield, CT 06877  203-438-5300"
PRINT



'~~~~~ Get input parameters from COMMAND$ or by prompting the User
GetParms FileName$, NewLib$, LstFile$, InpLibs$, BASLib$



Subs = 0                                'Init. number of procs.


'~~~~~ Read each Main Module or List file specified
Look = 1
DO
   Spac = INSTR(Look, FileName$, " ")
   IF Spac = 0 THEN Spac = INSTR(Look, FileName$, "+")
   IF Spac = 0 THEN Spac = LEN(FileName$) + 1
   SourceName$ = LTRIM$(MID$(FileName$, Look, Spac - Look))

   CheckExtension SourceName$, ".BAS"

   Per = INSTR(QInstrB(Default, SourceName$, "\") + 1, SourceName$, ".")

   '~~~~~ Check the file's extension
   SELECT CASE MID$(SourceName$, Per + 1)
     
      '~~~~~ Are we using a List file (.LST)?
      CASE "LST"

         '~~~~~ Read the routine names into array (Procs)
         CheckName SourceName$
         OPEN SourceName$ FOR INPUT AS #1
         Blank$ = SPACE$(ProcLen2)
         DO UNTIL EOF(One)
            Subs = Subs + 1
            IF Subs > MaxProcs THEN FatalErr "Too many procedures!"
            LINE INPUT #1, Procs(Subs).ProcName
            IF Procs(Subs).ProcName = Blank$ THEN
               Subs = Subs - 1
            ELSE
               Procs(Subs).ProcName = UCASE$(Procs(Subs).ProcName)
            END IF
         LOOP
         CLOSE #1

      CASE "OBJ"
         OtherObjName$ = OtherObjName$ + " " + SourceName$

      CASE ELSE

         '~~~~~ Search source files for external references
         ReadSource SourceName$, Procs(), Subs

   END SELECT

   Look = Spac + 1
LOOP UNTIL Spac = LEN(FileName$) + 1



'~~~~~ Bail out if no external routines found.
IF Subs = 0 THEN FatalErr "No external routines required."



'~~~~~ Sort the procedure names
SortT Procs(1), Subs, Zero, ProcLen2 * 2 + 4, 0, ProcLen2



'~~~~~ Create the object and list files
MakeObj Subs, Procs(), LstFile$



'~~~~~ Display status message
LOCATE , One
QPrint0 SPACE$(78), Default
QPrint0 "Creating " + NewLib$, Default




'~~~~~ Create a LINK response file
OPEN RspName$ FOR OUTPUT AS #1
PRINT #1, "/q/noe/seg:512 "; ObjName$; OtherObjName$; ","
PRINT #1, NewLib$; ",nul,"
PRINT #1, InpLibs$; "+"
PRINT #1, BASLib$; ";"
CLOSE #1



'~~~~~ SHELL out to LINK.EXE to build the new Quick Library.
SHELL "LINK @" + RspName$ + " > LinkErr$.Tmp"

KILL RspName$
KILL ObjName$
IF NOT Exist("LinkErr$.Tmp") THEN FatalErr "Cannot find [LINK.EXE]!"



'~~~~~ Check for LIB.EXE errors (OBJects not found)
LOCATE , One
LinkErr = 0
OPEN "LinkErr$.Tmp" FOR INPUT AS #1     'Open LIB.EXE message file

DO UNTIL EOF(One)
   LINE INPUT #1, Text$                 'Read a line
                                        'Was there an error?
   IF INSTR(Text$, "error") OR INSTR(UCASE$(Text$), "MEMORY") THEN
      BEEP                              'Yes, display the message
      LinkErr = -1
      PRINT SPACE$(79)
      PRINT Text$
      DO UNTIL EOF(One)
         LINE INPUT #1, Text$
         PRINT Text$
      LOOP
   END IF
LOOP                                    'Look for more

CLOSE #1
KILL "LinkErr$.Tmp"



'~~~~~ Display status message
IF NOT LinkErr THEN
   QPrint0 SPACE$(78), Default
   PRINT NewLib$; " Created."
END IF



'~~~~~ Data used by "MakeObj" to create Object file header and footer.
DATA 128,14,0,12,99,104,114,105,115,109,97,121,46,65,83,77,247,150,39
DATA 0,0,6,68,71,82,79,85,80,13,67,72,82,73,83,77,65,89,95,84,69,88,84
DATA 4,68,65,84,65,4,67,79,68,69,5,95,68,65,84,65,160,152,7,0,72,0
DATA 0,3,5,1,16,152,7,0,72,0,0,6,4,1,14,154,4,0,2,255,2,95
DATA 136,4,0,0,162,1,209,138,2,0,0,116

SUB CheckExtension (FileName$, DefaultXtn$) STATIC

   Per = INSTR(QInstrB(Default, FileName$, "\") + 1, FileName$, ".")
   IF Per = 0 THEN
      FileName$ = FileName$ + DefaultXtn$
   END IF

END SUB

'~~~~~ Check File Name for validity
SUB CheckName (FileName$) STATIC

    IF NOT Valid%(FileName$) THEN
       FatalErr "`" + FileName$ + "' is not a valid file name!"
    END IF

END SUB

'~~~~~ Displays error message and ends the program
SUB FatalErr (Message$) STATIC

    BEEP
    PRINT
    QPrint0 Message$ + "  Program terminated.", Default
    PRINT
    END

END SUB

FUNCTION FixPath$ (Path$) STATIC

   Temp$ = Path$
   IF LEN(Temp$) THEN
      IF RIGHT$(Temp$, 1) <> ":" AND RIGHT$(Temp$, 1) <> "\" THEN
         Temp$ = Temp$ + "\"
      END IF
   END IF

   FixPath$ = Temp$

END FUNCTION

'~~~~~ Get Input Parameters from User
SUB GetParms (FileName$, NewLib$, LstFile$, InpLibs$, BASLib$) STATIC

    FileName$ = ".BAS"
    InpLibs$ = DefaultLib$
    BASLib$ = BQLB$
    NoSemi = 5


    '~~~~~ Get command line parameters from COMMAND$
    IF LEN(COMMAND$) THEN

       Param = 1
       P = 1
       CMD$ = COMMAND$


       '~~~~~ Check for response files and include them if found
       IncludeResponseFiles CMD$


       DO
          '~~~~~ Parse out parameter looking for [,] or [;] or EOL
          PC = INSTR(P, CMD$, ",")
          IF PC = 0 THEN PC = INSTR(P, CMD$, ";")
          IF PC = 0 THEN PC = LEN(CMD$) + 1
          Temp$ = UCASE$(LTRIM$(RTRIM$(MID$(CMD$, P, PC - P))))


          '~~~~~ Assign parameters
          SELECT CASE Param
             CASE 1                             'File Name
                FileName$ = Temp$
                IF FileName$ = "" THEN FatalErr "No Source File Name!"
                BaseName$ = NoXtn$(FileName$)
                NoSemi = 4
             CASE 2                             'New Quick Library name
                NewLib$ = Temp$
                NoSemi = 3
             CASE 3                             'List file name
                LstFile$ = Temp$
                NoSemi = 2
             CASE 4                             'Input Library names
                InpLibs$ = Temp$
                NoSemi = 1
             CASE 5                             'BASIC library name
                BASLib$ = Temp$
                NoSemi = 0
             CASE ELSE
          END SELECT

          Param = Param + 1                     'Bump parameter number
          P = PC + 1
       LOOP UNTIL PC >= LEN(CMD$) OR MID$(CMD$, PC, One) = ";"   'Get another

    END IF


    '~~~~~ Prompt User for parameters
    IF INSTR(CMD$, ";") = 0 THEN                'No semicolon, prompt User
       IF NoSemi = 5 THEN GOSUB GetSource
       IF NoSemi >= 4 THEN GOSUB GetNewLib
       IF NoSemi >= 3 THEN GOSUB GetListFile
       IF NoSemi >= 2 THEN GOSUB GetInputLibs
       IF NoSemi >= 1 THEN GOSUB GetBQLBLib
       PRINT
    END IF


    '~~~~~ Make default names for parameters if required
    IF LEN(NewLib$) = 0 THEN NewLib$ = NoPath$(BaseName$) + ".QLB"
    CheckExtension NewLib$, ".QLB"
    CheckName NewLib$

    IF LEN(LstFile$) = 0 THEN LstFile$ = NoPath$(BaseName$) + ".LST"
    CheckExtension LstFile$, ".LST"
    CheckName LstFile$

    IF LEN(InpLibs$) = 0 THEN InpLibs$ = DefaultLib$

    IF LEN(BASLib$) = 0 THEN BASLib$ = BQLB$
    CheckExtension BASLib$, ".LIB"
    CheckName BASLib$


    '~~~~~ Search for required libraries using "LIB" environment variables
    LibPaths$ = ENVIRON$("LIB")

    P = 1
    DO                                          'Parse out individual names
       PC = INSTR(P, InpLibs$, " ")
       IF PC = 0 THEN PC = LEN(InpLibs$) + 1
       InpLib$ = LTRIM$(RTRIM$(MID$(InpLibs$, P, PC - P)))

       CheckExtension InpLib$, ".LIB"
       CheckName InpLib$

       SrchPath InpLib$, LibPaths$, NotFound    'Check path for file
       IF NotFound THEN
          PRINT InpLib$; " not found!"
          GOSUB GetInputLibs
          IF RIGHT$(InpLibs$, 1) = ":" OR RIGHT$(InpLibs$, 1) = "\" THEN
             InpLibs$ = InpLibs$ + NoPath$(InpLib$)
          END IF
          PC = 1
       END IF

       P = PC + Blanks(MID$(InpLibs$, PC))
    LOOP UNTIL P > LEN(InpLibs$)

    DO
       SrchPath BASLib$, LibPaths$, NotFound    'Check paths for BASIC library
       IF NotFound THEN
          Temp$ = BASLib$
          PRINT BASLib$; " not found!"
          GOSUB GetBQLBLib
          CheckExtension BASLib$, ".LIB"
          IF RIGHT$(BASLib$, 1) = ":" OR RIGHT$(BASLib$, 1) = "\" THEN
             BASLib$ = BASLib$ + NoPath$(Temp$)
          END IF
          Temp$ = ""
       END IF
    LOOP WHILE NotFound


    EXIT SUB


'~~~~~ Get Source file name
GetSource:
    FileName$ = UserInp$(NoSemi, "Main Module Name", FileName$)

    IF FileName$ = ".BAS" THEN END           'Check validity
    BaseName$ = NoXtn$(FileName$)
RETURN


'~~~~~ Get output library name
GetNewLib:
    IF LEN(NewLib$) THEN
       Default$ = NewLib$
    ELSE
       Default$ = NoPath$(BaseName$) + ".QLB"
    END IF

    NewLib$ = UserInp$(NoSemi, "Output Library Name", Default$)
RETURN


'~~~~~ Get list file name
GetListFile:
    IF LEN(LstFile$) THEN
       Default$ = LstFile$
    ELSE
       Default$ = NoPath$(BaseName$) + ".LST"
    END IF

    LstFile$ = UserInp$(NoSemi, "List File Name", Default$)
RETURN


'~~~~~ Get input library names
GetInputLibs:
    InpLibs$ = UserInp$(NoSemi, "Input Libraries", InpLibs$)
RETURN


'~~~~~ Get BASIC library [BQLB] name
GetBQLBLib:
    BASLib$ = UserInp$(NoSemi, "BQLB## Library Name", BASLib$)
RETURN


END SUB

SUB IncludeResponseFiles (CMD$)

    '~~~~~ Check for a response file... allows use of "+" for continuation
    '      of lines.
    DO
       RspFile = INSTR(CMD$, "@")
       IF RspFile THEN
          LeftSide$ = LEFT$(CMD$, RspFile - 1)

          FOR N = RspFile + 1 TO LEN(CMD$)
             IF INSTR(" +,;@&", MID$(CMD$, N, 1)) THEN EXIT FOR
          NEXT

          RightSide$ = MID$(CMD$, N)
          Temp$ = MID$(CMD$, RspFile + 1, N - RspFile - 1)

          OPEN Temp$ FOR INPUT AS #2

          DO UNTIL EOF(2)
             LINE INPUT #2, Temp$
             LeftSide$ = LeftSide$ + Temp$
          LOOP
          Temp$ = ""
          CLOSE #2

          CMD$ = LeftSide$ + RightSide$
       END IF

    LOOP WHILE RspFile

END SUB

'~~~~~ Create an Object file consisting of EXTRN declarations
'~~~~~ Also writes the List File
SUB MakeObj (Subs, Procs() AS ProcInfo, LstFile$) STATIC

    LOCATE , One
    QPrint0 "Creating temporary file: `ChrisMay.obj'.", Default


    '~~~~~ Create files
    IF Exist%(ObjName$) THEN KILL ObjName$
    OPEN ObjName$ FOR BINARY AS #1
    OPEN LstFile$ FOR OUTPUT AS #2


    '~~~~~ Compose OBJ Header string
    A$ = SPACE$(86)
    FOR N = 1 TO 86
       READ I
       MID$(A$, N) = CHR$(I)
    NEXT
    PUT #1, , A$


    '~~~~~ Compose external procedure names into OBJ form
    I = 1                                       'initial value
    DO
       Count = 0
       FileList$ = ""

       FOR N = I TO Subs                        'For each procedure name

           IF Procs(N).BasFlag = 0 THEN         'If it's an external proc.
                      'print name to list file
              IF NOT Null%(Procs(N).AliasName) THEN
                 A$ = Procs(N).AliasName
              ELSE
                 A$ = Procs(N).ProcName
              END IF

              A$ = RTRIM$(A$)

              PRINT #2, A$

              Lng = LEN(A$)
              Count = Count + Lng + 2
              IF Count > 1018 THEN EXIT FOR
              FileList$ = FileList$ + CHR$(Lng) + A$ + CHR$(Zero)
           END IF

       NEXT

       Lng = LEN(FileList$) + 1
       FileList$ = "Œ" + CHR$(Lng MOD 256) + CHR$(Lng \ 256) + FileList$
       FileList$ = FileList$ + CHR$(CheckSum(FileList$))
       PUT #1, , FileList$
       I = N

    LOOP WHILE I <= Subs


    '~~~~~ Compose OBJ Footer
    A$ = SPACE$(12)
    FOR N = 1 TO 12
       READ I
       MID$(A$, N) = CHR$(I)
    NEXT
    PUT #1, , A$


    CLOSE #1, #2

END SUB

FUNCTION NoPath$ (FileName$) STATIC

    N = MaxInt(QInstrB(Default, FileName$, ":"), QInstrB(Default, FileName$, "\"))

    NoPath$ = MID$(FileName$, N + 1)

END FUNCTION

'~~~~~ Returns the base part of a file name
FUNCTION NoXtn$ (FileName$) STATIC

    Per = INSTR(QInstrB(Default, FileName$, "\") + 1, FileName$, ".")
    Spac = INSTR(FileName$, " ")
    IF Spac = 0 THEN Spac = LEN(FileName$) + 1

    IF Per > 0 AND Per < Spac THEN
       NoXtn$ = LEFT$(FileName$, Per - 1)
    ELSE
       NoXtn$ = LEFT$(FileName$, Spac - 1)
    END IF

END FUNCTION

'~~~~~ Read Source files looking for external routines and dead code
SUB ReadSource (FileName$, Procs() AS ProcInfo, Subs) STATIC

    RtnTerm$ = " =-)(%!#&@$:" + CHR$(9)  'Terminators for SUB/FUNCTION names
    Quote$ = CHR$(34)

    REDIM KWord$(3)                      'Keyword table for finding procedures
    KWord$(0) = "FUNCTION "
    KWord$(1) = "SUB "
    KWord$(2) = "CALL "
    KWord$(3) = "CALLS "


    CheckName FileName$

    '~~~~~ Parse out file's path name
    Path$ = LEFT$(FileName$, INSTR(FileName$, NoPath$(FileName$)) - 1)


    '~~~~~ Load up the .MAK file if there is one.
    MakeName$ = NoXtn$(FileName$) + ".MAK"

    IF Exist%(MakeName$) THEN
       OPEN MakeName$ FOR INPUT AS #1

       Modules = 0                              'Count the number of modules
       DO UNTIL EOF(One)
          LINE INPUT #1, Text$
          IF LEN(LTRIM$(Text$)) THEN Modules = Modules + 1
       LOOP
       CLOSE #1

       REDIM Make$(Modules)                     'Make array for module names
       OPEN MakeName$ FOR INPUT AS #1

       FOR M = 1 TO Modules                     'Read the module names
          LINE INPUT #1, Make$(M)
          IF LEN(Make$(M)) THEN
                                                'Add a path name if needed
             IF INSTR(Make$(M), "\") = 0 AND INSTR(Make$(M), ":") = 0 THEN
                Make$(M) = Path$ + Make$(M)
             END IF
             CheckExtension Make$(M), ".BAS"
             IF NOT Exist%(Make$(M)) THEN FatalErr Make$(M) + " not found!"
          ELSE
             M = M - 1
          END IF
       NEXT

       CLOSE #1

    ELSE                                        'One module

       Modules = 1
       REDIM Make$(1)
       Make$(1) = FileName$

    END IF
                  'See if we have enough memory
    IF FRE(-1) < ((MaxProcs + 1) * Modules * CLNG(ProcLen + 2)) + 1028& THEN
       FatalErr "Not enough memory (too many modules)!"
    END IF
                  'Array for module level procs.
    REDIM ModSub(MaxProcs, 1 TO Modules) AS ModProcs
    Rtn$ = SPACE$(ProcLen2)                     'Work space for proc. names



    '~~~~~ Search All Files for Procedure Names
    LOCATE , One
    QPrint0 "Examining ", Default
    LOCATE , 11


    FOR M = 1 TO Modules                        'Examine each module
       Handle = 1                               'File handle for module

       IF NOT Exist%(Make$(M)) THEN FatalErr "Cannot find " + Make$(M) + "!"


       '~~~~~ Test for binary file (Fast Load and Save)
       Test$ = " "
       OPEN Make$(M) FOR BINARY AS #Handle      'Open the module
       GET #Handle, , Test$
       CLOSE #Handle
       IF ASC(Test$) = 252 THEN
          FatalErr "Cannot process QuickBASIC - Fast Load and Save files!"
       END IF


       OPEN Make$(M) FOR INPUT AS #Handle       'Open the module

       QPrint0 SPACE$(68), Default
       QPrint0 Make$(M), Default


       '~~~~~ Read until end of module
       'Note "ERR = 62" is faster in
       '  P.D.Q..  Use EOF(Handle)
       '  in regular QB
       DO UNTIL Handle = 1 AND EOF(One)

          DO WHILE EOF(Handle)                 'Close include file when done
             CLOSE #Handle
             Handle = Handle - 1
             IF Handle = 1 THEN                'Redisplay module name
                QPrint0 SPACE$(68), Default
                QPrint0 Make$(M), Default
                EXIT DO
             END IF
          LOOP
          IF Handle = 1 AND EOF(1) THEN EXIT DO

          Ky$ = INKEY$                         'Check for Ctrl C
          IF LEN(Ky$) THEN
             IF ASC(Ky$) = 3 THEN FatalErr ""
          END IF


          LINE INPUT #Handle, Text$            'Read a line of text


          '~~~~~ Remove quoted strings
          DO
             BQ = INSTR(Text$, Quote$)
             IF BQ THEN
                IF INSTR(Text$, "ALIAS") = 0 THEN 'Except Alias name
                   EQ = INSTR(BQ + 1, Text$, Quote$)
                   IF EQ = 0 THEN EQ = BQ
                   Text$ = LEFT$(Text$, BQ - 1) + MID$(Text$, EQ + 1)
                ELSE
                   MID$(Text$, 1, BQ) = UCASE$(Text$)
                   EXIT DO
                END IF
             ELSE
                Text$ = UCASE$(Text$)                'Make it upper case
             END IF
          LOOP WHILE BQ



          '~~~~~ Get Length without comments
          Length = INSTR(Text$, "'") - 1
          IF Length = -1 THEN Length = INSTR(Text$, "REM ") - 1
          IF Length = -1 THEN Length = LEN(Text$)



          '~~~~~ Look for INCLUDE files
          Inc = INSTR(Text$, "$INCLUDE:")

          IF Inc THEN

             IF INSTR(Length + 2, Text$, "'") > Inc THEN
                Inc = INSTR(Inc, Text$, "'") + 1
                Inc2 = INSTR(Inc, Text$, "'")
                IF Inc2 > Inc THEN
                   IncName$ = MID$(Text$, Inc, Inc2 - Inc)
                   CheckExtension IncName$, ".BAS"
                                                'Add path to include name
                   IF LEN(Path$) AND INSTR(IncName$, "\") = 0 AND INSTR(IncName$, ":") = 0 THEN
                      IncName$ = Path$ + IncName$
                   END IF

                   IF NOT Exist%(IncName$) THEN
                      IncName$ = MID$(IncName$, LEN(Path$) + 1)
                                                'Check environment path
                      SrchPath IncName$, ENVIRON$("INCLUDE"), NotFound
                      IF NotFound THEN FatalErr "Include file " + IncName$ + " not found!"
                   END IF

                   Handle = Handle + 1          'Bump handle
                   OPEN IncName$ FOR INPUT AS #Handle 'Open the include file

                   QPrint0 SPACE$(68), Default  'Display the name of INCLUDE
                   QPrint0 "Include File: " + IncName$, Default

                   Length = 0
                END IF
             END IF
          END IF



          Text$ = LTRIM$(LEFT$(Text$, Length))  'Trim left side and remark


          IF LEN(Text$) THEN                    'If its not a Null string,

             ' ### 2/17/93  BS
             ' Convert line back from VB/DOS format for processing
             IF LEFT$(Text$, 10) = "STATIC SUB" OR LEFT$(Text$, 15) = "STATIC FUNCTION" THEN
                Text$ = RIGHT$(Text$, LEN(Text$) - 7) + " STATIC"
             END IF


             '~~~~~ Check for each key word
             FOR KW = 0 TO 3
                 KWPos = 1

                 DO
                                                'Look for key word
                    KWPos = INSTR(KWPos, Text$, KWord$(KW))

                    IF KWPos > 1 THEN           'Make sure it's a whole word
                       IF INSTR(" " + CHR$(9), MID$(Text$, KWPos - 1, One)) = 0 THEN KWPos = 0
                    END IF


                    IF KWPos THEN               'If there's a valid key word

                       '~~~~~ Extract the keyword from the line
                                                'Bump pointer to end of key
                       KWEnd = KWPos + LEN(KWord$(KW))
                                                'look for end of proc. name
                       FOR P2 = KWEnd + 1 TO LEN(Text$)
                           IF INSTR(RtnTerm$, MID$(Text$, P2, One)) THEN EXIT FOR
                       NEXT
                                                'Extract procedure name
                       LSET Rtn$ = MID$(Text$, KWEnd, P2 - KWEnd)


                       '~~~~~ See if procedure used before in ANY modules
                       St = 1
                       DO
                          N = Subs - St + 1
                          FindT Procs(St), ProcLen2 * 2 + 4, N, Rtn$
                          IF N = -1 THEN
                             N = Subs + 1
                             IF N > MaxProcs THEN FatalErr "Too many procedures!"
                             EXIT DO
                          ELSE
                             N = N + St
                             IF Procs(N).ProcName = Rtn$ THEN EXIT DO
                             St = N + 1
                          END IF
                       LOOP UNTIL St > Subs


                       '~~~~~ See if procedure used before in THIS module
                       MS = ModSub(0, M).Count
                       ModSub(0, M).ProcName = Rtn$
                       FindT ModSub(1, M), ProcLen + 2, MS, ModSub(0, M).ProcName
                       IF MS = -1 THEN
                          MS = ModSub(0, M).Count + 1
                          ModSub(0, M).Count = MS   'Bump number of procedures
                          ModSub(MS, M).ProcName = Rtn$ 'Assign Proc. name
                       ELSE
                          MS = MS + 1
                       END IF


                       '~~~~~ If it's a "CALL" or "CALLS",
                       IF KW > 1 THEN           'Bump count for routine
                          ModSub(MS, M).Count = ModSub(MS, M).Count + 1
                          Procs(N).Refed = 2
                       END IF


                       '~~~~~ Is this a BASIC proc. definition (SUB/FUNCTION)?
                       IF KW < 2 THEN
                          IF INSTR(Text$, "DECLARE") <> KWPos - 8 THEN
                             Procs(N).BasFlag = BASProc 'Set flag
                                                'If referenced before, set flag
                             IF Procs(N).Refed > 1 OR ModSub(MS, M).Count THEN
                                Procs(N).BasFlag = RefedProc
                             END IF
                          END IF
                       END IF


                       '~~~~~ If its a new procedure name
                       IF N > Subs THEN
                          Procs(N).ProcName = Rtn$ 'Assign it
                          Subs = N              'Bump number of procedures
                                                'Look for an ALIAS name
                          Al = INSTR(Text$, "ALIAS")
                          IF Al THEN
                             Al = Al + 7
                             AlEnd = INSTR(Al, Text$, CHR$(34))
                             Procs(N).AliasName = MID$(Text$, Al, AlEnd - Al)
                          ELSE
                             Al = INSTR(Text$, "CDECL")
                             IF Al THEN
                                Procs(N).AliasName = "_" + LCASE$(Rtn$)
                                FOR P = 2 TO LEN(Procs(N).AliasName)
                                   IF MID$(Procs(N).AliasName, P, 1) = "." THEN
                                      MID$(Procs(N).AliasName, P, 1) = "_"
                                   END IF
                                NEXT
                             END IF
                          END IF
                          
                                                'Is this a BASIC procedure?
                       ELSEIF Procs(N).BasFlag = BASProc THEN
                          IF Procs(N).Refed > 1 OR ModSub(MS, M).Count THEN
                                                'Set flag to show it was
                             Procs(N).BasFlag = RefedProc '  referenced
                          END IF
                       END IF

                                                'Remove Name so it isn't
                                                '  found below
                       Text$ = LEFT$(Text$, KWEnd - 1) + MID$(Text$, P2)

                       KWPos = KWPos + 1        'Bump pointer for next word

                    END IF

                 LOOP WHILE KWPos AND KW > 1    'Look for more on line

             NEXT                               'Check for next key word


             '~~~~~ Look for references to procs. that were declared
             FOR N = 1 TO ModSub(0, M).Count    'Examine text for prev. refs.

                IF ModSub(N, M).Count = 0 THEN

                   ProcName$ = RTRIM$(ModSub(N, M).ProcName)
                   Look = 0
                   DO
                      Look = INSTR(Look + 1, Text$, ProcName$)

                      IF Look THEN
                         Start = Look
                         IF Start > 1 THEN      'Beginning of line?
                                                'Check Beginning of word
                            IF INSTR(RtnTerm$, MID$(Text$, Start - 1, One)) = 0 THEN
                               Start = 0
                            END IF
                         END IF

                         IF Start THEN          'Check end of word
                            PrLen = LEN(ProcName$)
                            IF INSTR(RtnTerm$, MID$(Text$, Start + PrLen, One)) THEN
                               ModSub(N, M).Count = ModSub(N, M).Count + 1
                                                'Check for previous refs.
                               LSET Rtn$ = MID$(Text$, Start, PrLen)
                               P = Subs
                               FindT Procs(1), ProcLen2 * 2 + 4, P, Rtn$
                               IF P > -1 THEN
                                  P = P + 1
                                                'Is it a BASIC procedure?
                                  IF Procs(P).BasFlag THEN
                                     '~~~~~ Check for function assignment
                                     IF MID$(Text$, Start + PrLen + 1, One) = "=" THEN
                                                'Decrement counter
                                        ModSub(N, M).Count = ModSub(N, M).Count - 1
                                     ELSE        'Show it was referenced
                                        Procs(P).Refed = 2
                                     END IF
                                  ELSE          'Show it was referenced
                                     Procs(P).Refed = 2
                                  END IF
                               END IF
                            END IF
                         END IF
                      END IF

                   LOOP WHILE Look

                END IF
             NEXT

          END IF

       LOOP                                     'Read another line of text

       CLOSE #1                                 'Close the module

    NEXT                                        'Read the next module file

    ERASE KWord$                                'Clean up string space
    Text$ = ""

    LOCATE , One
    QPrint0 SPACE$(78), Default                 'Erase message from screen


    '~~~~~ Display unreferenced routines
    NoTitle = -1
    Temp$ = SPACE$(4)
    FOR M = 1 TO Modules                        'For each module
       NoModName = -1
       FOR N = 1 TO ModSub(0, M).Count          'For each procedure in module
          IF ModSub(N, M).Count = 0 THEN        'Count of 0 means wasn't used
                                                'Look in master list
             P = Subs
             FindT Procs(1), ProcLen2 * 2 + 4, P, ModSub(N, M).ProcName
             P = P + 1
                                                'Confirm lack of reference
             IF Procs(P).BasFlag <> RefedProc AND Procs(P).Refed <> 2 THEN

                IF NoTitle THEN                 'Print error message
                   PRINT
                   PRINT "Note: The following procedures have been declared or defined but never used."
                   NoTitle = 0
                END IF
                IF NoModName THEN               'Print Module name
                   PRINT Make$(M)
                   NoModName = 0
                END IF
                                                'Print procedure name
                PRINT Temp$; ModSub(N, M).ProcName;
                IF Procs(P).BasFlag = BASProc THEN 'Print message
                   PRINT " is an unused BASIC procedure."
                ELSE
                   PRINT " was DECLAREd but not used";
                   IF Procs(P).Refed <> 2 THEN
                      PRINT "."
                      Procs(P).BasFlag = 1
                   ELSE
                      PRINT " in this module."
                      Procs(P).BasFlag = 0
                   END IF
                END IF
             END IF
          END IF
       NEXT
    NEXT

    ERASE ModSub, Make$
    Rtn$ = ""

END SUB

'~~~~~ Search an environment path for a file
SUB SrchPath (FileName$, Paths$, NotFound) STATIC

    NotFound = -1                               'Guilty until proven otherwise
    Path$ = ""                                  'No Path yet
    PP = 1                                      'Present position

    DO UNTIL Exist(Path$ + FileName$)           'Loop until we find the file
       IF PP > LEN(Paths$) THEN EXIT SUB        'Bail out if no more paths

       PCP = INSTR(PP, Paths$, ";")             'Find Semicolon position
       IF PCP = 0 THEN PCP = LEN(Paths$) + 1    'Last path
                                                'Parse out the path
       Path$ = LTRIM$(RTRIM$(MID$(Paths$, PP, PCP - PP)))
                                                'Ensure there's a "\" at end
       IF RIGHT$(Path$, One) <> "\" THEN Path$ = Path$ + "\"
                                                'Bump position for next path
       PP = PCP + 1
    LOOP

    FileName$ = Path$ + FileName$               'Add the path to the file name
    NotFound = 0

END SUB

'~~~~~ Prompt User for input
FUNCTION UserInp$ (NoSemi, Prompt$, Default$) STATIC

    PRINT Prompt$; " ["; Default$; "]: ";
    LINE INPUT ""; Temp$
    
    Temp$ = UCASE$(LTRIM$(RTRIM$(Temp$)))
    IF RIGHT$(Temp$, One) = ";" THEN
       Temp$ = LEFT$(Temp$, LEN(Temp$) - 1)
       NoSemi = 0
    END IF
    IF LEN(Temp$) = 0 THEN Temp$ = Default$
    
    UserInp$ = Temp$

END FUNCTION

