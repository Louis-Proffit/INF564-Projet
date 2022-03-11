open Format
open Ttree

(* utiliser cette exception pour signaler une erreur de typage *)
exception Error of string

type environment = {
  vars                      : (string, typ * var_typ) Hashtbl.t;
  structs                   : (string, structure) Hashtbl.t;
  funs                      : (string, decl_fun) Hashtbl.t;
  returnType                : typ;
  block_new_index           : int ref;
}

let rec string_of_type = function
  | Tint       -> "int"
  | Tstruct x -> "struct " ^ x.str_name
  | Tpointer t -> (string_of_type t)^"*"
  | Tvoidstar  -> "void*"
  | Ttypenull  -> "typenull"

let rec type_equiv t s =
  match (t, s) with
    | (Tstruct s1, Tstruct s2) -> String.equal s1.str_name s2.str_name
    | (Tpointer t1, Tpointer t2) -> type_equiv t1 t2
    | (a, b) when b = a       -> true
    | (Ttypenull, Tint)       -> true
    | (Tint, Ttypenull)       -> true
    | (Ttypenull, Tpointer _) -> true
    | (Tpointer _, Ttypenull) -> true
    | (Tvoidstar, Tpointer _) -> true
    | (Tpointer _, Tvoidstar) -> true
    | _                       -> false

let rec type_type env = function
    | Ptree.Tint -> Tint
    | Ptree.Tstruct i ->
        begin try Tstruct (Hashtbl.find env.structs i.id)
        with Not_found -> raise (Error ("Structure "^i.id^" not defined"))
        end
    | Ptree.Tpointer t -> Tpointer (type_type env t)

and type_ident_star t = function
    | (i,0) -> t
    | (i,n) -> Ptree.Tpointer (type_ident_star t (i, n - 1))

and type_expr env = function
  | Ptree.Econst 0l ->
  {
    expr_node = Econst 0l;
    expr_typ = Ttypenull;
  }
  | Ptree.Econst n  ->
  {
    expr_node = Econst n;
    expr_typ = Tint;
   }
  | Ptree.Eright (Ptree.Lident x) ->
  begin
      try let (typ, var_typ) = Hashtbl.find env.vars x.id in
      {
          expr_node = Eaccess_local(x.id,var_typ);
          expr_typ = typ;
      }
      with Not_found -> raise (Error ("the variable " ^ x.id ^ " is not assigned"))
  end
  | Ptree.Eright (Ptree.Lderef e) ->
    let texpr = type_expr env e.expr_node in
    begin match texpr.expr_typ with
        | Tpointer t -> {expr_node=Eaccess_memory(texpr);expr_typ=t}
        | _ -> raise (Error ("Cannot dereference a non pointer type"))
    end
  | Ptree.Eright (Ptree.Larrow (e, x)) ->
    let texpr = type_expr env e.expr_node in
    begin match texpr.expr_typ with
      | Tpointer (Tstruct str) ->
          begin try let f = Hashtbl.find str.str_fields x.id in
          {
            expr_node = Eaccess_field (texpr, f);
            expr_typ = f.field_typ
          } with Not_found -> raise (Error ("field "^x.id^" doesn't exist"))
          end
      | _            -> raise (Error "you are using arrow operator on a non structure pointer expression")
    end
  | Ptree.Eassign (Ptree.Lident x, e) ->
    let texpr = type_expr env e.expr_node in
    (try let (left_typ, arg_typ) = Hashtbl.find env.vars x.id in
       if type_equiv left_typ texpr.expr_typ
       then {expr_node = Eassign_local (x.id, texpr, arg_typ); expr_typ = left_typ}
       else raise (Error ("Assigning " ^ x.id ^ " of type "^(string_of_type left_typ)^" with type "^(string_of_type texpr.expr_typ)))
     with Not_found -> raise (Error ("the variable " ^ x.id ^ " is not declared (assignement)"))
     )
  | Ptree.Eassign (Ptree.Lderef e1, e2) ->
    let texpr1 = type_expr env e1.expr_node in
    let texpr2 = type_expr env e2.expr_node in
    begin match texpr1.expr_typ with
        | Tpointer t ->
            if type_equiv t texpr2.expr_typ
            then {expr_node = Eassign_memory (texpr1, texpr2); expr_typ=t }
            else raise (Error "Incompatible types for dereference assigning")
        | _ -> raise (Error "Can't dereference a non pointer type")
    end
  | Ptree.Eassign (Ptree.Larrow (e1, x), e2) ->
    let typed_e1 = type_expr env e1.expr_node and typed_e2 = type_expr env e2.expr_node in
    begin match typed_e1.expr_typ with
      | Tpointer (Tstruct str) ->
      begin
        try let field = Hashtbl.find str.str_fields x.id in
        if type_equiv field.field_typ typed_e2.expr_typ
        then
        {
            expr_node = Eassign_field (typed_e1, field, typed_e2);
            expr_typ = field.field_typ;
        }
        else raise (Error ("Assigning "^x.id^" of type "^(string_of_type field.field_typ)^" with type "^(string_of_type typed_e2.expr_typ)))
        with Not_found -> raise (Error ("accessing undefined field "^x.id^" for struct "^str.str_name))
      end
      | _ -> raise (Error "you are trying using arrow operator to assign a non struct pointer expression")
    end
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
  (try (let mfun = Hashtbl.find env.funs i.id in
    (try let expr_list = List.map2 (
        fun (expr:Ptree.expr) (t,i,vt) -> let mexpr = type_expr env expr.expr_node in
        if (type_equiv mexpr.expr_typ t)
        then mexpr else raise (Error "non matching types")
       ) el mfun.fun_formals in
    {expr_node=Ecall(i.id, expr_list);expr_typ=mfun.fun_typ}
   with Invalid_argument e -> raise (Error "wrong number of arguments")))
   with Not_found -> raise (Error ("function "^i.id^" not defined")))
  | Ptree.Esizeof typ -> {expr_node= Esizeof (type_type env typ); expr_typ=Tint} (* What if the structure is not defined *)


