
/* Parseur pour le compilateur C */

%{

  open Parsing
  open Ptree

  (* Construction d'expressions et d'instructions localis�es *)

%}

%token <string> IDENT
%token <int32> INTEGER

/* Mots cl�s */

%token IF ELSE WHILE RETURN
%token INT STRUCT SIZEOF

/* Symboles */

%token LPAR RPAR LBRACE RBRACE
%token SEMICOLON COMMA ARROW
%token EOF

/* Op�rateurs */

%token EQ
%token VERTICALBARVERTICALBAR
%token AMPERSANDAMPERSAND
%token <Ptree.binop> EQOP
%token <Ptree.binop> COMP
%token PLUS MINUS
%token STAR SLASH
%token BANG

/*s Pr�c�dences */

%nonassoc prec_then
%nonassoc ELSE

%right EQ
%left VERTICALBARVERTICALBAR /* || */
%left AMPERSANDAMPERSAND     /* && */
%left EQOP                   /* == != */
%left COMP                   /* < <= > >= */
%left PLUS MINUS             /* + - */
%left STAR SLASH             /* * /  */
%right uminus BANG           /* - ! */
%left ARROW

/*s Point d'entr�e */

%start file
%type <Ptree.file> file
%type <Ptree.decl_var> decl_var

%%

file:
| dl = list(decl) EOF  { dl }
;

typ:
| p = primitive_typ
    { p }
| t = primitive_typ STAR
    { Tpointer t }
;

primitive_typ:
| INT
    { Tint }
| STRUCT s = ident
    { Tstruct s }
;

ident_star :
| i = ident
    { (i,0)}
| STAR id = ident_star
    { let i,n = id in (i, n + 1) }
;

decl_var :
| t = typ i = ident
    { (t,i) }
;

decl:
| STRUCT s = ident LBRACE fl = list(decl_var_local) RBRACE SEMICOLON
    { Dstruct (s, List.flatten fl) }
| f = decl_fun
    { Dfun f }
;

decl_var_local:
| t = primitive_typ vl = separated_nonempty_list(COMMA, ident_star) SEMICOLON
    { List.map (fun x -> (t, x)) vl }
;

decl_fun:
| t = typ id = ident LPAR args = separated_list(COMMA, decl_var) RPAR body = block
    { {
        fun_typ = t;
        fun_name = id;
        fun_formals = args;
        fun_body = body;
    } }
;

lvalue:
| ident
    { Lident $1 }
| expr ARROW ident
    { Larrow ($1, $3) }
;

expr:
  e = expr_node
  { { expr_node = e; expr_loc = $startpos, $endpos } }
;

expr_node:
| lvalue
    { Eright $1 }
| lvalue EQ expr
    { Eassign ($1, $3) }
| expr VERTICALBARVERTICALBAR expr
    { Ebinop (Bor, $1, $3) }
| expr AMPERSANDAMPERSAND expr
    { Ebinop (Band, $1, $3) }
| expr EQOP expr
    { Ebinop ($2, $1, $3) }
| expr COMP expr
    { Ebinop ($2, $1, $3) }
| expr PLUS expr
    { Ebinop (Badd, $1, $3) }
| expr MINUS expr
    { Ebinop (Bsub, $1, $3) }
| expr STAR expr
    { Ebinop (Bmul, $1, $3) }
| expr SLASH expr
    { Ebinop (Bdiv, $1, $3) }
| MINUS expr %prec uminus
    { Eunop (Uminus, $2) }
| BANG expr
    { Eunop (Unot, $2) }
| INTEGER
    { Econst $1 }
| id = ident LPAR el = separated_list(COMMA, expr) RPAR
    { Ecall (id, el) }
| LPAR expr RPAR
    { $2.expr_node }
| SIZEOF LPAR t = typ RPAR
    { Esizeof t }
;

stmt:
  s = stmt_node
   { { stmt_node = s; stmt_loc = $startpos, $endpos } }
;

stmt_node:
| SEMICOLON
   { Sskip }
| expr SEMICOLON
   { Sexpr $1 }
| IF LPAR expr RPAR stmt %prec prec_then
   { Sif ($3, $5, { stmt_node = Sskip; stmt_loc = $startpos, $endpos }) }
| IF LPAR expr RPAR stmt ELSE stmt
   { Sif ($3, $5, $7) }
| WHILE LPAR expr RPAR stmt
   { Swhile ($3, $5) }
| block
   { Sblock $1 }
| RETURN expr SEMICOLON
   { Sreturn $2 }
;

block:
| LBRACE vl = list(decl_var_local) sl = list(stmt) RBRACE { List.flatten vl, sl }
;

ident:
| id = IDENT { { id = id; id_loc = $startpos, $endpos } }
;
