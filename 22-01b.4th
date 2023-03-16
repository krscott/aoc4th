s" input/22-01.txt" r/o open-file throw Value fd

256 Constant line-size
Create line-buf line-size 2 + allot

: take-line ( -- n-len f-not-eof )
  line-buf line-size fd read-line throw ;

: take-n ( -- n-number f-not-eof )
  take-line swap dup 0<>
    if line-buf swap s>number? 2drop
    then
  swap ;

: input-to-stack ( -- n... )
  begin take-n while repeat ;

: drop-zeroes ( 0... -- )
  begin dup 0= while drop repeat ;

: bag-sum ( 0 n... -- sum )
  0 >r
  begin dup 0<>
    while r> + >r
    repeat
  drop r> ;

: bubble ( n[len] len -- n[len] )
  rot rot       ( ... len na nb )
  2dup >        ( ... len na nb na>nb? )
  if swap then  ( ... len n-small n-big )
  >r swap 1-    ( ... n-small len-1 | R: n-big )
  dup 1 >       ( ... n-small len-1 len-1>1? | R: n-big )
  if recurse else drop then
  r> ;

: largest-3-bags ( 0 0 n... -- bag1 bag2 bag3 )
  0 >r 0 >r 0 >r  \ top 3 bags
  begin bag-sum dup 0<>   ( ... new-bag new-bag=0? r: bag3 bag2 bag1 )
    while
      r> r> r> 3 pick     ( ... new-bag bag1 bag2 bag3 new-bag )
      4 bubble            ( ... new-bag bag0' bag1' bag2' bag3' )
      >r >r >r drop drop  ( ... r: bag3' bag2' bag1' )
    repeat                ( 0 )
  drop r> r> r>           ( bag1 bag2 bag3 )
  ;

0 0
input-to-stack
drop-zeroes

largest-3-bags
+ + . cr

bye
