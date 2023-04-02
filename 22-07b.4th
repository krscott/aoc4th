s" input/22-07.txt" r/o open-file throw value fd
Create line-buf 256 allot

: read-char ( addr -- )
  dup 1 fd read-file    \ read 1 character
  abort" ioerr"         \ abort on IO error
  0= if
    0 swap !            \ set 0 if eof
  else
    drop
  endif
;

: is-whitespace ( c -- b )
  dup bl = if drop true exit endif   \ space
  dup 9  = if drop true exit endif   \ \t
  dup 10 = if drop true exit endif   \ \n
  dup 13 = if drop true exit endif   \ \r
  drop false
;

: is-word-char ( c -- b )
  dup is-whitespace   ( c is-whitespace )
  swap 0=             ( is-whitespace is-nul )
  or invert
;

: read-word ( -- buf len )
  0 line-buf                      ( 0 addr )

  \ skip whitespace
  begin
    dup read-char                 ( 0 addr )
    dup c@ is-whitespace          ( 0 addr is-whitespace )
  while
  repeat

  \ exit with ( buf 0 ) if last char is nul
  dup c@ 0= if swap exit endif

  \ already read 1 char
  1+ swap 1+ swap                 ( 1 addr )

  \ read word
  begin
    dup read-char                 ( len addr )
    dup c@ is-word-char           ( len addr is-word-char )
  while
    1+ swap 1+ swap               ( `len+1` `addr+1` )
  repeat
  drop line-buf swap              ( buf len )
;

: 3drop drop 2drop ;
: 3dup 2 pick 2 pick 2 pick ;

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


: list-new ( item -- list )
  \ list { next: ?list, item: any }
  here 0 , swap ,
;
: list-next ( list -- addr ) @ ;
: list-item ( list -- addr ) 1 cells + @ ;

: list-end ( list -- list )
  begin
    dup @         ( list list.next )
    dup 0<>
  while
    nip           ( list.next )
  repeat
  drop            ( list )
;

: list-len ( list -- n )
  0 swap          ( n list )
  begin
    dup @         ( n list list.next )
    dup 0<>
  while
    nip           ( n list.next )
    swap 1+ swap  ( n+1 list.next )
  repeat
  2drop           ( n )
;

: list-append ( item list -- )
  list-end        ( item endlist )
  swap list-new   ( endlist newlist )
  swap !          ( )
;

\ : list-skip ( n list -- list[n] )
\   begin
\     over 0>       ( n list n>0 )
\   while           ( n list )
\     @             ( n list.next )
\     swap 1-       ( n-1 list.next )
\     dup 0= abort" list-at: index out of range"
\     swap          ( n-1 list.next )
\   repeat
\ ;


: filestat-new ( filesize name-buf name-len -- filestat )
  \ filestat { name-len: int, name-buf: addr, filesize: int }
  align here swap , swap , swap ,
;
: filestat-filesize ( filestat -- n ) 2 cells + @ ;
: filestat-name ( filestat -- buf len ) dup 1 cells + @ swap @ ;
: filestat-print ( filestat -- )
  dup filestat-name type
  ." :" filestat-filesize .
;

: dirstat-new ( name-buf name-len -- dirstat )
  \ dirstat {
  \   name-len: int,
  \   name-buf: addr,
  \   subdirs: ?list,
  \   files: ?list,
  \   parent: ?dirstat
  \ }
  align here swap , swap , 0 , 0 , 0 ,
;
: dirstat-name ( dirstat -- buf len ) dup 1 cells + @ swap @ ;
: dirstat>subdirs ( dirstat -- list ) 2 cells + ;
: dirstat-subdirs ( dirstat -- list ) dirstat>subdirs @ ;
: dirstat>files ( dirstat -- list ) 3 cells + ;
: dirstat-files ( dirstat -- list ) dirstat>files @ ;
: dirstat>parent ( dirstat -- dirstat ) 4 cells + ;
: dirstat-parent ( dirstat -- dirstat ) dirstat>parent @ ;

: dirstat-root ( dirstat -- dirstat )
  begin
    dup dirstat-parent 0<>
  while
    dirstat-parent
  repeat
