s" input/22-04.txt" r/o open-file throw Value fd

30 Constant line-size
Create buf line-size 2 + allot

: take-line ( -- )
  buf line-size fd read-line throw drop  ( len )
  \ add 0 sentinel value
  0 swap buf + ! ;                       ( )

: parse-decimal ( buf -- n buf' )
  0 >r
  begin                                   ( buf       | r: acc )
    dup c@                                ( buf char  | r: acc )
    dup [char] 0 >= over [char] 9 <= and
  while
    [char] 0 -                            ( buf digit | r: acc )
    r> 10 * + >r                          ( buf       | r: acc )
    1+
  repeat
  drop r> swap ;                          ( acc buf )

: split-nums ( buf -- n n n n )
  parse-decimal 1+
  parse-decimal 1+
  parse-decimal 1+
  parse-decimal drop ;

: a-includes-b ( a0 a1 b0 b1 -- f )
  3 pick 2 pick <=
  3 pick 2 pick >=
  and ;

: is-subset ( a0 a1 b0 b1 -- f )
  a-includes-b >r       ( a0 a1 b0 b1 | r: fab )
  2swap a-includes-b >r ( b0 b1 a0 a1 | r: fab fba )
  2drop 2drop           (             | r: fab fba )
  r> r> or ;            ( f )

: count-subsets ( -- n )
  0
  begin                       ( n )
    take-line                 ( n )
    buf c@ 0<>                ( n buf[0]<>0? )
  while                       ( n )
    buf split-nums is-subset  ( n f )
    if 1+ then                ( n' )
  repeat ;

count-subsets
. cr

bye