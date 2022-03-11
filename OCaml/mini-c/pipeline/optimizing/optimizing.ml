open Format
open IS

(* utiliser cette exception pour signaler une erreur de typage *)
exception Error of string

let typ_size = function
    | Ttree.Tint
    | Ttree.Ttypenull
    | Ttree.Tvoidstar -> 8l
    | Ttree.Tpointer t -> 8l
    | Ttree.Tstruct s -> Int32.of_int (8 * (Hashtbl.length s.str_fields))

let rec check_return_stmt = function
      | Sskip -> false
      | Sexpr e -> false
      | Sifelse (e,s1,s2) -> (check_return_stmt s1) && (check_return_stmt s2)
      | Sif (e,s) -> false
      | Swhile (e,s) -> check_return_stmt s
      | Sblock b -> check_return_block b
      | Sreturn e -> true

and check_return_block (b:block) =
    begin match List.rev b with
    | [] -> false
    | [x] -> check_return_stmt x
    | h :: t -> (check_return_stmt h) || (check_return_block t)
    end

let full_ident ident = function
    | Ttree.Iarg -> ident^"_arg"
    | Ttree.Ilocal n -> ident^"_"^(string_of_int n)

let map_decl_var ((t,i,vt):(Ttree.typ*Ttree.ident*Ttree.var_typ)) = full_ident i vt

let rec map_locals (b:Ttree.block) =
    let rec map_locals_in_block = function
        | (dl,sl) -> List.append (List.map map_decl_var dl) (map_locals_in_stmt_list sl)
    and map_locals_in_stmt_list = function
        | [] -> []
        | h :: t -> List.append (map_locals_in_stmt h) (map_locals_in_stmt_list t)
    and map_locals_in_stmt = function
        | Ttree.Sskip -> []
        | Ttree.Sexpr e -> []
        | Ttree.Sif (e,s1,s2) -> List.append (map_locals_in_stmt s1) (map_locals_in_stmt s2)
        | Ttree.Swhile (e,s) -> map_locals_in_stmt s
        | Ttree.Sreturn e -> []
        | Ttree.Sblock b -> map_locals_in_block b
    in map_locals_in_block b

(* Returns a the optimized expression *)
and map_expr (e:Ttree.expr) =
    opt_expr begin match e.expr_node with
      | Ttree.Econst n -> Econst n
      | Ttree.Eaccess_local (i,vt) -> Eaccess_local(full_ident i vt)
      | Ttree.Eaccess_field (e,f) -> Eaccess_shift(map_expr e, 8 * f.shift)
      | Ttree.Eassign_local (i,e,vt) -> Eassign_local(full_ident i vt, map_expr e)
      | Ttree.Eassign_field (e1,f,e2) -> Eassign_shift(map_expr e1, 8 * f.shift, map_expr e2)
      | Ttree.Eaccess_memory e -> Eaccess_shift(map_expr e, 0)
      | Ttree.Eassign_memory (e1,e2) -> Eassign_shift(map_expr e1, 0, map_expr e2)
      | Ttree.Eunop (u,e) -> Eunop(u, map_expr e)
      | Ttree.Ebinop (Ptree.Badd,e1,e2) -> Ebinop(Ptree.Badd, map_expr e1, map_expr e2)
      | Ttree.Ebinop (b,e1,e2) -> Ebinop(b, map_expr e1, map_expr e2)
      | Ttree.Ecall (i,el) -> Ecall(i, List.map map_expr el)
      | Ttree.Esizeof t -> Econst(typ_size t)
    end

