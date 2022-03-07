open X86_64

let visited = Hashtbl.create 17
type instr = Code of X86_64.text | Label of Label.t
let code = ref []
let emit l i = code := Code i :: Label l :: !code
let emit_wl i = code := Code i :: !code
let emit_wi l = code := Label l :: !code
let labels = Hashtbl.create 17
let need_label l = Hashtbl.add labels l ()

let operand = function
  | Ltltree.Reg r -> reg (register64 r)
  | Ltltree.Spilled i -> ind ~ofs:(- (i + 1) * 8) rbp

let rec lin g l =
  if not (Hashtbl.mem visited l) then begin
    Hashtbl.add visited l ();
    instr g l (Label.M.find l g)
  end else begin
    need_label l;
    emit_wl (jmp (l :> string))
  end

and instr g l = function
  | Ltltree.Econst (n, op, l1) -> emit l (movq (imm32 n) (operand op)); lin g l1
  | Eload (r1, i, r2, l1) ->  emit l (movq (ind ~ofs:i (register64 r1)) (reg (register64 r2))); lin g l1
  | Estore (r1, r2, i, l1) -> emit l (movq (reg (register64 r1)) (ind ~ofs:i (register64 r2))); lin g l1
  | Egoto l1 -> if (Hashtbl.mem labels l1) then (need_label l1;emit l (jmp (l1 :> string))) else (emit_wi l;lin g l1)
  | Ereturn -> emit l ret
  | Emunop (muop, op, l1) ->
    begin match muop with
    | Maddi i -> emit l (addq (imm32 i) (operand op)); lin g l1
    | Msetei i -> emit l (testq (imm32 i) (operand op)); lin g l1
    | Msetnei i -> assert false
    end
  | Embinop (mbop, op1, op2, l1) ->
      begin match mbop with
      | Mmov -> emit l (movq (operand op1) (operand op2)); lin g l1
      | Madd -> emit l (addq (operand op1) (operand op2)); lin g l1
      | Msub -> emit l (subq (operand op1) (operand op2)); lin g l1
      | Mmul -> emit l (imulq (operand op1) (operand op2)); lin g l1
      | Mdiv -> emit (Label.fresh ()) cqto; emit l (idivq (operand op1)); lin g l1
      | Msete
      | Msetne
      | Msetl
      | Msetle
      | Msetg
      | Msetge ->
        emit l (cmpq (operand op1) (operand op2));
          begin match mbop with
          | Msete -> emit (Label.fresh ()) (sete (reg r11b));
          | Msetne -> emit (Label.fresh ()) (setne (reg r11b));
          | Msetl -> emit (Label.fresh ()) (setl (reg r11b));
          | Msetle -> emit (Label.fresh ()) (setle (reg r11b));
          | Msetg -> emit (Label.fresh ()) (setg (reg r11b));
          | Msetge -> emit (Label.fresh ()) (setge (reg r11b));
          | _ -> assert false
          end;
        emit (Label.fresh ()) (movzbq (reg r11b) r11);
        emit (Label.fresh ()) (movq (reg r11) (operand op2));
        lin g l1
      end
  | Emubranch (mub, op, l1, l2) ->
      begin match mub with
      | Mjz ->
          let r = operand op in
          emit l (testq r r);
          need_label l1;
          emit (Label.fresh ()) (je (l1 :> string));
          lin g l2;
          lin g l1;
      | Mjnz ->
          let r = operand op in
          emit l (testq r r);
          need_label l1;
          emit (Label.fresh ()) (jne (l1 :> string));
          lin g l2;
          lin g l1;
      | Mjlei i -> assert false
      | Mjgi i -> assert false
      end
  | Embbranch (mbb, op1, op2, l1, l2) ->
    begin match mbb with
    | Mjl ->
        need_label l1;
        emit l (cmpq (operand op1) (operand op2));
        emit (Label.fresh ()) (jl (l1 :> string));
        lin g l2;
        lin g l1;
    | Mjle ->
        need_label l1;
        emit l (cmpq (operand op1) (operand op2));
        emit (Label.fresh ()) (jle (l1 :> string));
        lin g l2;
        lin g l1;
    end
  | Epush (op, l1) -> emit l (pushq (operand op)); lin g l1
  | Ecall (id, l1) -> emit l1 (call id); lin g l1
  | Epop (r,l1) -> emit l (popq (register64 r)); lin g l1

let linearing_fun (df:Ltltree.deffun) =
    emit_wl (label df.fun_name);
    lin df.fun_body df.fun_entry

let program (f:Ltltree.file) =
    List.iter linearing_fun f.funs;
    let text = List.fold_right
    (fun instr txt ->
        begin match instr with
        | Label l -> if (Hashtbl.mem labels l) then txt ++ (label (l :> string)) else txt
        | Code c -> txt ++ c
        end
    )
    !code
    (globl "main")in
    {
        text = text;
        data = nop;
    }
