'****************************************************************************
' DEMOMENU.BAS - PullDown/VertMenu demonstration program
' Demonstrates polling technics for both modules.  See also DEMOPULL.BAS
' and DEMOVERT.BAS.
'
' by Don Malin   (C) Crescent Software 1988-1989
'****************************************************************************

DEFINT A-Z


'----- BASIC subprograms
'
DECLARE SUB BarPrint (Choice$(), BarClr)
DECLARE SUB GetColor (Cnf AS ANY)
DECLARE SUB GetFiles (FileSpec$, FilName$, Cnf AS ANY)
DECLARE SUB CSMsgBox (Message$, Wdth, Cnf AS ANY)
DECLARE SUB PullDown (Choice$(), Stat(), Menu, Choice, Ky$, Action, Cnf AS ANY)
DECLARE SUB VertMenu (Item$(), Choice, Max.Len, BotLin, Ky$, Action, Cnf AS ANY)

'----- Assembler routines
'
DECLARE FUNCTION FCount% (Spec$)
DECLARE FUNCTION Monitor% ()

DECLARE SUB InitMouse (MouseThere)
DECLARE SUB MPaintBox (ULRow, ULCol, LRRow, LRCol, Colr)
DECLARE SUB MQPrint (X$, Colr)
DECLARE SUB MScrnSave (ULRow, ULCol, LRRow, LRCol, SEG Address)
DECLARE SUB MScrnRest (ULRow, ULCol, LRRow, LRCol, SEG Address)
DECLARE SUB ReadFile (BYVAL Address)
DECLARE SUB SetCursor (Row, Col)
DECLARE SUB ShowCursor ()
DECLARE SUB TextCursor (FG, BG)


'The first Include file contains a structure definition for menu and screen
'colors.  The second Include determines the type of monitor you are using and
'assigns appropriate colors.
'
'$INCLUDE: 'DEFCNF.BI'
'$INCLUDE: 'SETCNF.BI'

CONST Inactive = -1
CONST Active = 0

REDIM MMenu$(9, 5)                      'holds the menu choice strings
REDIM Stat(9, 5)                        'holds the choice status flags
REDIM Help$(9, 5)                       'holds Help strings
REDIM ScrTxt$(50)                       'holds the screen text

MMenu$(0, 0) = "ð"                      'this was the MS Help Icon

'******* Define Main Menu
RESTORE MenuStrngs                      'read the menu choices into the Array
FOR R = 0 TO 9                          'for each menu choice,
    FOR C = 1 TO 5                      '  read each menu.
        READ MMenu$(R, C)
    NEXT C
NEXT R

'*** Set Inactive menu choices
Stat(2, 1) = Inactive                   'can't save file until it's loaded
Stat(2, 3) = Inactive                   'can't cut a block until its marked
Stat(3, 3) = Inactive                   'ditto for copying and pasting.
Stat(4, 3) = Inactive
Stat(2, 4) = Inactive                   'can't repeat last find before find


'*** Some help strings need to be built up since contsant string assignments
'*** can only be 255 characters in length.
Help$(0, 0) = "Use the Left or Right arrow keys to move from menu to menu.  Inside a menu use the Up or Down arrow keys to move from item to item.  Once your selection has been hi-lited, press the Enter key to confirm the choice and continue.  "
Help$(0, 0) = Help$(0, 0) + "  Low-intensity choices are not selectable."
Help$(1, 1) = "Use this choice to simulate selecting and retrieving a file.  After selecting this choice, a vertical menu will be displayed containing all of the file names in the current directory."
Help$(2, 1) = "Selecting this menu choice will simulate saving the current file to disk.  Note that this item will be inactive (displayed in low intensity) until either a file has been retrieved or a new file is created."
Help$(4, 1) = "Use this choice to simulate marking a file as Read Only.  After selecting this function, a menu of all files in the current directory will be displayed from which you can pick the file to protect."
Help$(5, 1) = "This is the opposite of the previous choice.  You can remove the Read Only status of a file by selecting its name from the menu of files that are displayed."
Help$(7, 1) = "Use this menu item to simulate changing the current drive or directory.  After making this selection, a menu of directory names will be displayed from which you can choose the directory to be made current."
Help$(8, 1) = "Don't panic, this choice does nothing."
Help$(9, 1) = "Temporarily exit to the operating system.  This program stays in memory.  To return, type EXIT."

Help$(1, 2) = "The Colors menu item can be used to change the color of the text displayed on the screen.  After making this choice, a second menu will be displayed allowing you to choose a new Foreground, Background or color Intensity.  "
Help$(1, 2) = Help$(1, 2) + "If you choose Foreground or Background, a third menu will be displayed containing the range of possible colors."
Help$(3, 2) = "This setting is used to change the way text searches could be done.  If this setting is active, searches would ignore capitalization, otherwise words would be found only if they match the case of each letter in the text.  "
Help$(3, 2) = Help$(3, 2) + "Pressing Enter on this choice will toggle between the two modes.  A Check mark is displayed if case insensitivity is active."
Help$(4, 2) = "Due to the laziness of the author of this demo, there is no help for this item."
Help$(6, 2) = Help$(4, 2)

