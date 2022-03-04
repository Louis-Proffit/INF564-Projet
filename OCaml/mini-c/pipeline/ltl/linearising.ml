open X86_64

let visited = Hashtbl.create 17
type instr = Code of X86_64.text | Label of Label.t
let code = ref []
let emit l i = code := Code i :: Label l :: !code
let emit_wl i = code := Code i :: !code
let labels = Hashtbl.create 17
let need_label l = Hashtbl.add labels l ()

let operand = function
  | Ltltree.Reg r -> reg (register64 r)
  | _ -> assert false

let rec lin g l =
  if not (Hashtbl.mem visited l) then begin
    Hashtbl.add visited l ();
    instr g l (Label.M.find l g)
  end else begin
    need_label l;
    emit_wl (jmp (l :> string))
  end

and instr g l = function
  | Ltltree.Econst (n, r, l1) ->
      emit l (movq (imm32 n) (operand r)); lin g l1
  | _ -> assert false

let linearing_fun (df:Ltltree.deffun) =
    lin df.fun_body df.fun_entry

let program (f:Ltltree.file) =
    List.iter linearing_fun f.funs;
    {
        text = [];
        data = [];
    }
