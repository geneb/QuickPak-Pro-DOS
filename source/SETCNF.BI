DIM Cnf AS Config

CALL InitMouse(Cnf.Mouse)

Cnf.MonTyp = Monitor

ClrDisp% = Cnf.MonTyp = 3 OR (Cnf.MonTyp >= 5 AND Cnf.MonTyp <= 9) OR Cnf.MonTyp = 11
IF INSTR(COMMAND$, "/B") THEN ClrDisp% = 0

IF ClrDisp% THEN
   Cnf.PulBar = 48
   Cnf.MenBox = 49
   Cnf.ActivCh = 48
   Cnf.InActCh = 52
   Cnf.HiLite = 31
   Cnf.InActHiLt = 64
   Cnf.NonMen = 30
ELSE
   Cnf.PulBar = 112
   Cnf.MenBox = 112
   Cnf.ActivCh = 112
   Cnf.InActCh = 112
   Cnf.HiLite = 15
   Cnf.InActHiLt = 80
   Cnf.NonMen = 7
END IF

IF Cnf.MonTyp >= 3 AND Cnf.MonTyp <= 5 THEN
   Cnf.CurSize = 7
ELSE
   Cnf.CurSize = 12
END IF

