
open Ltltree

let graph = ref Label.M.empty

let add l i =
    graph := Label.M.add l i !graph

let lookup c r =
  if Register.is_hw r then Reg r else Register.M.find r c

let rec map_instr c frame_size il = function
  | Ertltree.Econst (n, r, l) -> add il (Econst (n, lookup c r, l))
  | Ertltree.Emunop (op, r, l) -> add il (Emunop (op, lookup c r, l))
  | Ertltree.Embinop (op, r1, r2, l) ->
  let cr1 = lookup c r1 in
  let cr2 = lookup c r2 in
  begin match op with
  | Ops.Mmov when cr1 = cr2 -> add il (Egoto l)
  | _ ->
    begin match (cr1,cr2) with
    | (Spilled i, Spilled j) ->
    let l1 = Label.fresh () in
    let l2 = Label.fresh () in
    add l1 (Embinop(Ops.Mmov, Reg Register.tmp1, cr2, l));
    add l2 (Embinop(op, cr1, Reg Register.tmp1, l1));
    add il (Embinop(Ops.Mmov, cr2, Reg Register.tmp1, l2))
    | _ -> add il (Embinop (op, cr1, cr2, l))
    end
  end
  | Ertltree.Emubranch (mu, r, l1, l2) ->
    let cr = lookup c r in
    begin match cr with
    | Spilled i ->
        let l = Label.fresh () in
        add l (Emubranch(mu, Reg Register.tmp1, l1, l2));
        add il (Embinop(Ops.Mmov, cr, Reg Register.tmp1, l))
    | _ -> add il (Emubranch (mu, lookup c r, l1, l2))
    end
  | Ertltree.Embbranch (mb, r1, r2, l1, l2) ->
  let cr1 = lookup c r1 in
  let cr2 = lookup c r2 in
  begin match (cr1,cr2) with
      | (Spilled i, Spilled j) ->
      let l = Label.fresh () in
      add l (Embbranch(mb, cr1, Reg Register.tmp1, l1, l2));
      add il (Embinop(Ops.Mmov, cr2, Reg Register.tmp1, l))
      | _ -> add il (Embbranch (mb, cr1, cr2, l1, l2))
  end
  | Ertltree.Epush_param (r, l) -> add il (Epush (lookup c r, l))
  | Ertltree.Egoto l -> add il (Egoto l)
  | Ertltree.Ereturn -> add il Ereturn
  | Ertltree.Ecall (id, n, l) -> add il (Ecall (id, l))
  | Ertltree.Eload (r1, n, r2, l) -> begin
      let pr1 = lookup c r1 and pr2 = lookup c r2 in
      match (pr1, pr2) with
        | (Reg hw1, Reg hw2) -> add il (Eload (hw1, n, hw2, l))
        | (Reg hw1, Spilled i2) -> let label_load = Label.fresh () in
                                   add label_load (Embinop(Mmov, Reg Register.tmp1, Spilled i2, l));
                                   add il (Eload (hw1, n, Register.tmp1, label_load))
        | (Spilled i1, Reg hw2) -> let label_load = Label.fresh () in
                                   add label_load (Eload (Register.tmp1, n, hw2, l));
                                   add il (Embinop(Mmov, Spilled i1, Reg Register.tmp1, label_load))
        | (Spilled i1, Spilled i2) -> let label_load1 = Label.fresh () and label_load2 = Label.fresh () in
                                      add label_load2 (Embinop (Mmov, Reg Register.tmp2, Spilled i2, l));
                                      add label_load1 (Eload (Register.tmp1, n, Register.tmp2, label_load2));
                                      add il (Embinop (Mmov, Spilled i1, Reg Register.tmp2, label_load1));
      end
  | Ertltree.Estore (r1, r2, n, l) -> begin
      let pr1 = lookup c r1 and pr2 = lookup c r2 in
      match (pr1, pr2) with
        | (Reg hw1, Reg hw2) -> add il (Estore (hw1, hw2, n, l))
        | (Reg hw1, Spilled i2) -> let label_store = Label.fresh () in
                                   add label_store (Embinop(Mmov, Reg Register.tmp1, Spilled i2, l));
                                   add il (Estore (hw1, Register.tmp1, n, label_store))
        | (Spilled i1, Reg hw2) -> let label_store = Label.fresh () in
                                   add label_store (Estore (Register.tmp1, hw2, n, l));
                                   add il (Embinop(Mmov, Spilled i1, Reg Register.tmp1, label_store))
        | (Spilled i1, Spilled i2) -> let label_store1 = Label.fresh () and label_store2 = Label.fresh () in
                                      add label_store2 (Embinop (Mmov, Reg Register.tmp2, Spilled i2, l));
                                      add label_store1 (Estore (Register.tmp1, Register.tmp2, n, label_store2));
                                      add il (Embinop (Mmov, Spilled i1, Reg Register.tmp2, label_store1));
      end
  | Ertltree.Ealloc_frame l -> if (frame_size <> 0) then
                                   let label_push_cst = Label.fresh () in
                                   let label_add_rsp = Label.fresh () and label_mov_rsp = Label.fresh () in
                                   add label_add_rsp (Embinop (Madd, Reg Register.tmp1, Reg Register.rsp, l));
                                   add label_push_cst (Econst (Int32.of_int (-8 * frame_size), Reg Register.tmp1, label_add_rsp));
                                   add label_mov_rsp (Embinop (Mmov, Reg Register.rsp, Reg Register.rbp, label_push_cst));
                                   add il (Epush (Reg Register.rbp, label_mov_rsp))
                               else
                               add il (Egoto l)
  | Ertltree.Edelete_frame l -> if (frame_size <> 0) then
                                    let label_pop_rbp = Label.fresh () in
                                    add label_pop_rbp (Epop (Register.rbp, l));
                                    add il (Embinop (Mmov, Reg Register.rbp, Reg Register.rsp, label_pop_rbp))
                                else
                                add il (Egoto l)
  | Ertltree.Eget_param (i, r, l) -> map_instr c frame_size il (Ertltree.Eload (Register.rbp, i, r, l))

let ltl_fun (f:Coloring.deffun) =
    graph := Label.M.empty;
    Label.M.iter (fun l (i:Ertltree.instr) -> map_instr f.fun_coloring f.fun_stack_count l i) f.fun_body;
    {
      fun_name = f.fun_name;
      fun_entry = f.fun_entry;
      fun_body = !graph;
    }

let program (f:Coloring.file)  =
    {
        funs = List.map ltl_fun f.funs;
    }
