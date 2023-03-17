s" input/22-03.txt" r/o open-file throw Value fd

100 Constant line-size
Create bufa line-size 2 + allot
Create bufb line-size 2 + allot
Create bufc line-size 2 + allot

: take-line ( addr -- len )
  line-size fd read-line throw drop ;

: char>priority ( c -- n )
  dup [char] a <
    if [char] A - 27 +
    else [char] a - 1 +
    then ;

: contains? ( c buf len -- f )
  dup 0=                    ( c buf len len=0 )
    if 2drop drop false     ( 0 )
    else                    ( c buf len )
      2dup + 1- c@          ( c buf len buf[len-1]@ )
      3 pick =              ( c buf len buf@=c )
        if 2drop drop true  ( -1 )
        else 1- recurse     ( f )
        then
    then ;

: find-triplet ( bufa lena bufb lenb bufc lenc -- c )
  dup 0= throw              ( bufa lena bufb lenb bufc lenc )
  2dup + 1- c@ dup          ( bufa lena bufb lenb bufc lenc c c | c = bufc[lenc-1]@ )
  7 pick 7 pick             ( bufa lena bufb lenb bufc lenc c c bufa lena )

  contains?                 ( bufa lena bufb lenb bufc lenc c f )
    if
      dup 5 pick 5 pick     ( bufa lena bufb lenb bufc lenc c c bufb lenb  )
      contains?             ( bufa lena bufb lenb bufc lenc c f )
    else 0                  ( bufa lena bufb lenb bufc lenc c 0 )
    then

  if                        ( bufa lena bufb lenb bufc lenc c f )
    >r 2drop 2drop 2drop r> ( c )
    else                    ( bufa lena bufb lenb bufc lenc c )
      drop 1-               ( bufa lena bufb lenb bufc lenc-1 )
      recurse               ( c )
    then ;

: triplets-sum ( -- n )
  0
  begin
      bufa dup take-line
      bufb dup take-line
      bufc dup take-line  ( sum bufa lena bufb lenb bufc lenc )
      dup
    while
      find-triplet        ( sum c )
      char>priority +     ( sum )
    repeat
  2drop 2drop 2drop ;     ( sum )

triplets-sum
. cr

bye
