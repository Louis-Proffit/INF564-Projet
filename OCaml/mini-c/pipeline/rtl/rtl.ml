open Rtltree
open Ops
open Format

let graph = ref Label.M.empty
let var_reg_map = Hashtbl.create 15

let generate i =
    let l = Label.fresh () in
    graph := Label.M.add l i !graph;
    l

let rec expr e destr destl =
    begin match e with
    | IS.Econst n -> generate (Econst (n, destr, destl))
    | IS.Eaccess_local i -> generate (Embinop (Mmov, Hashtbl.find var_reg_map i, destr, destl))
    | IS.Eaccess_shift (e,i) ->
    let reg = Register.fresh () in let label = generate (Eload(reg,i,destr,destl)) in expr e reg label
    | IS.Eassign_local (i,e) ->
    let var_reg = (Hashtbl.find var_reg_map i) in
    let expr_label = generate (Embinop(Mmov, var_reg, destr, destl)) in
    expr e var_reg expr_label
    | IS.Eassign_shift (e1,i,e2) ->
    let adress_reg = Register.fresh () in
    let label1 = generate (Estore(destr,adress_reg,i,destl)) in
    let label2 = expr e1 adress_reg label1 in
    expr e2 destr label2
    | IS.Ebinop(Band, e1, e2) ->
        let label_expr_2 = expr e2 destr destl in
        let label_jmp = generate (Emcbranch(Me, destl, label_expr_2)) in
        let label_flag = generate (Euflags(destr, label_jmp)) in
    expr e1 destr label_flag
    | IS.Ebinop(Bor, e1, e2) ->
        let label_expr_2 = expr e2 destr destl in
        let label_jmp = generate (Emcbranch(Mne, destl, label_expr_2)) in
        let label_flag = generate (Euflags(destr, label_jmp)) in
        expr e1 destr label_flag
    | IS.Ebinop(b, e1, e2) ->
    let reg = Register.fresh () in
    let label_add = generate (
    Embinop(
        begin
        match b with
            | Badd ->Madd
            | Bsub ->Msub
            | Bmul ->Mmul
            | Bdiv ->Mdiv
            | Beq -> Msete
            | Bneq -> Msetne
            | Blt -> Msetl
            | Ble -> Msetle
            | Bgt -> Msetg
            | Bge -> Msetge
            | Band | Bor -> assert false
        end, reg, destr, destl))
    in let label2 = expr e2 reg label_add in
    expr e1 destr label2
    | Ecall (i,el) ->
    let regs = List.init (List.length el) (fun x -> Register.fresh ()) in
    let nextl = generate (Ecall(destr, i, regs, destl)) in
    List.fold_right2 (fun e reg nextl -> expr e reg nextl) el regs nextl
    | Eunop (u,e) ->
        begin match u with
        | Unot ->
        let label = generate (Emunop(Msetei 0l, destr, destl)) in
        expr e destr label
        | Uminus ->
        let expr_reg = Register.fresh () in
        let label = generate (Embinop(Msub, expr_reg, destr, destl)) in
        let label1 = generate (Econst(0l,destr, label)) in
        expr e expr_reg label1
        end
    end


