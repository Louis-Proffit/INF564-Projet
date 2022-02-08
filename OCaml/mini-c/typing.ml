open Format
open Ttree

(* utiliser cette exception pour signaler une erreur de typage *)
exception Error of string

type environment = {
  vars: (string, typ) Hashtbl.t;
  structs: (string, structure) Hashtbl.t;
  funs: (string, decl_fun) Hashtbl.t;
  returnType: typ
}

let string_of_type = function
  | Tint       -> "int"
  | Tstructp x -> "struct " ^ x.str_name ^ "*"
  | Tvoidstar  -> "void*"
  | Ttypenull  -> "typenull"


let type_equiv t s =
  match (t, s) with
    | (a, b) when b = a       -> true
    | (Ttypenull, Tint)       -> true
    | (Ttypenull, Tstructp _) -> true
    | (Tvoidstar, Tstructp _) -> true
    | (Tint, Ttypenull)       -> true
    | (Tstructp _, Ttypenull) -> true
    | (Tstructp _, Tvoidstar) -> true
    | _                       -> false

let rec type_expr env = function
  | Ptree.Econst 0l ->
  {
    expr_node = Econst 0l;
    expr_typ = Ttypenull;
  }
  | Ptree.Econst n  ->
  {
    expr_node = Econst n;
    expr_typ = Ttypenull;
   }
  | Ptree.Eright (Ptree.Lident x) ->
    (try {expr_node = Eaccess_local x.id; expr_typ = Hashtbl.find env.vars x.id}
     with Not_found -> raise (Error ("the variable " ^ x.id ^ " is not assigned")))
  | Ptree.Eright (Ptree.Larrow (e, x)) ->
    let texpr = type_expr env e.expr_node in
    (match texpr.expr_typ with
      | Tstructp str -> (
        try let structure = Hashtbl.find env.structs str.str_name
            in let f = Hashtbl.find structure.str_fields x.id
               in {expr_node = Eaccess_field (texpr, f);
                   expr_typ = f.field_typ}
       with Not_found -> raise (Error "you are trying to access a structure that is not defined"))
      | _            -> raise (Error "you are trying to access a field of something that is not a structure")
)
  | Ptree.Eassign (Ptree.Lident x, e) ->
    let texpr = type_expr env e.expr_node in
    (try let ty_left = Hashtbl.find env.vars x.id in
       if type_equiv ty_left texpr.expr_typ
       then {expr_node = Eassign_local (x.id, texpr); expr_typ = texpr.expr_typ}
       else raise (Error ("you are trying to assign " ^ x.id ^ " with the wrong type"))
     with Not_found -> raise (Error ("the variable " ^ x.id ^ " is not declared (assignement)"))
     )
  | Ptree.Eassign (Ptree.Larrow (e1, x), e2) ->
    let texpr1 = type_expr env e1.expr_node and texpr2 = type_expr env e2.expr_node in
    (match texpr1.expr_typ with
      | Tstructp str -> (
        try let structure = Hashtbl.find env.structs str.str_name
            in let f = Hashtbl.find structure.str_fields x.id
               in if type_equiv f.field_typ texpr2.expr_typ
                  then {expr_node = Eassign_field (texpr1, f, texpr2); expr_typ = f.field_typ}
                  else raise (Error ("you are trying to assign " ^ x.id ^ " with the wrong type"))
        with Not_found -> raise (Error "you are trying to assign a field of a structure that is not defined"))
      | _            -> raise (Error "you are trying to assign a field of something that is not a structure")
)
  | Ptree.Eunop (Unot,e) -> let expr = type_expr env e.expr_node in {expr_node=Eunop(Unot, expr);expr_typ=Tint}
  | Ptree.Eunop (Uminus,e) -> let expr = type_expr env e.expr_node in
    if (type_equiv expr.expr_typ Tint)
    then {expr_node=Eunop(Uminus, expr);expr_typ=Tint}
    else raise (Error "Negation of a non integer variable not defined")
    | Ptree.Ebinop (b,e1,e2) ->
    let ne1 = type_expr env e1.expr_node in
    let ne2 = type_expr env e2.expr_node in
    begin match b with
    | Beq
    | Bneq
    | Blt
    | Ble
    | Bgt
    | Bge->
      if (type_equiv ne1.expr_typ ne2.expr_typ)
      then {expr_node=Ebinop(b, ne1, ne2);expr_typ=Tint}
      else raise (Error "Incompatible types for binop")
     | Badd
     | Bsub
     | Bmul
     | Bdiv ->
      if ((type_equiv ne1.expr_typ Tint) && (type_equiv ne2.expr_typ Tint))
      then {expr_node=Ebinop(b, ne1, ne2);expr_typ=Tint}
      else raise (Error "Incompatible types for binop")
     | Band
     | Bor ->
     {expr_node=Ebinop(b, ne1, ne2);expr_typ=Tint}
    end
  | Ptree.Ecall (i,el) ->
  let mfun = Hashtbl.find env.funs i.id in
    let expr_list = List.map2 (
        fun (expr:Ptree.expr) (t,i) -> let mexpr = type_expr env expr.expr_node in
        if (type_equiv mexpr.expr_typ t)
        then mexpr else raise (Error "non matching types")
       ) el mfun.fun_formals in
    {expr_node=Ecall(i.id, expr_list);expr_typ=mfun.fun_typ}
  | Ptree.Esizeof i ->
  try let structure = Hashtbl.find env.structs i.id in {expr_node=Esizeof(structure); expr_typ=Tint}
  with Not_found -> raise (Error ("structure " ^ i.id ^ " not defined"))
  | _         -> assert false