and type_stmt env (s: Ptree.stmt) =
  match s.stmt_node with
  | Ptree.Sskip           -> Sskip
  | Ptree.Sexpr e         -> Sexpr (type_expr env e.expr_node)
  | Ptree.Sblock (dl, sl) -> Sblock(type_block env (dl,sl))
  | Ptree.Sreturn e       ->
    let expr = type_expr env e.expr_node in
    if (type_equiv (expr.expr_typ) (env.returnType)) then Sreturn(expr) else raise (Error("Wrong return type"))
  | Ptree.Sif (e,s1,s2) -> Sif(type_expr env e.expr_node, type_stmt env s1, type_stmt env s2)
  | Ptree.Swhile (e,s) -> Swhile(type_expr env e.expr_node, type_stmt env s)


and type_block env ((dl, sl):(Ptree.decl_var_local list * Ptree.stmt list)) =
    let block_index = !(env.block_new_index) in
    env.block_new_index := block_index + 1;
    let new_vars = Hashtbl.create 15 in
    List.iter
        (fun ((t,(i,n)):(Ptree.typ*Ptree.ident_star)) ->
            if (Hashtbl.mem new_vars i.id)
            then raise (Error ("variable "^i.id^" defined twice in the block"))
            else Hashtbl.add new_vars i.id (type_type env (type_ident_star t (i,n)), Ilocal block_index)
        )
    dl;
    Hashtbl.iter (Hashtbl.add env.vars) new_vars;
    let stmts = List.map (type_stmt env) sl in
    Hashtbl.iter (fun i t -> Hashtbl.remove env.vars i) new_vars;
    let decls = List.map (fun ((t,(i,n)):(Ptree.typ*Ptree.ident_star)) -> let (mt, mvt) = Hashtbl.find new_vars i.id in (mt, i.id,Ilocal block_index)) dl in
    (decls, stmts)

let program (p: Ptree.file) =
  let rec aux env = function
    | [] -> []
    | (Ptree.Dstruct (id, l)) :: q ->
        let i = ref 0 in
        if (Hashtbl.mem env.structs id.id) then raise (Error ("struct " ^ id.id ^ " was already declared"));
        Hashtbl.add env.structs id.id {str_name = id.id ; str_fields = Hashtbl.create 5};
        let rec add_fields str_id env = function
            | [] -> ()
            | ((t,(id,n)):(Ptree.typ * (Ptree.ident * int))) :: q ->
                let str = try (Hashtbl.find env.structs str_id).str_fields with Not_found -> raise (Error "wtf") in
                if (Hashtbl.mem str id.id) then raise (Error ("Struct "^str_id^" contains two fields named "^id.id))
                else (Hashtbl.add str id.id)
                {
                    field_name = id.id;
                    field_typ = type_type env (type_ident_star t (id,n));
                    shift = !i;
                };
                i := !i + 1;
                add_fields str_id env q in
        add_fields id.id env l;
        aux env q
    | (Ptree.Dfun d) :: q -> (
        let fun_name = d.fun_name.id in
        (if (Hashtbl.mem env.funs fun_name) then raise (Error ("function named "^fun_name^" defined twice")));
        let fun_typ = type_type env d.fun_typ in
        let fun_formals = List.map
        (
            fun ((pt,i):(Ptree.typ*Ptree.ident)) -> let tt = type_type env pt in
            (if (Hashtbl.mem env.vars i.id) then raise (Error ("function "^fun_name^" has two arguments named "^i.id^""))
            else Hashtbl.add env.vars i.id (tt, Iarg));
            (tt,i.id, Iarg)
        ) d.fun_formals in
        Hashtbl.add env.funs fun_name {fun_typ=fun_typ;fun_name=fun_name;fun_formals=fun_formals;fun_body=([],[])};
        env.block_new_index := 0;
        let fun_body = type_block env d.fun_body in
        let ttree_dfun = {
          fun_typ = fun_typ;
          fun_name = fun_name;
          fun_formals = fun_formals;
          fun_body = fun_body;
        } in
        Hashtbl.replace env.funs fun_name ttree_dfun;
        (List.iter (fun (t,i,vt) -> Hashtbl.remove env.vars i) fun_formals);
        ttree_dfun :: (aux env q)
      )
   in
   let env = {
     vars = Hashtbl.create 15;
     structs = Hashtbl.create 10;
     funs = Hashtbl.create 10;
     returnType = Ttypenull;
     block_new_index = ref 0;
   } in
   Hashtbl.add env.funs "putchar"
   {
    fun_typ = Tint;
    fun_name = "putchar";
    fun_formals = [(Tint, "c",Iarg)];
    fun_body = ([],[Sskip]);
   };
   Hashtbl.add env.funs "sbrk"
      {
       fun_typ = Tvoidstar;
       fun_name = "sbrk";
       fun_formals = [(Tint, "n",Iarg)];
       fun_body = ([],[Sskip]);
      };
   let funs = aux env p in
   (try let main_fun = Hashtbl.find env.funs "main" in
   if ((List.length main_fun.fun_formals != 0) || not(type_equiv main_fun.fun_typ Tint)) then raise (Error "incorrect main function")
   with Not_found -> raise (Error "main function missing"));
   {
     funs = funs;
   }



