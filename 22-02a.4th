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
  rock swap
  case
    rock of draw endof
    paper of lose endof
    scissors of win endof
  endcase
  + ;

: Y ( score-total opponent-move -- new-score-total )
  paper swap
  case
    rock of win endof
    paper of draw endof
    scissors of lose endof
  endcase
  + ;

: Z ( score-total opponent-move -- new-score-total )
  scissors swap
  case
    rock of lose endof
    paper of win endof
    scissors of draw endof
  endcase
  + ;

0
include input/22-02.txt
. cr

bye

