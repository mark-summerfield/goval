%{
package main

%}

%union {
  token     Token
  expr      interface{}
}


%start program

%type<expr> program
%type<expr> expr
%type<expr> literal
%type<expr> math
%type<expr> logic
%type<expr> varAccess

%token<token> LITERAL_BOOL   // true false
%token<token> LITERAL_NUMBER // 42 4.2 4e2 4.2e2
%token<token> LITERAL_STRING // "text" 'text'
%token<token> IDENT
%token<token> AND            // &&
%token<token> OR             // ||

/* Operator precedence is taken from c: http://en.cppreference.com/w/c/language/operator_precedence */

%left  OR
%left  AND
%left  '+' '-'
%left  '*' '/'
%right '!'
%left  '.' '[' ']'

%%

program
  : expr
  {
    $$ = $1
    yylex.(*Lexer).result = $$
  }
  ;

expr
  : literal
  | math
  | logic
  | varAccess
  | '(' expr ')'          { $$ = $2 }
  ;

literal
  : LITERAL_BOOL          { $$ = $1.value }
  | LITERAL_NUMBER        { $$ = $1.value }
  | LITERAL_STRING        { $$ = $1.value }
  ;

math
  : '-' expr %prec  '*'   { $$ = unaryMinus($2)  }  /* unary minus has higher precedence */
  | expr '+' expr         { $$ = add($1, $3) }
  | expr '-' expr         { $$ = sub($1, $3) }
  | expr '*' expr         { $$ = mul($1, $3) }
  | expr '/' expr         { $$ = div($1, $3) }
  ;

logic
  : '!' expr              { $$ = !asBool($2) }
  | expr AND expr         { $$ = asBool($1) && asBool($3) }
  | expr OR expr          { $$ = asBool($1) || asBool($3) }

varAccess
  : IDENT                   { $$ = accessVar(yylex.(*Lexer).variables, $1.literal) }
  | varAccess '.' IDENT     { $$ = accessField($1, $3.literal) }
  | varAccess '[' expr ']'  { $$ = accessField($1, $3) }
  ;


%%
