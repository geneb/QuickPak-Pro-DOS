'********** DemoSect.Bas - demos the sector reading subprogram

'Copyright (c) 1987 Ethan Winer


'ReadSector is set up as a callable subprogram to simplify adding it
'to your own programs if you'd like.


DEFINT A-Z
DECLARE SUB ReadSector ()

CALL ReadSector

