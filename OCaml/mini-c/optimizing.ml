open Format
open IS

(* utiliser cette exception pour signaler une erreur de typage *)
exception Error of string

(* Returns the converted block and the list of local variables declaration *)
(*let opt_locals (b:Ttree.block) =
    let block_index = ref 0 in
    let rec inner_blocks (l:Ttree.ident list) = function
             | [] -> l
             | Ttree.Sblock (idl,isl) :: t -> block_index := !block_index + 1;let l = opt_locals_rec (idl,isl) l in inner_blocks l t
             | _ :: t -> inner_blocks l t
    and opt_locals_rec ((dl,sl):Ttree.block) (l:ident list)=
       begin
        let l = List.append l (List.map (fun (t,i) -> i^(string_of_int !block_index)) dl) in
        inner_blocks l sl
       end in
    let locals = opt_locals_rec b [] in*)

(* Returns a the optimized expression *)
let rec opt_expr (e:Ttree.expr) =
    begin match e.expr_node with
      | Ttree.Econst n -> Econst n
      | Ttree.Eaccess_local i -> Eaccess_shift(Evar(i),0)
      | Ttree.Eaccess_field (e,f) -> Econst 0l
      | Ttree.Eassign_local (i,e) -> Eassign_shift(Evar(i),0, opt_expr e)
      | Ttree.Eassign_field (e1,f,e2) -> Econst 0l
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
        | _ -> assert false
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
    let fun_formals = List.map (fun (t,i) -> i) df.fun_formals in
    {
      fun_name    = df.fun_name;
      fun_formals = fun_formals;
      fun_locals  = [];
      fun_body    = opt_block df.fun_body;
    }

let program (p: Ttree.file) =
    let funs = List.map opt_decl_fun p.funs in
   {
     funs = funs;
   }