Help$(1, 3) = Help$(4, 2)
Help$(2, 3) = Help$(4, 2)
Help$(3, 3) = Help$(4, 2)
Help$(4, 3) = Help$(4, 2)
Help$(6, 3) = Help$(4, 2)

Help$(1, 4) = Help$(4, 2)
Help$(2, 4) = Help$(4, 2)
Help$(3, 4) = Help$(4, 2)


RESTORE Screentxt                       'read the text we are displaying on
FOR R = 1 TO 26                         '  body of the screen
    READ ScrTxt$(R)
NEXT

CLS                                     'print the text
FOR R = 1 TO 22
    LOCATE R + 2, 1
    CALL MQPrint(ScrTxt$(R), Cnf.NonMen)
NEXT

CALL TextCursor(-2, 4)                  'Inverse foreground red background
CALL SetCursor(1, 1)                    'Locate it at upper right of screen
CALL ShowCursor                         'Turn it on

'*** Paint the screen the default color defined in "Screen.bi"
CALL MPaintBox(1, 1, 25, 80, Cnf.NonMen)

'*** Print the 25th line
LOCATE 25, 1: CALL MQPrint("File: ", 23)
LOCATE 25, 7: CALL MQPrint(SPACE$(12), 112)
LOCATE 25, 62: CALL MQPrint(DATE$, 112)
LOCATE 25, 73: CALL MQPrint(TIME$, 112)
LOCATE 25, 24: CALL MQPrint("F1-Help", 48)
LOCATE 25, 34: CALL MQPrint("PgDn-More", 48)
LOCATE 25, 46: CALL MQPrint("PgUp-Prev.", 48)

Action = 1                              'set Action flag to 1 - init PullDown
Tim! = TIMER                            'init the time

DO
   DO                                   'call the Pull Down menu routine
      CALL PullDown(MMenu$(), Stat(), Menu, Choice, Ky$, Action, Cnf)
 
      GOSUB ShowTime                    'update the time every second
                                        
      IF Ky$ = CHR$(0) + CHR$(59) THEN  'display Help
         GOSUB ShowHelp
      END IF

      IF Ky$ = CHR$(0) + CHR$(81) THEN  'PgDn key pressed
         CALL PullDown(MMenu$(), Stat(), Menu, Choice, Ky$, 5, Cnf)
         Fld$ = SPACE$(79)
         Lca = 3
         FOR R = 23 TO 44
             LSET Fld$ = ScrTxt$(R)
             LOCATE Lca, 1
             Lca = Lca + 1
             CALL MQPrint(Fld$, Cnf.NonMen)
         NEXT
         Action = 1
      END IF

      IF Ky$ = CHR$(0) + CHR$(73) THEN  'PgDn key pressed
         CALL PullDown(MMenu$(), Stat(), Menu, Choice, Ky$, 5, Cnf)
         Fld$ = SPACE$(79)
         Lca = 3
         FOR R = 1 TO 22
             LSET Fld$ = ScrTxt$(R)
             LOCATE Lca, 1
             Lca = Lca + 1
             CALL MQPrint(Fld$, Cnf.NonMen)
         NEXT
         Action = 1
      END IF

   LOOP UNTIL Action = 4                'keep calling PullDown until User
                                        '  makes a selection

   Again = -1                           'default flag to loop again.
   Action = 2                           'default Action flag to redisplay the
                                        '  menu contents
   IF Ky$ = CHR$(27) THEN               'if user pressed escape, exit this
   '  Again = 0                         '  demo (only if REM is removed)
   ELSE                                 'otherwise,
      SELECT CASE Menu                  '  process selection.

         CASE 0                         'help Icon
            GOSUB ShowHelp

         CASE 1                         'File Menu
            SELECT CASE Choice
               CASE 1, 4, 5             'Retrieve, Protect or Unprotect File
                  LOCATE Choice + 2, 32
                  CALL GetFiles("*.*", FilName$, Cnf)
                                        'if user didn't Escape from file routine
                  IF Choice = 1 AND LEN(FilName$) THEN
                     LOCATE 25, 7               'print file name
                     CALL MQPrint(FilName$, 112)
                     Stat(2, 1) = Active        'User can now save his file
                  END IF
               CASE 2                   'Save File
               CASE 7                   'Change Drive
               CASE 8                   'Format Disk
               CASE 9                   'DOS Shell
                  REDIM ScrBuf(2000)
                  CALL MScrnSave(1, 1, 25, 80, ScrBuf(0))
                  CLS
                  LOCATE 25, 1
                  CALL MQPrint("Type EXIT to return to demo.", 2)
                  SHELL
                  CALL MScrnRest(1, 1, 25, 80, ScrBuf(0))
                  ERASE ScrBuf
               CASE ELSE
            END SELECT

         CASE 2                         'Settings Menu
            SELECT CASE Choice
               CASE 1                   'Colors
                  LstClr = Cnf.NonMen   'save the current color attribute
                  CALL GetColor(Cnf)    'show color options, get color
                                        'if user made a choice,
                  Action = 5                 'set to restore screen
                  CALL PullDown(MMenu$(), Stat(), Menu, Choice, Ky$, Action, Cnf)
                                             'paint screen new color
                  IF Cnf.NonMen <> LstClr THEN
                    CALL MPaintBox(1, 1, 24, 80, Cnf.NonMen)
                  END IF
                  Action = 1                 'set to redisplay whole menu
               CASE 3, 4                        'Search options
                  Psn = LEN(MMenu$(Choice, 2))  'get length of choice
                                                'see if its marked
                  Mark$ = MID$(MMenu$(Choice, 2), Psn, 1)
                  IF Mark$ = "û" THEN           'if it is, then unmark it
                     Mark$ = " "
                  ELSE
                     Mark$ = "û"                'otherwise mark it
                  END IF
                  MID$(MMenu$(Choice, 2), Psn) = Mark$
               CASE 6
               CASE ELSE
            END SELECT

         CASE 3                         'Edit Menu
            SELECT CASE Choice
               CASE 1                           'Mark Block
                  Stat(2, 3) = Active           'block can now be cut, copied
                  Stat(3, 3) = Active           '  or moved
                  Stat(4, 3) = Active
               CASE 2                           'Cut Block
                  Stat(2, 3) = Inactive         'once cut, it can't be cut again
               CASE 3                           'Copy
               CASE 4                           'Paste
               CASE 6                           'New File
                  Stat(2, 1) = Active           'make "Save File" active
               CASE ELSE
            END SELECT

         CASE 4                         'Search Menu
            SELECT CASE Choice
               CASE 1                           'Find
                  Stat(2, 4) = Active           'ake Repeat Find active
               CASE 2                           'Repeat Last Find
               CASE 3                           'Change
               CASE ELSE
            END SELECT

         CASE ELSE                      'Quit Program (no choices)
            Again = 0                   'set loop flag to terminate
      END SELECT
   
   END IF