let type_type env = function
  | Ptree.Tint -> Tint
  | Ptree.Tstructp ident -> try Tstructp (Hashtbl.find env.structs ident.id) with Not_found -> raise (Error ("type_type failed with " ^ ident.id))


let rec type_stmt env (s: Ptree.stmt) =
  match s.stmt_node with
  | Ptree.Sskip           -> Sskip
  | Ptree.Sexpr e         -> Sexpr (type_expr env e.expr_node)
  | Ptree.Sblock (vl, sl) ->
    (let rec fill_vars h (l: Ptree.decl_var list) =
       match l with
        | []                -> []
        | (ty, id_var) :: q -> let ttree_type = type_type env ty in
                               Hashtbl.add h id_var.id ttree_type;
                               (ttree_type, id_var.id) :: fill_vars h q
    in
    let tvl = fill_vars env.vars vl in
    Sblock (tvl, List.map (type_stmt env) sl))
  | Ptree.Sreturn e       ->
    let expr = type_expr env e.expr_node in
    if (type_equiv (expr.expr_typ) (env.returnType)) then Sreturn(expr) else raise (Error("Wrong return type"))
  | _         -> assert false

let type_decl_var env ((t, i):(Ptree.typ * Ptree.ident)) =
    let new_t = type_type env t in
    Hashtbl.add env.vars i.id new_t;
    (new_t, i.id)

let type_stmt_list env sl = List.map (type_stmt env) sl

let type_decl_var_list env dl =
    List.map (type_decl_var env) dl

let type_block env ((dl, sl):(Ptree.decl_var list * Ptree.stmt list)) =
    let vars = type_decl_var_list env dl in
    (vars, type_stmt_list env sl)

let program (p: Ptree.file) =
  let rec aux env = function
    | [] -> []
    | (Ptree.Dstruct (id, l)) :: q ->
        if (Hashtbl.mem env.structs id.id) then raise (Error ("struct " ^ id.id ^ " was already declared"));
        Hashtbl.add env.structs id.id {str_name = id.id; str_fields = Hashtbl.create 1};
        (let new_fields = Hashtbl.create 15 in
        (let rec fill_struct h (li: Ptree.decl_var list) =
          match li with
            | []                -> ()
            | (ty, id_var) :: q -> Hashtbl.add h (id_var.id: ident) {field_name = id_var.id;
                                                                    field_typ = type_type env ty};
                                   fill_struct h q
         in
         fill_struct new_fields l;
         let new_struct = {
           str_name = id.id;
           str_fields = new_fields
         } in
         Hashtbl.remove env.structs id.id;
         Hashtbl.add env.structs id.id new_struct;
         aux env q))
    | (Ptree.Dfun d) :: q -> (
        let fun_typ = type_type env d.fun_typ in
        let new_env = {
            vars = Hashtbl.create 15;
            structs = env.structs;
            funs = env.funs;
            returnType = fun_typ;
        } in
        let ttree_dfun = {
          fun_typ = fun_typ;
          fun_name = d.fun_name.id;
          fun_formals = type_decl_var_list env d.fun_formals;
          fun_body = type_block new_env d.fun_body
        } in
        Hashtbl.add env.funs d.fun_name.id ttree_dfun;
        ttree_dfun :: (aux env q)
      )
   in
   let env = {
     vars = Hashtbl.create 15;
     structs = Hashtbl.create 10;
     funs = Hashtbl.create 10;
     returnType = Ttypenull
   } in
   {
     funs = aux env p
   }



