'********** DEMOIN.BAS - shows all of the input routines in context

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z  'use integers throughout - faster and requires less variable space

  
'BASIC subprograms demonstrated
DECLARE SUB CapNum ()
DECLARE SUB DateIn (Dt$, ExitCode, Colr)
DECLARE SUB NumIn (N#, Max, Places, ExitCode, Colr)
DECLARE SUB TextIn (T$, Max, NumOnly, CapsOn, ExitCode, Colr)
DECLARE SUB YesNoB (YN$, ExitCode, Colr)

'Assembler subprograms and functions used by the demo only
DECLARE SUB ClearEOL (Colr)
DECLARE FUNCTION FUsing$ (Number$, Mask$)
DECLARE FUNCTION OneColor% (FG, BG)
DECLARE FUNCTION Peek1% (Segment, Address)
DECLARE SUB QPrint (X$, Colr, Page)

'Short functions to aid the screen formatting in the demo only
DEF FnExt$ (X$, Length) = X$ + SPACE$(Length - LEN(X$))  'for display only

DEF FnSlash$ (D$)                    'add slashes to date for display
  IF D$ = "" THEN D$ = SPACE$(6)
  D$ = LEFT$(D$, 2) + "/" + MID$(D$, 3, 2) + "/" + RIGHT$(D$, 2)
  FnSlash$ = D$
END DEF


   'determine if the monitor is mono or color
   '
   IF Peek1%(0, &H463) = &HB4 THEN      'mono monitor
      FG = 0
      BG = 7
   ELSE                                 'color
      FG = 7
      BG = 1
   END IF

   Colr = OneColor%(FG, BG)             'pack FG and BG into a single byte

   GOSUB InitializeTest                 'set up a few of the fields
   GOSUB DisplayScreen                  'display the entry screen


GetName:
   LOCATE 5, 6                          'location of beginning of field
   CapsOn = 0: NumOnly = 0: Max = 32    'specify field parameters
   CALL TextIn(Nam$, Max, NumOnly, CapsOn, XCode, Colr)        'get input
   IF XCode = 1 GOTO GetName            'can't back up any more, stay here
   IF XCode = 2 GOTO Done               'all done entering data

       
GetAddress:
   LOCATE 7, 6
   CALL TextIn(Address$, Max, NumOnly, CapsOn, XCode, Colr)
   IF XCode = 1 GOTO GetName            'go back to the name field
   IF XCode = 2 GOTO Done

          
GetCity:
   LOCATE 9, 6
   Max = 20                             'use a length of twenty here
   CALL TextIn(City$, Max, NumOnly, CapsOn, XCode, Colr)
   IF XCode = 1 GOTO GetAddress
   IF XCode = 2 GOTO Done
       

GetState:
   LOCATE 9, 36
   CapsOn = 1: NumOnly = 0: Max = 2     'force caps, use length of two for zip
   CALL TextIn(State$, Max, NumOnly, CapsOn, XCode, Colr)
   IF LEN(State$) THEN
      IF LEN(State$) <> 2 THEN          'state must be 2 letters or nothing
         PLAY "L16O3EC"
         GOTO GetState
      END IF
   END IF
   CapsOn = 0                           'reset this for the other fields
   IF XCode = 1 GOTO GetCity
   IF XCode = 2 GOTO Done

        
GetZip:
   LOCATE 9, 44
   CapsOn = 0: NumOnly = 1: Max = 5     'numeric only, please
   CALL TextIn(Zip$, Max, NumOnly, CapsOn, XCode, Colr)
   IF LEN(Zip$) THEN
      IF LEN(Zip$) < 5 THEN             'zip MUST be five digits or nothing
         PLAY "L16O3EC"
         GOTO GetZip
      END IF
   END IF
   IF XCode = 1 GOTO GetState
   IF XCode = 2 GOTO Done
        

GetPhone:
   LOCATE 11, 7
   NumOnly = 0: Max = 14
   CALL TextIn(Phone$, Max, NumOnly, CapsOn, XCode, Colr)
   IF XCode = 1 GOTO GetZip
   IF XCode = 2 GOTO Done
        

GetSS:
   LOCATE 13, 6
   NumOnly = 1: Max = 9
   CALL TextIn(SS$, Max, NumOnly, CapsOn, XCode, Colr)
   IF XCode = 1 GOTO GetPhone
   IF XCode = 2 GOTO Done
     

GetBalDue:
   LOCATE 13, 52
   Max = 8: Places = 2
   CALL NumIn(BalDue#, Max, Places, XCode, Colr)
   IF XCode = 1 GOTO GetSS
   IF XCode = 2 GOTO Done

         
GetDtPaid:
   LOCATE 15, 54
   CALL DateIn(DtPaid$, XCode, Colr)
   IF XCode = 1 GOTO GetBalDue
   IF XCode = 2 GOTO Done

         
GetMemo:
   LOCATE 19, 6
   CapsOn = 0: NumOnly = 0: Max = 74
   CALL TextIn(Memo$, Max, NumOnly, CapsOn, XCode, Colr)
   IF XCode = 1 GOTO GetDtPaid
       

Done:
   LOCATE 23, 1
   PRINT "Is this okay? (Yes/No) ";

   X$ = ""
   CALL YesNoB(X$, XCode, Colr)
   LOCATE , 1
   ClearEOL 7
   IF XCode = 1 GOTO GetMemo
   IF X$ = "N" GOTO GetName
   IF X$ <> "Y" GOTO Done               'insist on either Y or N or up-arrow

   LOCATE , 1
   PRINT "Thank You"
   END


InitializeTest:                         'initialize some of the screen data
   Nam$ = "Ralph Montenegro"
   Address$ = "14 Vander Avenue"
   City$ = "North Hollywood"
   State$ = "CA"
RETURN


DisplayScreen:                          'display screen w/any existing values
   CLS
   PRINT TAB(26);
   QPrint "QuickPak Input Routine Demo", 15, -1
   PRINT
   QPrint STRING$(80, "Í"), 15, -1

   LOCATE 5, 1: QPrint "Name", 15, -1
   LOCATE , 6:  QPrint FnExt$(Nam$, 32), Colr, -1

   LOCATE 7, 1: QPrint "Addr ", 15, -1
   LOCATE , 6:  QPrint FnExt$(Address$, 32), Colr, -1

   LOCATE 9, 1: QPrint "City ", 15, -1
   LOCATE , 6:  QPrint FnExt$(City$, 20), Colr, -1

   LOCATE 9, 30: QPrint "State ", 15, -1
   LOCATE , 36:  QPrint FnExt$(State$, 2), Colr, -1

   LOCATE 9, 40: QPrint "Zip ", 15, -1
   LOCATE , 44:  QPrint FnExt$(Zip$, 5), Colr, -1

   LOCATE 11, 1: QPrint "Phone ", 15, -1
   LOCATE , 7:   QPrint FnExt$(Phone$, 14), Colr, -1

   LOCATE 13, 1: QPrint "SS # ", 15, -1
   LOCATE , 6:   QPrint FnExt$(SS$, 9), Colr, -1

   LOCATE 13, 44: QPrint "Amt Due ", 15, -1
   LOCATE , 52:   QPrint FUsing$(STR$(AmtDue#), "########.##"), Colr, -1

   LOCATE 15, 44: QPrint "Date Paid ", 15, -1
   LOCATE , 54:   QPrint FnSlash$(DtPaid$), Colr, -1

   LOCATE 19, 1: QPrint "Memo ", 15, -1
   LOCATE , 6:   QPrint FnExt$(Memo$, 74), Colr, -1

RETURN