LOOP WHILE Again                        'go back to the PullDown menu unless
                                        '  flag set to terminate
'Restore the Screen
Action = 5
CALL PullDown(MMenu$(), Stat(), Menu, Choice, Ky$, Action, Cnf)

END


'----- Display the apropriate help message
ShowHelp:

   LOCATE 14, 1                         'position the starting line for box
   Wdth = 62                            'set text width
   CALL CSMsgBox(Help$(Choice, Menu), Wdth, Cnf)
   DO UNTIL LEN(INKEY$)
      GOSUB ShowTime                    'Update the time every second
   LOOP
   CALL CSMsgBox("", 1, Cnf)

RETURN



'----- Update the time every second
ShowTime:

   IF TIMER > Tim! + 1 THEN
      Tim! = TIMER
      LOCATE 25, 73
      CALL MQPrint(TIME$, 112)
   END IF

RETURN


MenuStrngs:                             'define the menu choices
DATA "File",                    "Settings",                   "Edit",          "Search",            "Quit"
DATA "Retrieve File...",        "Colors...",                  "Mark Block...", "Find...",           ""
DATA "Save Current File...",    "-",                          "Cut",           "Repeat Last Find",  ""
DATA "-",                       "Ignore upper/lower Case ",   "Copy",          "Change...",         ""
DATA "Protect a File...",       "Match whole word ",          "Paste",         "",                  ""
DATA "Unprotect a file...",     "-",                          "-",             "",                  ""
DATA "-",                       "Margins...",                 "New File",      "",                  ""
DATA "Change Drive/Directory",  "",                           "",              "",                  ""
DATA "Format a Disk",           "",                           "",              "",                  ""
DATA "DOS Shell",               "",                           "",              "",                  ""


