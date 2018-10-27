'********** GETCMOS.BAS - shows how to read data from AT-compatible CMOS RAM

'Copyright (c) 1991 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION GetCPU% ()                     'QuickPak Pro routines
DECLARE SUB QPCli ()
DECLARE SUB QPSti ()

DECLARE FUNCTION ReadCMOS% (Address%)           'BASIC functions in this demo
DECLARE FUNCTION Two2One% (LoByte%, HiByte%)


'----- These are the CMOS memory addresses
CONST Diskette = 16                     'the diskettes byte (drives A and B)
CONST HardDisk = 18                     'the hard disk types
CONST Equipment = 20                    'the CMOS equipment list
CONST LowRam = 21                       'stored in 21 and 22 together
CONST HiRam = 23                        'stored in 23 and 24 together
CONST Extended = 25                     'extended info for HD 1, 26 for HD 2
CONST Century = 50                      'the first two digits of the year


CLS
IF GetCPU% < 286 THEN
  PRINT "This program requires an 80286 or better PC."
  END
END IF


Diskettes = ReadCMOS%(Diskette)         'read diskette types
Disk1 = Diskettes \ 16                  'disk 1 is in the high nybble
Disk2 = Diskettes AND 15                'disk 2 is in the low nybble
FOR X = 1 TO 2                          'clever way to use one block of code
  PRINT "      Diskette"; X; ": ";       '  twice for two variables
  SELECT CASE Disk1
    CASE 0
      PRINT "Not installed"
    CASE 1
      PRINT "5-1/4 inch 360K"
    CASE 2
      PRINT "5-1/4 inch 1.2MB"
    CASE 3
      PRINT "3-1/2 inch 720K"
    CASE 4
      PRINT "3-1/2 inch 1.44MB"
    CASE ELSE
      PRINT "Invalid drive type!"
  END SELECT
  SWAP Disk1, Disk2                     'here's the clever part...
NEXT



HardDisks = ReadCMOS%(HardDisk)         'read hard disk types
Disk1 = HardDisks \ 16                  'disk 1 is in the high nybble
Disk2 = HardDisks AND 15                'disk 2 is in the low nybble
FOR X = 1 TO 2                          'clever way to use one block of code
  PRINT "     Hard Disk"; X; ": ";       '  twice for two variables
  SELECT CASE Disk1
    CASE 0
      PRINT "Not installed";
      IF X = 1 THEN PRINT " or PS/2";
    CASE 15
      PRINT "Extended type";
      PRINT ReadCMOS%(Extended + X - 1);
    CASE ELSE
      PRINT "Type"; Disk1;
  END SELECT
  SWAP Disk1, Disk2                     'as above with the floppy disks
  PRINT
NEXT



PRINT "      Low Memory :";
LowMem = Two2One%(ReadCMOS%(LowRam), ReadCMOS%(LowRam + 1))
PRINT LowMem; "K"

PRINT "     High Memory :";
HiMem = Two2One%(ReadCMOS%(HiRam), ReadCMOS%(HiRam + 1))
PRINT HiMem; "K"

PRINT "    Total Memory :"; LowMem + HiMem; "K"



Equip = ReadCMOS%(Equipment)
PRINT "   Floppy drives :";
IF Equip AND 1 THEN
  PRINT ((Equip AND 192) \ 64) + 1;
ELSE
  PRINT " Not ";
END IF
PRINT "installed"

PRINT "Math coprocessor : ";
IF (Equip AND 2) = 0 THEN PRINT "Not ";
PRINT "installed"

PRINT "    Display type : ";
Display = (Equip AND 48) \ 16
SELECT CASE Display
  CASE 0
    PRINT "EGA/VGA/XGA with its own BIOS"
  CASE 1
    PRINT "CGA adapter in 40-column mode"
  CASE 2
    PRINT "CGA adapter in 80-column mode"
  CASE 3
    PRINT "Monochrome adapter"
END SELECT

FUNCTION ReadCMOS% (Address) STATIC

  CALL QPCli                'disable interrupts for a moment
  OUT 112, Address          'to read the CMOS send the address to port 112
  Dummy = -1                'slight pause gives the hardware time to settle
  ReadCMOS% = INP(113)      'then read that address using INP from port 113
  CALL QPSti                'reenable interrupts ASAP

END FUNCTION

FUNCTION Two2One% (LoByte, HiByte) STATIC

  Two2One% = LoByte + (256 * HiByte)    'combine Lo and Hi to one word

END FUNCTION

