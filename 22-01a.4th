s" input/22-01.txt" r/o open-file throw Value fd

256 Constant line-size
Create line-buf line-size 2 + allot

: take-line ( -- n-len f-not-eof )
  line-buf line-size fd read-line throw ;

: take-n ( -- f-not-eof n-number )
  take-line swap dup 0<>
    if line-buf swap s>number? 2drop
    then ;

: take-bag ( -- n )
  0
  begin take-n nip dup 0<>
    while +
    repeat
  drop ;

: max-bag ( -- n )
  0
  begin take-bag dup 0<>
    while max
    repeat
  drop ;

max-bag . cr

bye
