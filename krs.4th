\ Kris's Forth Utility Library

\
\ Basic
\

: 3drop drop 2drop ;
: 3dup 2 pick 2 pick 2 pick ;

\
\ Characters
\

: is-whitespace ( c -- b )
  \ Check if given character is whitespace

  dup bl = if drop true exit endif   \ space
  dup 9  = if drop true exit endif   \ \t
  dup 10 = if drop true exit endif   \ \n
  dup 13 = if drop true exit endif   \ \r
  drop false
;

: is-word-char ( c -- b )
  \ Check if given character is non-whitespace char

  dup is-whitespace   ( c is-whitespace )
  swap 0=             ( is-whitespace is-nul )
  or invert
;

\
\ Strings
\

: s= ( buf1 len1 buf2 len2 -- b )
  \ return false if lengths are not equal
  2 pick                        ( buf1 len1 buf2 len2 len1 )
  <> if 3drop false exit endif  ( buf1 len1 buf2 )
  swap                          ( buf1 buf2 len1 )

  \ compare characters
  0 do                          ( buf1 buf2 )
    over i + c@                 ( buf1 buf2 c1 )
    over i + c@                 ( buf1 buf2 c1 c2 )
    <> if unloop 2drop false exit endif
  loop
  2drop true
;
: s-clone ( buf1 len -- buf2 len )
  dup >r here >r        ( buf1 len      | r: len buf2 )
  here over allot swap  ( buf1 buf2 len | r: len buf2 )
  cmove                 (               | r: len buf2 )
  r> r>                 ( buf2 len )
;

\
\ I/O
\

: read-char ( fd addr -- )
  \ read 1 character from file fd and store at addr

  dup 1 3 pick        ( fd addr addr 1 fd )
  read-file           ( fd addr bytes-read is-io-err )
  \ abort on IO error
  abort" ioerr"       ( fd addr bytes-read )
  0= if               ( fd addr )
    \ set 0 if eof
    0 swap !          ( fd )
  else
    drop              ( fd )
  endif
  drop                ( )
;

: read-word ( buf fd -- buf len )
  \ Read a word from file fd

  0 -rot                          ( 0 buf fd )

  \ skip whitespace
  begin
    2dup read-char                ( 0 buf fd )
    over c@ is-whitespace         ( 0 buf fd is-whitespace )
  while
  repeat

  \ exit with ( buf 0 ) if last char is nul
  over c@ 0= if swap exit endif   ( 0 buf fd )

  \ already read 1 char
  rot 1+ rot 1+ rot               ( 1 `buf+1` fd )

  \ read word
  begin
    2dup read-char                ( len buf fd )
    over c@ is-word-char          ( len buf fd is-word-char )
  while
    rot 1+ rot 1+ rot             ( `len+1` `buf+1` fd )
  repeat
  drop swap                       ( buf len )
;

\
\ Linked List
\

: listnode-new ( item -- listnode )
  \ listnode { next: ?listnode, item: any }
  align here 0 , swap ,
;

: listnode>next ( listnode -- addr ) ;
: listnode-next ( listnode -- listnode ) listnode>next @ ;
: listnode>item ( listnode -- addr ) 1 cells + ;
: listnode-item ( listnode -- any ) listnode>item @ ;

: listnode-end ( listnode -- listnode )
  begin
    dup @         ( listnode listnode.next )
    dup 0<>
  while
    nip           ( listnode.next )
  repeat
  drop            ( listnode )
;

: listnode-len ( listnode -- n )
  1 swap          ( n listnode )
  begin
    dup @         ( n listnode listnode.next )
    dup 0<>
  while
    nip           ( n listnode.next )
    swap 1+ swap  ( n+1 listnode.next )
  repeat
  2drop           ( n )
;

: listnode-push ( item listnode -- )
  listnode-end        ( item endlist )
  swap listnode-new   ( endlist newlist )
  swap !              ( )
;

: list-new ( -- list )
  \ list { head: ?listnode, tail: ?listnode }
  align here 0 , 0 ,
;

: list>head ( list -- addr ) ;
: list-head ( list -- listnode ) list>head @ ;
: list>tail ( list -- addr ) 1 cells + ;
: list-tail ( list -- listnode ) list>tail @ ;
: list-is-empty ( list -- b ) list-head 0= ;

: list-len ( list -- n )
  list-head
  dup 0= if
    drop 0
  else
    listnode-len
  endif
;

: list-push ( item list -- )
  swap listnode-new       ( list item-node )
  over list-tail          ( list item-node tail-node )
  dup 0= if
    drop                  ( list item-node )
    2dup list>tail !      ( list item-node )
    list>head !           ( )
  else
    over swap             ( list item-node item-node tail-node )
    listnode>next !       ( list item-node )
    swap list>tail !      ( )
  endif
;
\ TODO: list-pop, list-unshift, list-shift

\
\ Fixed-Capacity List
\

: fixlist-new ( capacity -- fixlist )
  \ fixlist { len: int, capacity: int, items: int... }
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