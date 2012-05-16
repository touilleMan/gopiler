%{

package main

import (
         "fmt"
)

%}

%union{
  val int32
  name string
}

%type <val> num

%token <val> NUMBER REG COMMENT
%token <val> AND OR XOR ADD SUB BEQ SLL SRL LW SW SLT ANDI ORI ADDI
%token <name> LABEL

%right ':' ','
%left '-'

%%

source : lines
       ;

lines : // nothing
      | single_line lines
      ;

single_line : label_set
            | instruction
            | COMMENT
            ;

instruction   : AND REG',' REG',' REG { cmd_r($1, $4, $6, $2, 0) }
              | OR REG',' REG',' REG { cmd_r($1, $4, $6, $2, 0) }
              | XOR REG',' REG',' REG { cmd_r($1, $4, $6, $2, 0) }
              | ADD REG',' REG',' REG { cmd_r($1, $4, $6, $2, 0) }
              | SUB REG',' REG',' REG { cmd_r($1, $4, $6, $2, 0) }
              | BEQ REG',' REG',' LABEL { cmd_i($1, $2, $4, 0, $6) }
              | BEQ REG',' REG',' num { cmd_i($1, $2, $4, $6, "") }
              | SLL REG',' REG',' num { cmd_r($1, 0, $4, $2, $6) }
              | SRL REG',' REG',' num { cmd_r($1, 0, $4, $2, $6) }
              | LW REG',' num'('REG')' { cmd_i($1, $6, $2, $4, "") }
              | SW REG',' num'('REG')' { cmd_i($1, $6, $2, $4, "") }
              | SLT REG',' REG',' REG { cmd_r($1, $4, $6, $2, 0) }
              | ANDI REG',' REG',' num { cmd_i($1, $4, $2, $6, "") }
              | ORI REG',' REG',' num { cmd_i($1, $4, $2, $6, "") }
              | ADDI REG',' REG',' num { cmd_i($1, $4, $2, $6, "") }
              ;

num  : NUMBER { $$ = $1 }
     | '-'NUMBER { $$ = -$2 }
     ;

label_set : LABEL ':' { label($1) }
          ;
%%
