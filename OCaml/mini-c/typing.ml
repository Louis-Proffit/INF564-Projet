open Format
open Ttree

(* utiliser cette exception pour signaler une erreur de typage *)
exception Error of string

type environment = {
  vars: (string, typ) Hashtbl.t;
  structs: (string, typ) Hashtbl.t;
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

let type_expr env = function
  | Ptree.Econst 0l ->
  {
    expr_node=Econst 0l;
    expr_typ=Ttypenull;
  }
  | Ptree.Econst n  ->
  {
    expr_node=Econst n;
    expr_typ=Ttypenull;
   }
  | _         -> assert false

let type_type env = function
  | Ptree.Tint -> Tint
  | Ptree.Tstructp ident -> try Hashtbl.find env.structs ident.id with Not_found -> raise (Error ("type_type failed with " ^ ident.id))


let type_stmt env (s: Ptree.stmt) =
  match s.stmt_node with
  | Ptree.Sreturn e ->
    let expr = type_expr env e.expr_node in
    if (type_equiv (expr.expr_typ) (env.returnType)) then Sreturn(expr) else raise (Error("Wrong return type"))
  | _         -> assert false

let rec type_decl_var_list env (pdv: Ptree.decl_var list) =
  match pdv with
    | []      -> []
    | (t, i) :: q -> (type_type env t, i.id) :: (type_decl_var_list env q)

let type_block env (d, s) =
  (type_decl_var_list env d, List.map (type_stmt env) s)


let program (p: Ptree.file) =
  let rec aux env = function
    | [] -> []
    | (Ptree.Dstruct (id, l)) :: q -> assert false (*(match l with
        | [] -> ()
        | (ty, id_var) :: l -> if

      )*)
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



