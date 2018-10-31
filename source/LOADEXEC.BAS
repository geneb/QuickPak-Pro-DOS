'********** LOADEXEC.BAS

'Copyright (c) 1991 Ethan Winer

DEFINT A-Z

DECLARE FUNCTION ErrorMsg$ (ErrCode)
DECLARE FUNCTION LoadExec% (FileName$, Param$)
DECLARE FUNCTION SearchPath$ (FileName$)
DECLARE FUNCTION WhichError% ()

FileName$ = "pkzip"                         'I sure hope you have PKZIP!
Param$ = "junk *.not"                       'fail unless *.not matches
Qualified$ = SearchPath$(FileName$)         'create a fully qualified name

IF RIGHT$(Qualified$, 4) = ".BAT" THEN      'here's how to handle batch files
  Param$ = "/C" + Qualified$ + " " + Param$ '/c tells COMMAND.COM to run it
  Qualified$ = ENVIRON$("COMSPEC")          'usually COMSPEC = C:\COMMAND.COM
END IF

ExitCode = LoadExec%(Qualified$, Param$)    'load and execute the program
PRINT

QPErr = WhichError%                         'report what happened
IF QPErr THEN
  PRINT "Error:"; QPErr; ErrorMsg$(QPErr)   'an error

ELSEIF ExitCode <= 255 THEN                 'normal termination
   PRINT "Normal termination with an exit code of"; ExitCode

ELSE                                        'abnormal termination
   DOSCode = ExitCode \ 256                 'isolate DOS's contribution
   ExitCode = ExitCode AND 255              'retain the program's part too
   PRINT "DOS intervened"
   SELECT CASE DOSCode
      CASE 1
         PRINT "You pressed Ctrl-C or Ctrl-Break to end the program"
      CASE 2
         PRINT "A critical error occurred and you pressed A (Abort)"
      CASE 3
         PRINT "The program ended as a TSR -- reboot now!"
      CASE ELSE
   END SELECT
END IF

