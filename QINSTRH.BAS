'********* QINSTRH.BAS - demonstrates QInstrH to find data anywehere in a PC

DEFINT A-Z

DECLARE FUNCTION FullAdr& (Segment, Address)
DECLARE FUNCTION GetString$ (Segment, Address, NumBytes)
DECLARE FUNCTION QPSSeg% (Work$)

DECLARE SUB BCopy (FromSeg, FromAdr, ToSeg, ToAdr, NumBytes, Direction)
DECLARE SUB QInstrH (Segment, Address, Search$, NumBytes&)
DECLARE SUB QPrint0 (Work$, Colr)

Segment = 0                     'start searching at segment zero
Address = 0                     'and address zero in that segment
Search$ = "Copyright"           'all computers have this somewhere in memory
NumBytes& = -1                  'search all of memory (QInstrH stops at 1MB)

StringSeg = QPSSeg%(Search$)    'so we can skip all the junk copies that are
Bottom& = FullAdr&(StringSeg, 0)'  created in BASIC's memory by GetString$
Top& = Bottom& + 65535          'define bounds of BASIC's string data segment

CLS
DO
  CALL QInstrH(Segment, Address, Search$, NumBytes&)  'search memory
  IF Segment OR Address THEN                          'if either is non-zero
    ThisFull& = FullAdr&(Segment, Address)            'and not in BASIC's
    IF ThisFull& < Bottom& OR ThisFull& > Top& THEN   '  string data segment
      PRINT "Found at segment "; HEX$(Segment); ", address "; HEX$(Address);
      PRINT TAB(38);
      CALL QPrint0(GetString$(Segment, Address, 43), 7)
      PRINT
    END IF
    Address = Address + 1
  END IF
LOOP WHILE Segment OR Address   'until Segment and Address are both zero

FUNCTION FullAdr& (Segment, Address) STATIC

'This function creates a full, linear address from segment and address parts

  Temp& = Segment
  IF Temp& < 0 THEN Temp& = Temp& + 65536
  Temp& = Temp& * 16 + Address
  FullAdr& = Temp&

END FUNCTION

FUNCTION GetString$ (Segment, Address, NumBytes) STATIC

  Work$ = SPACE$(NumBytes)
  CALL BCopy(Segment, Address, QPSSeg%(Work$), SADD(Work$), NumBytes, Zero)
  GetString$ = Work$
  Work$ = ""                  'free up the memory

END FUNCTION

