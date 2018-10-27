'********** DiskInfo.Bas - shows how to get full information about a disk

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE SUB DiskInfo (Drive$, Bytes, Sectors, FreeClusters, TotalClusters)
DECLARE FUNCTION GoodDrive% (Drive$)
DECLARE FUNCTION GetDrive% ()

CLS
INPUT "Enter the drive to check, or press Enter for the default drive: ", Drive$
IF Drive$ = "" THEN Drive$ = CHR$(GetDrive%)
PRINT

IF GoodDrive%(Drive$) THEN
   DiskInfo Drive$, Bytes, Sectors, FreeClusters, TotalClusters
   PRINT "Drive "; Drive$; " has"; Sectors; "sectors per cluster, ";
   PRINT "and each sector holds"; Bytes; "bytes."
   PRINT "There are a total of"; CLNG(TotalClusters) * Sectors; "sectors, ";
   PRINT "of which"; CLNG(FreeClusters) * Sectors; "sectors are free."
ELSE
   PRINT Drive$; " is an invalid drive"
END IF