(*
destl est le label à suivre à la fin de l'instruction
retr est le registre ou mettre le retour de la fonction
exitl est le label à suivre après le return
*)
and stmt s destl retr exitl =
    begin match s with
    | IS.Sskip -> exitl
    | IS.Sreturn e -> expr e retr exitl
    | IS.Sifelse (e,s1,s2) ->
        let expr_reg = Register.fresh () in
        let stmt_label_1 = stmt s1 destl retr exitl in
        let stmt_label_2 = stmt s2 destl retr exitl in
        let label_jmp = generate(Emcbranch(Me, stmt_label_2, stmt_label_1)) in
        let label_flag = generate(Euflags(expr_reg, label_jmp)) in
        expr e expr_reg label_flag
    | IS.Sif (e,s) ->
        begin match e with
        | IS.Ebinop(b, e1, e2) when b <> Band && b <> Bor ->
            let expr_reg_1 = Register.fresh () in
            let expr_reg_2 = Register.fresh () in
            let stmt_label = stmt s destl retr exitl in
            let label_jmp =
            begin match b with
                | Badd -> generate(Embinop(Madd, expr_reg_1, expr_reg_2, (generate(Emcbranch(Mne, stmt_label, destl)))))
                | Bsub -> generate(Embinop(Msub, expr_reg_1, expr_reg_2, (generate(Emcbranch(Mne, stmt_label, destl)))))
                | Bmul -> generate(Embinop(Mmul, expr_reg_1, expr_reg_2, (generate(Emcbranch(Mne, stmt_label, destl)))))
                | Bdiv -> generate(Embinop(Mdiv, expr_reg_1, expr_reg_2, (generate(Emcbranch(Mne, stmt_label, destl)))))
                | Beq -> generate(Ebflags(expr_reg_1, expr_reg_2, (generate(Emcbranch(Me, stmt_label, destl)))))
                | Bneq -> generate(Ebflags(expr_reg_1, expr_reg_2, (generate(Emcbranch(Mne, stmt_label, destl)))))
                | Blt -> generate(Ebflags(expr_reg_1, expr_reg_2, (generate(Emcbranch(Mg, stmt_label, destl)))))
                | Ble -> generate(Ebflags(expr_reg_1, expr_reg_2, (generate(Emcbranch(Mge, stmt_label, destl)))))
                | Bgt -> generate(Ebflags(expr_reg_1, expr_reg_2, (generate(Emcbranch(Ml, stmt_label, destl)))))
                | Bge -> generate(Ebflags(expr_reg_1, expr_reg_2, (generate(Emcbranch(Mle, stmt_label, destl)))))
            end in
            let label_expr = expr e2 expr_reg_2 label_jmp in
            expr e1 expr_reg_1 label_expr
        | _ ->
            let expr_reg = Register.fresh () in
            let stmt_label = stmt s destl retr exitl in
            let label_jmp = generate(Emcbranch(Me, destl, stmt_label)) in
            let label_flag = generate(Euflags(expr_reg, label_jmp)) in
            expr e expr_reg label_flag
        end
    | IS.Swhile (e,s) ->
        let expr_reg = Register.fresh () in
        let flag_label = Label.fresh () in
        let expr_label = expr e expr_reg flag_label in
        let stmt_label = stmt s expr_label retr exitl in
        let jmp_label = generate (Emcbranch(Me, destl, stmt_label)) in
        graph := Label.M.add flag_label (Euflags(expr_reg, jmp_label)) !graph;
        generate (Egoto expr_label)
    | IS.Sblock b -> stmt_list b destl retr exitl
    | IS.Sexpr e -> expr e (Register.fresh ()) destl
    end

and stmt_list sl destl retr exitl =
    begin match sl with
    | [] -> destl
    | h :: t ->
        let destl = stmt_list t destl retr exitl in
        stmt h destl retr exitl
    end

and deffun (df:IS.decl_fun) =
    Hashtbl.reset var_reg_map;
    graph := Label.M.empty;
    let fun_result  = Register.fresh () in
    let fun_exit    = Label.fresh () in
    let fun_formals = List.map (fun i -> let reg = Register.fresh () in Hashtbl.add var_reg_map i reg; reg) df.fun_formals in
    let fun_locals  = List.map (fun i -> let reg = Register.fresh () in Hashtbl.add var_reg_map i reg; reg) df.fun_locals in
    let fun_entry   = stmt_list df.fun_body fun_exit fun_result fun_exit in
    let result = {
      fun_name   = df.fun_name;
      fun_formals= fun_formals;
      fun_result = fun_result;
      fun_locals = Register.set_of_list fun_locals;
      fun_entry  = fun_entry;
      fun_exit   = fun_exit;
      fun_body   = !graph;
    } in
    (result)

let program (f:IS.file) =
{
  funs = List.map deffun f.funs;
}
