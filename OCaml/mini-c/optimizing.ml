open Format
open IS

(* utiliser cette exception pour signaler une erreur de typage *)
exception Error of string

let full_ident ident = function
    | Ttree.Iarg -> ident^"_arg"
    |Ttree.Ilocal n -> ident^"_"^(string_of_int n)

let opt_decl_var ((t,i,vt):(_*_*Ttree.var_typ)) = full_ident i vt

let rec check_return_stmt = function
      | Sexpr e -> false
      | Sif (e,s1,s2) -> (check_return_stmt s1) && (check_return_stmt s2)
      | Swhile (e,s) -> check_return_stmt s
      | Sblock b -> check_return_block b
      | Sreturn e -> true

and check_return_block (b:block) =
    begin match List.rev b with
    | [] -> false
    | [x] -> check_return_stmt x
    | h :: t -> (check_return_stmt h) || (check_return_block t)
    end

let rec opt_locals ((dl,sl):(Ttree.decl_var list * Ttree.stmt list)) =
    let rec opt_locals_rec (sl:Ttree.stmt list) =
        begin match sl with
        | [] -> []
        | Ttree.Sblock s :: t -> List.append (opt_locals s) (opt_locals_rec t)
        | h :: t -> opt_locals_rec t
        end in
    List.append (List.map opt_decl_var dl) (opt_locals_rec sl)

(* Returns a the optimized expression *)
and opt_expr (e:Ttree.expr) =
    begin match e.expr_node with
      | Ttree.Econst n -> Econst n
      | Ttree.Eaccess_local (i,vt) -> Eaccess_shift(Evar(full_ident i vt),0)
      | Ttree.Eaccess_field (e,f) -> Eaccess_shift(opt_expr e,f.shift)
      | Ttree.Eassign_local (i,e,vt) -> Eassign_shift(Evar(full_ident i vt),0, opt_expr e)
      | Ttree.Eassign_field (e1,f,e2) -> Eassign_shift(opt_expr e1,f.shift, opt_expr e2)
      | Ttree.Eunop (Ptree.Uminus,e) -> Ebinop(Ptree.Bsub, Econst 0l, opt_expr e)
      | Ttree.Eunop (Ptree.Unot,e) -> Eunop(Unot, opt_expr e)
      | Ttree.Ebinop (Ptree.Badd,e1,e2) ->
      begin match (e1.expr_node, e2.expr_node) with
      | (Ttree.Econst n1, Ttree.Econst n2) -> Econst(Int32.add n1 n2)
      | _ -> Ebinop(Ptree.Badd, opt_expr e1, opt_expr e2)
      end
      | Ttree.Ebinop (b,e1,e2) -> Ebinop(b, opt_expr e1, opt_expr e2)
      | Ttree.Ecall (i,el) -> Ecall(i, List.map opt_expr el)
      | Ttree.Esizeof s -> Econst(Int32.mul(Int32.of_int (Hashtbl.length s.str_fields)) 64l)
    end

and opt_stmt (stmt:Ttree.stmt)=
    begin match stmt with
        | Ttree.Sexpr e -> Sexpr(opt_expr e)
        | Ttree.Sif (e,s1,s2) -> Sif (opt_expr e,opt_stmt s1,opt_stmt s2)
        | Ttree.Swhile (e,s) -> Swhile (opt_expr e,opt_stmt s)
        | Ttree.Sreturn e -> Sreturn (opt_expr e)
        | Ttree.Sblock (dl,sl) -> Sblock(opt_stmt_list sl)
        | Ttree.Sskip -> assert false
    end

and opt_stmt_list (stmts:Ttree.stmt list) =
    begin match stmts with
    | [] -> []
    | h::t ->
        begin match h with
        | Ttree.Sskip -> opt_stmt_list t
        | Ttree.Sblock b -> Sblock(opt_block b) :: (opt_stmt_list t)
        | s -> (opt_stmt s) :: (opt_stmt_list t)
        end
    end

and opt_block ((dl, sl):(Ttree.decl_var list * Ttree.stmt list)) =
    opt_stmt_list sl

and opt_decl_fun (df:Ttree.decl_fun) =
    let fun_formals = List.map opt_decl_var df.fun_formals in
    let fun_locals = opt_locals df.fun_body in
    let fun_body = opt_block df.fun_body in
    if not(check_return_block fun_body) then printf "function %s doesn't return a value\n" df.fun_name;
    (*printf "fun %s\n" df.fun_name;
    printf "args : \n";
    List.iter (fun x -> printf "%s " x) fun_formals;
    printf "\nlocals : \n";
    List.iter (fun x -> printf "%s " x) fun_locals;
    printf "\n";*)
    {
      fun_name    = df.fun_name;
      fun_formals = fun_formals;
      fun_locals  = fun_locals;
      fun_body    = fun_body;
    }

let program (p: Ttree.file) =
    let funs = List.map opt_decl_fun p.funs in
   {
     funs = funs;
   }



