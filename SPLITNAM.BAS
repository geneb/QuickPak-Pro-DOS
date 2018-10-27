'********* SPLITNAM.BAS

DEFINT A-Z
DECLARE SUB SplitName (TestName$, Drive$, Path$, FileName$, Extension$)
DECLARE SUB SN (TestName$, Drive$, Path$, FileName$, Extension$)
DECLARE FUNCTION GetDir$ (Drive$)
DECLARE FUNCTION GetDrive% ()

TestName$ = "C:\MYPATH\YOURPATH\MYFILE.EXT"
CALL SplitName(TestName$, Drive$, Path$, FileName$, Extension$)

CLS
PRINT "Original name: "; TestName$
PRINT
PRINT "Drive: "; Drive$
PRINT " Path: "; Path$
PRINT " Name: "; FileName$
PRINT "  Ext: "; Extension$
PRINT
PRINT "Reconstructed: "; Drive$; Path$; FileName$; Extension$

