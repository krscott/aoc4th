s" input/22-06.txt" r/o open-file throw value fd

: read-char ( -- c )
  here                            \ temp buffer, no allot
  1 fd read-file abort" ioerr" 0= \ abort on IO error
  abort" eof"                     \ solution will halt before EOF
  here c@
;

14 constant som-len
here som-len allot constant som-buf

: is-som ( -- f )
  som-len 1- 0 do
    i som-buf + c@          ( c )
    som-len i 1+ do
      dup i som-buf + c@    ( c c )
      = if
        drop false          ( 0 )
        unloop unloop exit
      endif
    loop
    drop                    ( )
  loop
  true                      ( -1 )
;

: som-position ( -- n )
  som-len 1-                      ( i )

  \ fill initial buffer
  dup 0 do
    read-char i som-buf + c!
  loop

  \ search for start-of-message
  begin                           ( i )
    read-char over som-len mod    ( i c `i%len` )
    som-buf + c!                  ( i )
    1+
    is-som                        ( i is-som )
  until
;

som-position . cr

bye