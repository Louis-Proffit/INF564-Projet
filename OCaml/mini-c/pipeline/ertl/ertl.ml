open Ertltree
open Format

let graph = ref Label.M.empty
let add l i = graph := Label.M.add l i !graph

let map_instr il = function
    | Rtltree.Econst (i,r,l) -> add il (Econst(i,r,l))
    | Rtltree.Eload (r1, i, r2, l) -> add il (Eload(r1,i,r2,l))
    | Rtltree.Estore (r1,r2,i,l) -> add il (Estore (r1,r2,i,l))
    | Rtltree.Emunop (mu,r,l) -> add il (Emunop (mu,r,l))
    | Rtltree.Embinop (Mdiv,r1,r2,l) ->
    let label_mov_end = Label.fresh () in
    let label_div = Label.fresh () in
    add label_mov_end (Embinop(Mmov, Register.rax, r2, l));
    add label_div (Embinop(Mdiv, r1, Register.rax, label_mov_end));
    add il (Embinop(Mmov, r2, Register.rax, label_div));
    | Rtltree.Embinop (mn,r1,r2,l) -> add il (Embinop (mn,r1,r2,l))
    | Rtltree.Emubranch (mu,r,l1,l2) -> add il (Emubranch (mu,r,l1,l2))
    | Rtltree.Embbranch (mb,r1,r2,l1,l2) -> add il (Embbranch (mb,r1,r2,l1,l2))
    | Rtltree.Ecall (r,i,rl,l) ->
    let count_on_stack = max ((List.length rl) - 6) 0 in
    let count_on_reg = (List.length rl) - count_on_stack in
    let label_pop_args = Label.fresh () in
    let stack_pointer_shift_reg = Register.fresh () in
    let stack_pointer_shift_label = Label.fresh () in
    let move_result_label = Label.fresh () in
    let call_label = Label.fresh () in
    add label_pop_args (Embinop(Msub, stack_pointer_shift_reg, Register.rsp, l));
    add stack_pointer_shift_label (Econst(Int32.of_int (8 * count_on_stack), stack_pointer_shift_reg, label_pop_args));
    add move_result_label (Embinop(Mmov, Register.result, r, stack_pointer_shift_label));
    add call_label (Ecall(i, count_on_reg, move_result_label));
    let rec mov_arg_reg regs params label =
        begin match (regs, params) with
        | (_,[]) -> label
        | ([], _) -> label
        | (reg :: q1, param :: q2) ->
            let mov_label = Label.fresh () in
            add mov_label (Embinop (Mmov, reg, param, label));
            mov_arg_reg q1 q2 mov_label
        end in

    let rec truncate n l =
      begin match (n, l) with
        | (0, _) -> l
        | (_, []) -> assert false
        | (n, t :: q) -> truncate (n-1) q
      end in

    let rec mov_arg_stack regs label =
        begin match regs with
        | [] -> label
        | r :: q ->
            let push_label = Label.fresh () in
            add push_label (Epush_param (r, label));
            mov_arg_stack q push_label
        end in

    if count_on_stack > 0
       then let mov_stack_label = mov_arg_stack (truncate 6 rl) call_label
            in let mov_reg_label = mov_arg_reg rl Register.parameters mov_stack_label
                in add il (Egoto mov_reg_label)
       else let mov_reg_label = mov_arg_reg rl Register.parameters call_label
                in add il (Egoto mov_reg_label)
    | Rtltree.Egoto l -> add il (Egoto l)

let map_fun (f:Rtltree.deffun) =
    graph := Label.M.empty;

    let allocate_frame_label = Label.fresh() in

    let arg_count = List.length f.fun_formals in
    let args_on_stack = max (arg_count - 6) 0 in

    let callee_saved_regs = List.map (fun _ -> Register.fresh ()) Register.callee_saved in

    let rec args_to_reg args regs label =
        begin match (args, regs) with
        | ([], _) -> label
        | (_,[]) -> assert false
        | (arg::q1, reg::q2) ->
            let new_label = Label.fresh () in
            add new_label (Embinop(Mmov, reg, arg, label));
            args_to_reg q1 q2 new_label
        end in

    let rec args_to_stack args label count = (* args is passed as a reverted list *)
        begin match (args, count) with
        | (_,0) -> args_to_reg (List.rev args) Register.parameters label
        | ([], _) -> assert false
        | (arg::q, c) ->
            let new_label = Label.fresh () in
            add new_label (Eget_param (c - 1, arg, label));
            args_to_stack q new_label (c - 1)
        end in

    let get_args_label = args_to_stack (List.rev f.fun_formals) f.fun_entry args_on_stack in

    let save_callee_saved_regs_label = List.fold_right2
    (fun mreg reg label ->
        let new_label = Label.fresh () in
        add new_label (Embinop(Mmov, reg, mreg, label));
        new_label)
    callee_saved_regs Register.callee_saved get_args_label in

    add allocate_frame_label (Ealloc_frame save_callee_saved_regs_label);

    (* Work on the body of the function *)
    Label.M.iter map_instr f.fun_body;

    let return_label = Label.fresh () in
    let delete_frame_label = Label.fresh () in
    add return_label Ereturn;
    add delete_frame_label (Edelete_frame return_label);
    let restore_callee_regs_label = List.fold_right2
    (fun mreg reg label ->
        let new_label = Label.fresh () in
        add new_label (Embinop(Mmov, mreg, reg, label));
        new_label)
    callee_saved_regs Register.callee_saved delete_frame_label in
    add f.fun_exit (Embinop(Mmov, f.fun_result, Register.result, restore_callee_regs_label));
    {
        fun_name = f.fun_name;
        fun_formals = List.length f.fun_formals;
        fun_locals = f.fun_locals;
        fun_entry = allocate_frame_label;
        fun_body = !graph;
    }


let program (t:Rtltree.file) =
    {
        funs=List.map map_fun t.funs;
    }
