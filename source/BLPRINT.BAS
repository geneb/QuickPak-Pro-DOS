'********** BLPRINT.BAS - BASIC LPrint substitute eliminates ON ERROR

'Copyright (c) 1988 Ethan Winer


'This program demonstrates three routines: PRNReady which tests if a printer
'is on-line and available, BLPrint which sends text to the printer directly
'through the BIOS, and PrinterReady which is a BASIC "wrapper" for PRNReady.
'
'PRNReady requires a printer number to test (1 - 3), and it returns a status
'of either -1 (ready) or 0 (not ready).  Unlike earlier versions of PRNReady
'that relied on a BIOS service to test the printer, this version actually
'attempts to send two characters - a space and a backspace - and reports if
'the printing was successful.  Because many printer manufacturers have not
'standardized on the usage of the various printer status bits, this is the
'only way to tell for certain if a printer is ready.
'
'PRNReady begins by sending a CHR$(32) space to the specified printer.  If
'it successful, a backspace is printed to "undo" the forward space.  Most
'of the current PC clones have a BIOS that tries for a long enough time, but
'some computers do not wait long enough for a form-feed to complete before
'reporting a time-out.  In that case, PRNReady would report the printer as
'not ready, even though it is.  Comments in the assembler source code show
'how to modify it to try twice before giving up and reporting an error.  Note
'that PRNReady is not actually called by this demonstration program.  Rather,
'PrinterReady is used to minimize the time-out delay (see below).  To use the
'PrinterReady function in your own programs, simply copy it from this demo.
'
'BLPrint replaces BASIC's LPRINT command, and requires three arguments - a
'printer number (1-3), the string to print, and an error/counter variable.
'Because BLPrint goes directly to the printer, BASIC does not get a chance
'to add a carriage return or line feed to the string.  You must do this in
'your BASIC program.  Of course, this also provides greater control over
'how the text is printed.

'For example, if you add only a CHR$(13) return, then the print head will be
'returned to the beginning of the line, without advancing to the next line.
'This allows you to overstrike characters or easily perform underlining and
'bold printing without having to know those codes for the particular printer.
'
'If the line was printed successfully, BLPrint returns -1 as a status code.
'Any other value indicates the number of characters that were actually
'printed, which allows you to resume printing at the correct place.  In the
'tests I performed, most printers I tried printed either the entire line
'or nothing at all.  That is, de-selecting the printer in the middle of a
'line still was not detected until the line was finished.  However, because
'some printers do not work this way, you should use RIGHT$ as shown below in
'case only part of the line was printed.
'
'PrinterReady uses PRNReady to do the real work, but it first Pokes a small
'time-out value into low memory.  The BIOS in most computers waits for many
'seconds before returning with a time-out error.  For example, a DELL PC we
'have here at Crescent takes 2 full minutes before returning "not ready".


DEFINT A-Z

DECLARE FUNCTION PRNReady% (LPTNo)              'assembly language function
DECLARE FUNCTION Peek1% (Segment, Address)      'assembly language function
DECLARE FUNCTION PrinterReady% (LPTNo)          'BASIC function
DECLARE SUB BLPrint (LPTNo, X$, ErrCount)       'assembly language subroutine
DECLARE SUB Poke1 (Segment, Address, Value)     'assembly language subroutine

CLS
LPTNo = 1                               'printer to test (LPT1:)
Lines = 50                              'number of times to print test message

X$ = "This message demonstrates how PRNReady and BLPrint trap printer errors"

DO
  Ready = PrinterReady%(LPTNo)          'first test the printer
  IF NOT Ready THEN
    PRINT "Printer not ready - press any key to resume, Esc to cancel";
    PLAY "L32O3EC"
    K$ = INPUT$(1)
    IF K$ = CHR$(27) THEN END
    CLS
  END IF
LOOP UNTIL Ready


FOR X = 1 TO Lines                      'print test message a bunch of times
  Work$ = X$ + CHR$(13) + CHR$(10)      'add a CR/LF to the line
  DO
    BLPrint LPTNo, Work$, Er            'print the test message
    IF Er <> -1 THEN                    'anything but -1 means error
      PLAY "L32O3EC"
      PRINT "Printer not ready - press any key to resume, Esc to cancel";
      WHILE INKEY$ <> "": WEND
      K$ = INPUT$(1)
      IF K$ = CHR$(27) THEN END
      CLS                               'calculate how much to re-print
      Work$ = RIGHT$(Work$, LEN(Work$) - Er)
    END IF
  LOOP UNTIL Er = -1
NEXT

FUNCTION PrinterReady% (LPTNo) STATIC

   RetryAddr = &H477 + LPTNo                    'Calculate BIOS Retry address
   SaveRetries = Peek1%(Zero, RetryAddr)        'Save the current setting
   CALL Poke1(Zero, RetryAddr, 1)               'Set to 1 retry, never use 0!
   PrinterReady% = PRNReady%(LPTNo)             'Check the printer
   CALL Poke1(Zero, RetryAddr, SaveRetries)     'Restore the original Retry

END FUNCTION

