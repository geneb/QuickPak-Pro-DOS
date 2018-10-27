'******** FORMAT.BAS - demonstrates GetDisketteType and FormatDiskette

'Copyright (c) 1992 Crescent Software


DEFINT A-Z
DECLARE FUNCTION GetDisketteType% (Drive)
DECLARE FUNCTION FormatDiskette% (Drive, Capacity, SEG Buffer)

DIM Typ$(0 TO 4)
Typ$(0) = "No physical floppy or cannot identify"
Typ$(1) = "360K 5.25-inch drive"
Typ$(2) = "1.2M 5.25-inch drive"
Typ$(3) = "720K 3.5-inch drive"
Typ$(4) = "1.44M 3.5-inch drive"

PRINT "A: "; Typ$(GetDisketteType%(0))
PRINT "B: "; Typ$(GetDisketteType%(1))
PRINT "C: "; Typ$(GetDisketteType%(2))
PRINT "D: "; Typ$(GetDisketteType%(3))
PRINT "E: "; Typ$(GetDisketteType%(4))
PRINT

REDIM Buffer(1 TO 2340)    '2340 is big enough for the largest drive type

INPUT "Enter drive number to format (A=0, B=1) or Enter to quit: ", Drive$
IF LEN(Drive$) = 0 THEN END
Drive = VAL(Drive$)
PRINT

INPUT "Enter capacity (360, 1200, 720, 1440): ", Capacity
PRINT
PRINT "Formatting...."

Result = FormatDiskette%(Drive, Capacity, Buffer(1))

SELECT CASE Result
  CASE 0: PRINT "No error"
  CASE 1: PRINT "Invalid disk parameters"
  CASE 2: PRINT "Address mark not found"
  CASE 3: PRINT "Write protect error"
  CASE 4: PRINT "Requested sector not found"
  CASE 5: PRINT "Can't locate drive"
  CASE 6: PRINT "Disk change line is active"
  CASE 7: PRINT "Invalid capacity specified"
  CASE 8: PRINT "DMA Overrun"
  CASE 9: PRINT "DMA boundary error"
  CASE 10: PRINT "Track zero bad"
  CASE 11       'bad clusters were found (not fatal), report that
    CALL DiskInfo(CHR$(Drive + 65), Bytes, Sectors, FreeClusts, TotalClusts)
    BadClusts = TotalClusts - FreeClusts
    BadBytes& = CLNG(BadClusts) * Sectors * Bytes
    PRINT BadBytes&; "bytes were marked as being unusable"
  CASE 12: PRINT "Media type not found"
  CASE 16: PRINT "CRC read error"
  CASE 32: PRINT "Disk controller failure"
  CASE 64: PRINT "Seek failure"
  CASE 128: PRINT "Drive not ready"
END SELECT