and opt_expr = function
    | Eaccess_shift (e,i) -> Eaccess_shift (opt_expr e,i)
    | Eassign_shift (e1,i,e2) -> Eassign_shift (opt_expr e1,i,opt_expr e2)
    | Eunop (u,e) ->
    begin match u with
        | Uminus ->
        begin match e with
            | Econst n -> Econst (Int32.neg n)
            | _ -> Ebinop(Bsub,Econst 0l,opt_expr e)
        end
        | Unot ->
        begin match e with
            | Econst 0l -> Econst 1l
            | Econst x -> Econst 0l
            | Ebinop (Blt, e1, e2) -> opt_expr (Ebinop(Bge, e1, e2))
            | Ebinop (Ble, e1, e2) -> opt_expr (Ebinop(Bgt, e1, e2))
            | Ebinop (Bgt, e1, e2) -> opt_expr (Ebinop(Ble, e1, e2))
            | Ebinop (Bge, e1, e2) -> opt_expr (Ebinop(Blt, e1, e2))
            | _ -> Eunop(u, opt_expr e)
        end
    end
    | Ebinop (b, Econst n1, Econst n2) ->
        begin match b with
        | Badd -> Econst(Int32.add n1 n2)
        | Bsub -> Econst(Int32.sub n1 n2)
        | Bmul -> Econst(Int32.mul n1 n2)
        | Bdiv -> (try Econst (Int32.div n1 n2) with Division_by_zero -> Ebinop (Bdiv, Econst n1, Econst n2))
        | Beq -> Econst(Int32.div n1 n2)
        | Bneq -> Econst(Int32.div n1 n2)
        | Blt -> if (n1 < n2) then Econst(1l) else Econst(0l)
        | Bgt -> if (n1 > n2) then Econst(1l) else Econst(0l)
        | Bge -> if (n1 >= n2) then Econst(1l) else Econst(0l)
        | Ble -> if (n1 <= n2) then Econst(1l) else Econst(0l)
        | Band -> if (Int32.equal n1 0l) then Econst(0l) else (if (Int32.equal n2 0l) then Econst(0l) else Econst(1l))
        | Bor -> if (Int32.equal n1 0l) then (if (Int32.equal n2 0l) then Econst(0l) else Econst(1l)) else Econst(1l)
        end
    | Ebinop (b,e1,e2) -> Ebinop (b,opt_expr e1,opt_expr e2)
    | x -> x

and map_stmt (stmt:Ttree.stmt)=
    opt_stmt begin match stmt with
        | Ttree.Sexpr e -> Sexpr(map_expr e)
        | Ttree.Sif (e,s,Sblock (dl,[])) -> Sif (map_expr e,map_stmt s)
        | Ttree.Sif (e,s,Sskip) -> Sif (map_expr e,map_stmt s)
        | Ttree.Sif (e,Sblock (dl,[]),s) -> Sif (Eunop(Unot, map_expr e),map_stmt s)
        | Ttree.Sif (e,Sskip,s) -> Sif (Eunop(Unot, map_expr e),map_stmt s)
        | Ttree.Sif (e,s1,s2) -> Sifelse (map_expr e,map_stmt s1,map_stmt s2)
        | Ttree.Swhile (e,s) -> Swhile (map_expr e,map_stmt s)
        | Ttree.Sreturn e -> Sreturn (map_expr e)
        | Ttree.Sblock (dl,sl) -> Sblock(map_stmt_list sl)
        | Ttree.Sskip -> assert false
    end

and opt_stmt = function
    | Sifelse (Eunop (Unot, e),s1,s2) -> Sifelse(e,s2,s1)
    | x -> x

and map_stmt_list (stmts:Ttree.stmt list) =
    begin match stmts with
    | [] -> []
    | h::t ->
        begin match h with
        | Ttree.Sskip -> map_stmt_list t
        | Ttree.Sblock b -> Sblock(map_block b) :: (map_stmt_list t)
        | s -> (map_stmt s) :: (map_stmt_list t)
        end
    end

and map_block ((dl, sl):(Ttree.decl_var list * Ttree.stmt list)) =
    map_stmt_list sl

and map_decl_fun (df:Ttree.decl_fun) =
    let fun_formals = List.map map_decl_var df.fun_formals in
    let fun_locals = map_locals df.fun_body in
    let fun_body = map_block df.fun_body in
    if not(check_return_block fun_body) then printf "function %s doesn't return a value\n" df.fun_name;
    {
      fun_name    = df.fun_name;
      fun_formals = fun_formals;
      fun_locals  = fun_locals;
      fun_body    = fun_body;
    }

let program (p: Ttree.file) =
   {
     funs = List.map map_decl_fun p.funs;
   }



