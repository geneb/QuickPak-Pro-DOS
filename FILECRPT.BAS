'******** FileCrpt.Bas - encrypts a file with a password

'Copyright (c) 1988 Ethan Winer

'IMPORTANT: Do NOT forget your password!


DEFINT A-Z
DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION Exist% (FileName$)
DECLARE FUNCTION FLof& (Handle)
DECLARE SUB Encrypt (Secret$, PassWord$)
DECLARE SUB FClose (Handle)
DECLARE SUB FGet (Handle, Destination$)
DECLARE SUB FOpen (FileName$, Handle)
DECLARE SUB FPut (Handle, Source$)
DECLARE SUB FSeek (Handle, Offset&)

'********** FileCrpt.Bas - encrypts and decrypts files using a password
'
'Copyright (c) 1987 Ethan Winer
'
SUB FileCrypt (FileName$, PWord$) STATIC

    PassWord$ = PWord$                  'don't actually change the password
    Encrypt PassWord$, "ΔA2ρή,"         'double encrypt the password copy
    L = LEN(PassWord$)                  'remember the length of PassWord$

    FOpen FileName$, Handle             'open the file for QuickPak binary
    IF DOSError% THEN EXIT SUB          'it's not there or drive door is open

    FileSize& = FLof&(Handle)           'find how long the file is
    BufSize = 4096                      '4096 evenly holds four sectors
    IF FileSize& < BufSize THEN         'but we can't use more than FileSize&
       BufSize = FileSize&              'so use that instead
    END IF

    BufSize = BufSize - (FileSize& MOD L)       'LEN(Buffer$) must be an even
                                                '  multiple of LEN(PassWord$)
    IF BufSize = 0 THEN                         'it's a very small file, use
       BufSize = FileSize&                      '  FileSize& instead
    END IF

    Buffer$ = SPACE$(BufSize)           'create a buffer to hold the file
    Done& = 0                           'Done& tracks how much we've done

DO
    FGet Handle, Buffer$                'get this portion of the file
    Encrypt Buffer$, PassWord$          'encrypt it
    FSeek Handle, Done&                 'seek back to the start of this block
    FPut Handle, Buffer$                'write out the encrypted data
    Done& = Done& + LEN(Buffer$)        'track what we've already done

    IF FileSize& - Done& < LEN(Buffer$) THEN   'less than LEN(Buffer$) remains
       Buffer$ = ""                            'this shouldn't be necessary
       Buffer$ = SPACE$(FileSize& - Done&)     'adjust buffer to what remains
    END IF

LOOP WHILE LEN(Buffer$) AND NOT DOSError%      'loop while there's still more to do
                                               '  and no errors have occurred
    FClose Handle                              'close the file

END SUB                                        'see ya later, oscillator

