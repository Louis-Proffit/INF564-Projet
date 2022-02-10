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
    let label_test = generate (Emubranch(Mjz, destr, destl, label_expr_2)) in
    expr e1 destr label_test
    | IS.Ebinop(Bor, e1, e2) ->
    let label_expr_2 = expr e2 destr destl in
    let label_test = generate (Emubranch(Mjnz, destr, destl, label_expr_2)) in
    expr e1 destr label_test
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


and stmt s destl retr exitl =
    begin match s with
    | IS.Sskip -> exitl
    | IS.Sreturn e -> expr e retr exitl
    | IS.Sifelse (e,s1,s2) ->
    let expr_reg = Register.fresh () in
    let label2 = stmt s2 destl retr exitl in
    let label1 = stmt s1 destl retr exitl in
    let label_comp = generate (Emubranch(Mjnz,expr_reg,label1, label2)) in
    expr e expr_reg label_comp
    | IS.Sif (e,s) ->
    let expr_reg = Register.fresh () in
    let stmt_label = stmt s destl retr exitl in
    let label_comp = generate (Emubranch(Mjnz,expr_reg,stmt_label, destl)) in
    expr e expr_reg label_comp
    | IS.Swhile (e,s) ->
    let expr_reg = Register.fresh () in
    let test_label = Label.fresh () in
    let expr_label = expr e expr_reg test_label in
    let stmt_label = stmt s expr_label retr exitl in
    graph := Label.M.add test_label (Emubranch (Mjnz, expr_reg, stmt_label, destl)) !graph;
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