s" input/22-03.txt" r/o open-file throw Value fd

100 Constant line-size
Create line-buf line-size 2 + allot

: take-line ( -- len )
  line-buf line-size fd read-line throw drop ;

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

: find-pair ( bufa lena bufb lenb -- c )
  dup 0= throw            ( bufa lena bufb lenb )
  2dup + 1- c@ dup        ( bufa lena bufb lenb c c | c = bufb[lenb-1]@ )
  5 pick 5 pick           ( bufa lena bufb lenb c c bufa lena )
  contains?               ( bufa lena bufb lenb c f )
    if >r 2drop 2drop r>  ( c )
    else                  ( bufa lena bufb lenb c )
      drop 1-             ( bufa lena bufb lenb-1 )
      recurse             ( c )
    then ;

: split ( buf len -- buf len/2 buf+len/2 len/2 )
  2/ 2dup   ( buf len/2 buf len/2 )
  + over ;  ( buf len/2 buf+len/2 len/2 )

: pairs-sum ( -- n )
  0
  begin take-line dup     ( sum len len )
    while                 ( sum len )
      line-buf swap split ( sum buf len/2 buf+len/2 len/2 )
      find-pair           ( sum c )
      char>priority +     ( sum )
    repeat
  drop ;                  ( sum )

pairs-sum
. cr

bye