;
: dirstat-add-file ( filestat dirstat -- )
  dirstat>files     ( filestat 'files )
  dup @ 0<> if
    @ list-append   ( )
  else
    swap list-new   ( 'files files )
    swap !          ( )
  endif
;
: dirstat-add-subdir ( subdir dirstat -- )
  2dup swap dirstat>parent !
  dirstat>subdirs     ( filestat 'subdirs )
  dup @ 0<> if
    @ list-append   ( )
  else
    swap list-new   ( 'subdirs subdirs )
    swap !          ( )
  endif
;
: dirstat-find-subdir ( buf len dirstat -- subdir )
  dirstat-subdirs               ( buf len subdirs )
  begin
    dup 0<>  \ while list node is not null
  while
    3dup                        ( buf len subdirs buf len subdirs )
    list-item dirstat-name s=   ( buf len subdirs is-name-equal )
    if                          ( buf len subdirs )
      -rot 2drop                ( subdirs )
      list-item exit            ( dirstat )
    endif
    list-next                   ( buf len subdirs )
  repeat
  3drop 0                       ( 0 )
;
: dirstat-print-tree ( indent dirstat -- )
  \ print indent and dir name
  over spaces
  dup dirstat-name type ." /" cr

  swap 2 + swap             \ increase indent one level

  dup dirstat-files         ( indent dirstat files )
  begin
    dup 0<>
  while
    2 pick spaces
    dup list-item filestat-print cr
    list-next
  repeat
  drop                      ( indent dirstat )

  dirstat-subdirs           ( indent subdir )
  begin
    dup 0<>
  while
    2dup list-item          ( indent subdir indent subdir )
    recurse                 ( indent subdir )
    list-next
  repeat
  2drop
;


: todo abort" todo" ;


: parse-number ( addr u -- n f )
  s>number?     ( n 0 f )
  nip           ( n f )
;


s" <root>" dirstat-new value cwd

: parse-cd ( -- )
  \ ." parse-cd "
  read-word                       ( buf len )
  \ 2dup type cr

  2dup s" /" s= if
    2drop
    cwd dirstat-root to cwd
    exit
  endif

  2dup s" .." s= if
    2drop
    cwd dirstat-parent            ( buf len parent )
    dup 0= abort" cd: already at root"
    to cwd
    exit
  endif

  \ ." Changing directories" cr
  \ ." Currently: " cwd dirstat-name type cr
  \ cwd 1 cells + @ . cr

  2dup cwd dirstat-find-subdir    ( buf len subdir )
  dup 0= if drop type -1 abort" no such directory" endif

  to cwd                          ( buf len )
  2drop                           ( )

  \ ." Now: " cwd dirstat-name type cr
  \ cwd 1 cells + @ . cr
;

: parse-ls ( -- )
  \ ." parse-ls" cr
;

: parse-cmd ( -- )
  \ ." parse-cmd "
  read-word
  \ 2dup type cr
  2dup s" ls" s= if 2drop parse-ls exit endif
  2dup s" cd" s= if 2drop parse-cd exit endif
  type -1 abort" Unknown command"
;

: parse-dir ( -- )
  \ ." parse-dir "
  read-word
  \ 2dup type cr
  s-clone dirstat-new cwd dirstat-add-subdir
;

: parse-file-entry ( buf len -- )
  \ ." parse-file-entry " 2dup type 1 spaces
  parse-number 0= abort" Expected number"   ( n )
  read-word
  \ 2dup type cr
  s-clone filestat-new                      ( filestat )
  cwd dirstat-add-file                      ( )
;

: parse-line ( buf len -- )
  \ cr ." parse-line cwd: " cwd dirstat-name type cr
  \ cwd 1 cells + @ . cr

  dup 0= if 2drop exit endif
  2dup s" $" s= if 2drop parse-cmd exit endif
  2dup s" dir" s= if 2drop parse-dir exit endif
  parse-file-entry
;

: parse-input ( -- )
  begin
    \ .s cr
    read-word     ( buf len )
    dup 0<>
  while
    parse-line
  repeat
;

: min! ( n addr -- )
  2dup @ < if ! else 2drop endif
;

70000000 30000000 - constant filesystem-target-size

variable min-size

variable threshold-size

: dirstat-filesize ( dirstat -- n )
  0 over dirstat-files      ( dirstat acc files )
  begin
    dup 0<>
  while
    dup list-item           ( dirstat acc files filestat )
    filestat-filesize       ( dirstat acc files n )
    rot + swap              ( dirstat `acc+n` files )
    list-next
  repeat
  drop                      ( dirstat acc )

  swap dirstat-subdirs      ( acc subdirs )
  begin
    dup 0<>
  while
    dup list-item           ( acc subdirs dirstat )
    recurse                 ( acc subdirs n )

    dup threshold-size @ >= if
      dup min-size min!
    endif

    rot + swap              ( `acc+n` subdirs )
    list-next
  repeat
  drop
;



parse-input

cwd dirstat-root to cwd

\ 0 cwd dirstat-print-tree

\ Find how many bytes we need to free
cwd dirstat-filesize
filesystem-target-size - threshold-size !

\ threshold-size @ . cr

\ Find smallest dir which is above the threshold
filesystem-target-size min-size !
cwd dirstat-filesize drop

min-size @ . cr

bye
