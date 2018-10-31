'********** Stuffbuf.Bas - demonstrates stuffing the keyboard buffer

'Copyright (c) 1989 Ethan Winer


'IMPORTANT: Do not run this program from within the QuickBASIC editor.
'
'This program illustrates the steps needed to execute a batch file from
'within a QuickBASIC program.  In many cases, this will be preferrable
'to using the SHELL command to run other programs.  When SHELL is used
'your entire program (and its variables and arrays) is still in memory,
'which leaves that much less available to the program being shelled to.
'
'Of course, the only way to get StuffBuf to run a batch file is to end
'your program.  Then, the last command in the batch file will start the
'program again.  When SHELL is used, your program will resume at the
'next statement.  However, to simulate this with a batch file, you must
'pass a command line argument to your program, and then use GOTO to get
'to the proper point to resume execution.  This is shown below.


IF COMMAND$ = "10" GOTO 10      'allows resuming the BASIC program anywhere

OPEN "Go.Bat" FOR OUTPUT AS #1
   PRINT #1, "Echo Off"
   PRINT #1, "Cls"
   PRINT #1, "Echo This is a running batch file"
   PRINT #1, "Pause"
   PRINT #1, "StuffBuf 10";     'run this demo again, pass "10" to COMMAND$
CLOSE                           'NOTE: the final semicolon is very important

Argument$ = "Go" + CHR$(13)     'this simulates running the batch file
CALL StuffBuf(Argument$)        'you could also CALL StuffBuf("Go" + CHR$(13))
END                             'end the program to make it work

10 PRINT "The program resumed here at line 10"
   KILL "Go.Bat"

