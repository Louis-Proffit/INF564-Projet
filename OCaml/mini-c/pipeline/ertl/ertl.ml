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
        | ([],[]) -> label (* Params can't be empty while there are still arguments *)
        | (_,[]) -> assert false
        | ([], _) -> label
        | (reg :: q1, param :: q2) ->
            let mov_label = Label.fresh () in
            add mov_label (Embinop (Mmov, reg, param, label));
            mov_arg_reg q1 q2 mov_label
        end in
    let rec mov_arg_stack regs label count =
        begin match (regs, count) with
        | (_,0) -> mov_arg_reg (List.rev regs) Register.parameters label
        | ([], _) -> assert false
        | (r :: q, c) ->
            let push_label = Label.fresh () in
            add push_label (Epush_param (r, label));
            mov_arg_stack q push_label (c - 1)
        end in
    let mov_arg_label = mov_arg_stack (List.rev rl) call_label count_on_stack in
    add il (Egoto mov_arg_label)
    | Rtltree.Egoto l -> add il (Egoto l)

let map_fun (f:Rtltree.deffun) =
    graph := Label.M.empty;

    let entry_label = Label.fresh () in
    let allocate_frame_label = Label.fresh() in

    let arg_count = List.length f.fun_formals in
    let args_on_stack = max (arg_count - 6) 0 in

    let callee_saved_regs = List.map (fun x -> Register.fresh ()) Register.callee_saved in

    let rec args_to_reg args regs label =
        begin match (args, regs) with
        | ([], _) -> label
        | (_,[]) -> assert false
        | (arg::q1, reg::q2) ->
            let new_label = Label.fresh () in
            add new_label (Embinop(Mmov, reg, arg, label));
            args_to_reg q1 q2 new_label
        end in

    let rec args_to_stack args label count =
        begin match (List.rev args, count) with
        | (_,0) -> args_to_reg (List.rev args) Register.parameters label
        | ([], _) -> assert false
        | (arg::q, c) ->
            let new_label = Label.fresh () in
            add new_label (Eget_param (count, arg, label));
            args_to_stack q new_label (c - 1)
        end in

    let get_args_label = args_to_stack f.fun_formals f.fun_entry args_on_stack in

    let save_callee_saved_regs_label = List.fold_right2
    (fun mreg reg label ->
        let new_label = Label.fresh () in
        add new_label (Embinop(Mmov, reg, mreg, label));
        new_label)
    callee_saved_regs Register.callee_saved get_args_label in

    add allocate_frame_label (Ealloc_frame save_callee_saved_regs_label);
    add entry_label (Egoto allocate_frame_label);

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
        fun_entry = entry_label;
        fun_body = !graph;
    }


let program (t:Rtltree.file) =
    {
        funs=List.map map_fun t.funs;
    }