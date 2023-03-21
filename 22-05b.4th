s" input/22-05.txt" r/o open-file throw Value fd

100 constant line-size
create line-buf line-size 2 + allot

50 constant crate-stack-size

: take-line ( -- addr len )
  line-buf dup line-size fd read-line 2drop
;

: next-char ( addr len -- addr2 len2 c )
  dup 0> if
    over c@     ( addr len c )
    rot 1+      ( len c addr2 )
    rot 1-      ( c addr2 len2 )
    rot         ( addr2 len2 c )
  else
    0           ( addr len 0 )
  endif
;

: skip-whitespace ( addr len -- addr len )
  begin
    dup 0= if exit endif
    over c@                 ( addr len c )
    dup 0= if exit endif
    bl <> if exit endif
    1- swap 1+ swap         ( `addr+1` `len-1` )
  again
;

: next-token ( addr len -- rest restlen tok toklen )
  skip-whitespace
  over 0                        ( addr len addr 0 )
  begin                         ( rest restlen tok toklen )
    2 pick 0= if exit endif
    3 pick c@                   ( rest restlen tok toklen c )
    dup 0= if exit endif        \ exit if nul
    bl = if exit endif          \ exit if whitespace
    >r >r >r                    ( rest | r: toklen tok restlen )
    1+ r> 1- r> r> 1+           ( `rest+1` `restlen-1` tok `toklen+1` )
  again
;

: parse-decimal ( buf len -- n )
  0 -rot            ( acc buf len )
  0 do              ( acc buf )
    dup c@ '0' -    ( acc buf digit )
    rot 10 * + swap ( acc buf )
    1+
  loop
  drop
;

: fixlist-new ( capacity -- 'self | self = len capacity n...  )
  align
  here 0 , over ,     ( capacity 'self )
  swap cells allot    ( 'self )
;
: fixlist-len ( 'self -- len ) @ ;
: fixlist-capacity ( 'self -- capacity ) 1 cells + @ ;
: fixlist-is-full ( 'self -- f )
  dup fixlist-len swap fixlist-capacity >=
;

: fixlist-slice ( 'self -- addr len )
  dup @                 ( 'self len )
  swap 2 cells + swap   ( addr len )
;

: fixlist-at ( index 'self -- addr )
  over 0< abort" fixlist negative index"
  fixlist-slice                                 ( index addr len )
  2 pick <= abort" fixlist index out of range"  ( index addr )
  swap cells +
;
: fixlist-get ( index 'self -- n ) fixlist-at @ ;
: fixlist-set ( n index 'self -- ) fixlist-at ! ;

: fixlist-last ( 'self -- n )
  dup fixlist-len 1- swap fixlist-get
;

: fixlist-push ( n 'self -- )
  dup fixlist-is-full abort" fixlist overflow"
  swap over       ( 'self n 'self )
  fixlist-slice   ( 'self n addr len )
  cells + !       ( 'self )
  1 swap +!       ( ) \ increment len
;

: fixlist-pop ( 'self -- n )
  dup fixlist-len 0<= abort" fixlist underflow"
  dup fixlist-len 1- over   ( 'self `len-1` 'self )
  fixlist-get               ( 'self n )
  -1 rot +!                 ( n )  \ decrement len
;

: fixlist-unshift ( n 'self -- )
  dup fixlist-is-full abort" fixlist overflow"
  dup                     ( n 'self 'self )
  fixlist-slice           ( n 'self addr len )
  over 1 cells + swap     ( n 'self addr 'addr[1] len )
  cells cmove>            ( n 'self )
  dup 1 swap +!           ( n 'self ) \ increment len
  0 swap fixlist-set      ( ) \ set first element
;

: fixlist-pop-slice ( len 'self -- addr len )
  2dup fixlist-len > abort" fixlist-pop-slice len too big"
  2dup swap negate        ( len 'self 'self `-len` )
  swap +!                 ( len 'self ) \ reduce len
  fixlist-slice cells +   ( len addr )
  swap                    ( addr len )
;

: fixlist-push-slice ( addr len 'self -- )
  swap 0 do             ( addr 'self )
    over i cells + @    ( addr 'self n )
    over fixlist-push   ( addr 'self )
  loop
  2drop                 ( )
;

: fixlist-emit ( 'self -- )
  dup fixlist-len 0> if
    fixlist-slice 0 do
      dup i cells + @ emit
    loop
  endif
  drop
;

\ ( test fixlist )
\ crate-stack-size fixlist-new
\ 'A' over fixlist-push
\ 'B' over fixlist-push
\ 'C' over fixlist-push


: crates-new ( len -- 'self )
  fixlist-new                     ( 'self )
  dup fixlist-capacity 0 do       ( 'self )
    crate-stack-size fixlist-new  ( 'self 'list )
    over fixlist-push             ( 'self )
  loop
;

: crates-emit ( 'self -- )
  cr
  fixlist-slice 0 do
    i 1+ .
    dup i cells + @
    fixlist-emit cr
  loop
  drop cr
;

: crates-push-line ( 'line len 'self -- )
  -rot 1 do             ( 'self 'line )
    dup i + c@          ( 'self 'line c )
    dup bl <> if
      i 4 / 3 pick      ( 'self 'line c index 'self )
      fixlist-get       ( 'self 'line c 'list )
      fixlist-unshift   ( 'self 'line )
    else
      drop
    endif
  4 +loop
  2drop
;

: crates-push-lines ( 'self -- )
  begin
    take-line                 ( 'self 'line len )
    over 1+ c@ '1' <>
  while                       ( 'self 'line len )
    2 pick crates-push-line   ( 'self )
  repeat
  2drop drop
;

: crates-exec-move ( 'line len 'self -- )
  -rot                              ( 'self 'line len )

  next-token 2drop                  \ "move"
  next-token parse-decimal -rot     ( 'self amt 'line len )
  next-token 2drop                  \ "from"
  next-token parse-decimal 1- -rot  ( 'self amt src 'line len )
  next-token 2drop                  \ "to"
  next-token parse-decimal 1- -rot  ( 'self amt src dest 'line len )

  2drop -rot                        ( 'self dest amt src )
  3 pick fixlist-get                ( 'self dest amt 'srclist )
  fixlist-pop-slice                 ( 'self dest srcaddr srclen )
  2 pick 4 pick fixlist-get         ( 'self dest srcaddr srclen 'destlist )
  fixlist-push-slice                ( 'self dest )
  2drop                             ( )
;

: crates-exec-all ( 'self -- )
  begin
    take-line dup 0>
  while                       ( 'self 'line len )
    \ cr .s cr
    \ 2 pick crates-emit
    \ 2dup type cr

    2 pick crates-exec-move   ( 'self )
  repeat
  2drop drop                  ( )
;

: crates-tops-emit ( 'self -- )
  dup fixlist-len 0 do        ( 'self )
    i over fixlist-get        ( 'self 'list )
    fixlist-last emit
  loop
;


9 crates-new
dup crates-push-lines

take-line 2drop  \ empty line

dup crates-exec-all

\ dup crates-emit cr

dup crates-tops-emit cr

bye
