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
%token <val> AND OR NOR ADD ADDU SUB SUBU JR SLTU BEQ BNEQ SLL SRL LW LBU LHU LUI SLTI SLTIU SB SH SW SLT ANDI ORI ADDI ADDIU J JAL
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
              | ADD REG',' REG',' REG { cmd_r($1, $4, $6, $2, 0) }
              | ADDU REG',' REG',' REG { cmd_r($1, $4, $6, $2, 0) }
              | BEQ REG',' REG',' LABEL { cmd_i($1, $2, $4, 0, $6) }
              | JR REG',' REG',' REG { cmd_r($1, $4, $6, $2, 0) }
              | NOR REG',' REG',' REG { cmd_r($1, $4, $6, $2, 0) }
              | OR REG',' REG',' REG { cmd_r($1, $4, $6, $2, 0) }
              | SLTU REG',' REG',' REG { cmd_r($1, $4, $6, $2, 0) }

              | ADDI REG',' REG',' num { cmd_i($1, $4, $2, $6, "") }
              | ADDIU REG',' REG',' num { cmd_i($1, $4, $2, $6, "") }
              | ANDI REG',' REG',' num { cmd_i($1, $4, $2, $6, "") }
              | BEQ REG',' REG',' num { cmd_i($1, $2, $4, $6, "") }
              | BNEQ REG',' REG',' LABEL { cmd_i($1, $2, $4, 0, $6) }
              | BNEQ REG',' REG',' num { cmd_i($1, $2, $4, $6, "") }
              | LBU REG',' num'('REG')' { cmd_i($1, $6, $2, $4, "") }
              | LHU REG',' num'('REG')' { cmd_i($1, $6, $2, $4, "") }
              | LUI REG',' num'('REG')' { cmd_i($1, $6, $2, $4, "") }
              | LW REG',' num'('REG')' { cmd_i($1, $6, $2, $4, "") }
              | ORI REG',' REG',' num { cmd_i($1, $4, $2, $6, "") }
              | SB REG',' num'('REG')' { cmd_i($1, $6, $2, $4, "") }
              | SH REG',' num'('REG')' { cmd_i($1, $6, $2, $4, "") }
              | SLL REG',' REG',' num { cmd_r($1, 0, $4, $2, $6) }
              | SLT REG',' REG',' REG { cmd_r($1, $4, $6, $2, 0) }
              | SLTI REG',' num'('REG')' { cmd_i($1, $6, $2, $4, "") }
              | SLTIU REG',' num'('REG')' { cmd_i($1, $6, $2, $4, "") }
              | SRL REG',' REG',' num { cmd_r($1, 0, $4, $2, $6) }
              | SUB REG',' REG',' REG { cmd_r($1, $4, $6, $2, 0) }
              | SUBU REG',' REG',' REG { cmd_r($1, $4, $6, $2, 0) }
              | SW REG',' num'('REG')' { cmd_i($1, $6, $2, $4, "") }

              | J num { cmd_j($1, $2, "") }
              | J LABEL { cmd_j($1, 0, $2) }
              | JAL num { cmd_j($1, $2, "") }
              | JAL LABEL { cmd_j($1, 0, $2) }
              ;

num  : NUMBER { $$ = $1 }
     | '-'NUMBER { $$ = -$2 }
     ;

label_set : LABEL ':' { label($1) }
          ;
%%