Screentxt:
DATA "                    PULLDOWN/VERTMENU Demonstration Program."
DATA ""
DATA "  This demo illustrates some of the things that can be done with the features"
DATA "  and multi-tasking capabilities of the PullDown and VertMenu routines."
DATA ""
DATA "  Notice that menus can have dividing lines to separate a group of choices."
DATA "  This can be accomplished by using a ``-'' as a choice string.  Menu items"
DATA "  can also be made inactive (non selectable) by placing a value in a parallel"
DATA "  array that corresponds to the items string array."
DATA ""
DATA "  Both PullDown and Vertmenu can be used in a multi-tasking (polled) mode."
DATA "  Notice that the time is being displayed and updated at the bottom of the"
DATA "  screen.  This is being done from outside of the two menuing routines.  To"
DATA "  accomplish this you would call the menu routines in the same way you would"
DATA "  use the INKEY$ function in a loop.  A control flag can be used to make the"
DATA "  menus perform certain tasks.  (See subprogram headers for details.)"
DATA ""
DATA "  Notice also that help can be displayed for any menu item.  This is being"
DATA "  done outside of the PullDown menu routine by trapping the F1 key, reading"
DATA "  the Menu and Choice numbers and then displaying the appropriate help message."
DATA "  Another function that is performed outside the menu routine is paging of"
DATA "  this text.  Try the PgDn key to see."
DATA "  Other possible uses for polled menus are background communications or self-"
DATA "  modifying menus.  Examples of a self modifying menu are the ``Ignore Case''"
DATA "  or ``Match Whole Word'' choices from the ``Settings'' Menu, where a check
DATA "  mark is placed to the right of the text on the menu.

SUB GetColor (Cnf AS Config) STATIC

    REDIM Atrib$(3)
    Atrib$(1) = "Foreground "
    Atrib$(2) = "Background"
    Atrib$(3) = "Intensity "
    REDIM Clrs$(8)
    Clrs$(1) = "Black  "
    Clrs$(2) = "Blue"
    Clrs$(3) = "Green"
    Clrs$(4) = "Cyan"
    Clrs$(5) = "Red"
    Clrs$(6) = "Magenta"
    Clrs$(7) = "Brown"
    Clrs$(8) = "White"

    REDIM ScrBuf(2000)
    MScrnSave 1, 1, 20, 80, ScrBuf(0)

    Bkgrnd = Cnf.NonMen \ 16
    Frgrnd = Cnf.NonMen MOD 16
    Intens = -Frgrnd \ 8
    Frgrnd = Frgrnd - ABS(Intens) * 8

    DO
       LOCATE 3, 42
       VertAction = 1
       Tim! = TIMER - 1
       DO
           CALL VertMenu(Atrib$(), Atrb, 10, 24, Ky$, VertAction, Cnf)

           IF TIMER > Tim! + 1 THEN
              Tim! = TIMER
              LOCATE 25, 73
              CALL MQPrint(TIME$, 112)
           END IF
       LOOP UNTIL VertAction = 4

       IF Ky$ = CHR$(13) AND Atrb <> 3 THEN
          LOCATE 9, 42
          VertAction = 1
          IF Atrb = 1 THEN Clr = Frgrnd + 1
          IF Atrb = 2 THEN Clr = Bkgrnd + 1
          Tim! = TIMER - 1

          DO
              CALL VertMenu(Clrs$(), Clr, 7, 24, Ky$, VertAction, Cnf)
              IF TIMER > Tim! + 1 THEN
                 Tim! = TIMER
                 LOCATE 25, 73
                 CALL MQPrint(TIME$, 112)
              END IF
          LOOP UNTIL VertAction = 4

          CALL VertMenu(Clrs$(), Clr, 7, 24, K$, 5, Cnf)
       ELSE
          EXIT DO
       END IF

    LOOP UNTIL Ky$ = CHR$(13)

    IF Ky$ = CHR$(13) THEN
       IF Atrb = 1 THEN Frgrnd = Clr - 1
       IF Atrb = 2 THEN Bkgrnd = Clr - 1
       IF Atrb = 3 THEN Intens = NOT Intens
       Cnf.NonMen = Frgrnd + ABS(Intens) * 8 + 16 * Bkgrnd
    END IF
            
    MScrnRest 1, 1, 20, 80, SEG ScrBuf(0)
    ERASE Atrib$, Clrs$, ScrBuf

END SUB

SUB GetFiles (FileSpec$, FilName$, Cnf AS Config) STATIC

    Count = FCount%(FileSpec$)
    IF Count = 0 THEN EXIT SUB

    FilName$ = ""
    REDIM Fls$(Count)
    FOR N = 1 TO Count
        Fls$(N) = SPACE$(12)
    NEXT
    Fls$(0) = FileSpec$
    ReadFile VARPTR(Fls$(0))            'get the file names

    VertAction = 1
    Tim! = TIMER
    DO
        CALL VertMenu(Fls$(), FlNo, 12, 24, Ky$, VertAction, Cnf)
        IF TIMER > Tim! + 1 THEN
           Tim! = TIMER
           LOCATE 25, 73
           CALL MQPrint(TIME$, 112)
        END IF
    LOOP UNTIL VertAction = 4
    IF Ky$ <> CHR$(27) THEN FilName$ = Fls$(FlNo)

    CALL VertMenu(Fls$(), FlNo, 12, 24, K$, 5, Cnf)

END SUB

