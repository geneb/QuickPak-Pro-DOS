'******** DemoPick.Bas - demos PickList

'Copyright (c) 1988 Crescent Software
'written by Don Malin

DEFINT A-Z

DECLARE SUB PickList (Items$(), Picked%(), NPicked%, Cnf AS ANY)
DECLARE SUB ReadFile (BYVAL Address)
DECLARE FUNCTION FCount% (FileSpec$)
DECLARE FUNCTION MinInt% (Var1%, Var2%)
DECLARE FUNCTION Monitor% ()            'Used in SetCnf.Bi

'$INCLUDE: 'DefCnf.BI'
'$INCLUDE: 'SetCnf.BI'


'----- Read a directory of the disk
NFiles = FCount%("*.*")                 'Find the number of files
REDIM Items$(NFiles)                    'Dim the "Items$" array
Items$(0) = "*.*"                       'Put file spec. in element 0
FOR N = 1 TO NFiles                     'Pad elements to 12 for names
    Items$(N) = SPACE$(15)              '  plus 3 for check marks
NEXT
ReadFile VARPTR(Items$(0))              'Get the file names


'----- Set up the "Picked" array
MaxNum = MinInt%(10, NFiles)            'Allow 10 items to be picked
REDIM Picked(MaxNum)                    'Dim the array


'----- Print instructions
CLS
LOCATE , , 0                            'Turn the cursor off
PRINT "Choose up to"; MaxNum; "files.  Press [Esc] when done."
PRINT

CALL TextCursor(-2, -2)                 'set mouse colors to inverse
CALL ShowCursor                         'Turn it on


'----- Let the User pick file names
PickList Items$(), Picked(), NPicked, Cnf
CALL HideCursor                         'Turn the Mouse cursor off


'----- Show what they picked
LOCATE 3, 1                             'Print message on line 3
IF NPicked THEN
   PRINT "You picked the following files:"
   FOR N = 1 TO NPicked                 'Print each file name picked
       LOCATE , 33                                 'Picked% holds the element
       PRINT CHR$(34); Items$(Picked(N)); CHR$(34) 'number in the Items$ array
   NEXT
ELSE
   PRINT "No items selected."
END IF

