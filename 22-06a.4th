s" input/22-06.txt" r/o open-file throw value fd

: read-char ( -- c )
  here                            \ temp buffer, no allot
  1 fd read-file throw 0= throw   \ throw on error or EOF
  here c@
;

: header-check { a b c d -- b c d is-unique }
  b c d
  a b <> a c <> and a d <> and
         b c <> and b d <> and
                    c d <> and
;

: header-position ( -- n )
  read-char read-char read-char 3 ( a b c i )
  begin
    1+ >r                         ( a b c | r: i )
    read-char header-check        ( b c d is-unique | r: i )
    r> swap                       ( b c d i is-unique )
  until
  >r 2drop drop r>                ( i )
;

header-position . cr

bye