1 constant rock
2 constant paper
3 constant scissors

: win 6 + ;
: draw 3 + ;
: lose ;

: A rock ;
: B paper ;
: C scissors ;

: X ( score-total opponent-move -- new-score-total )
  case
    rock of scissors endof
    paper of rock endof
    scissors of paper endof
  endcase
  lose + ;

: Y ( score-total opponent-move -- new-score-total )
  draw + ;

: Z ( score-total opponent-move -- new-score-total )
  case
    rock of paper endof
    paper of scissors endof
    scissors of rock endof
  endcase
  win + ;

0
include input/22-02.txt
. cr

bye

