\ Scratch pad for misc useful things

: to-string ( n -- addr c ) s>d <# #s #> ;
: print-n ( n -- ) to-string stdout write-line throw ;

: ctype ( addr -- ) begin dup c@ dup while emit 1 + repeat drop drop ;

