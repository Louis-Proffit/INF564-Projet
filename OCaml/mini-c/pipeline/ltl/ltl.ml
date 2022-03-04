
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
  | _ -> add il (Embinop (op, cr1, cr2, l))
  end
  | Ertltree.Emubranch (mu, r, l1, l2) -> add il (Emubranch (mu, lookup c r, l1, l2))
  | Ertltree.Embbranch (mb, r1, r2, l1, l2) -> add il (Embbranch (mb, lookup c r1, lookup c r2, l1, l2))
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
  | Ertltree.Ealloc_frame l -> let label_push_rbp = Label.fresh () in
                               add label_push_rbp (Epush (Reg Register.rbp, l));
                               if frame_size <> 0 then
                                 let label_chg_rsp = Label.fresh () and label_chg_rbp = Label.fresh () in
                                 add label_chg_rbp (Embinop (Mmov, Reg Register.rsp, Reg Register.rbp, label_push_rbp));
                                 add label_chg_rsp (Embinop (Madd, Reg Register.tmp1, Reg Register.rsp, label_chg_rbp));
                                 add il (Econst (Int32.of_int (8 * frame_size), Reg Register.tmp1, label_chg_rsp))
                               else add il (Embinop (Mmov, Reg Register.rsp, Reg Register.rbp, label_push_rbp))
  | Ertltree.Edelete_frame l -> let label_pop_rbp = Label.fresh () in
                                add label_pop_rbp (Epop (Register.rbp, l));
                                add il (Embinop (Mmov, Reg Register.rbp, Reg Register.rsp, label_pop_rbp))
  | Ertltree.Eget_param (i, r, l) -> map_instr c frame_size il (Ertltree.Eload (Register.rbp, i, r, l))


let ltl_fun (c:Graph.coloring) (f:Ertltree.liveness_fun) =
    graph := Label.M.empty;
    Label.M.iter (fun l (li:Ertltree.live_info) -> map_instr c 0 l li.instr) f.live_info;
    let fun_def = f.fun_def in
    {
      fun_name = fun_def.fun_name;
      fun_entry = fun_def.fun_entry;
      fun_body = !graph;
    }

let program (c:Graph.coloring) (f:Ertltree.liveness_file)  =
    {
        funs = List.map (ltl_fun c) f.funs_info;
    }
