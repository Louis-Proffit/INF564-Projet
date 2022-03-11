
(** {2 Location Transfer Language (LTL)} *)

open Ops

type ident = string
  (** uniquement pour les fonctions *)

type register = Register.t

type label = Label.t

(** une opérande est un registre physique (Reg) ou un emplacement
    de pile (Spilled) *)
type operand =
  | Reg of Register.t
  | Spilled of int

(** Les différentes instructions LTL *)
type instr =
  (** les mêmes que dans ERTL *)
  | Eload of register * int * register * label
  | Estore of register * register * int * label
  | Egoto of label
  | Ereturn
  (** les mêmes que dans ERTL, mais avec operand à la place de register *)
  | Econst of int32 * operand * label
  | Emunop of munop * operand * label
  | Embinop of mbinop * operand * operand * label
  | Emubranch of mubranch * operand * label * label
  | Embbranch of mbbranch * operand * operand * label * label

  | Emcbranch of flag * label * label (* Binary conditional branching *)
  | Euflags of operand * label (* Set the flags of the corresponding register *)
  | Ebflags of flag * operand * operand * label (* Set the flags corresponding to two registers *)

  | Epush of operand * label
  (** légèrement modifiée *)
  | Ecall of ident * label
  (** nouveau *)
  | Epop of register * label

type cfg = instr Label.map
  (** Un graphe de flot de contrôle est un dictionnaire associant à des
      étiquettes des instructions LTL. *)

(** une fonction LTL *)
type deffun = {
  fun_name : ident;
  fun_entry: label;
  fun_body : cfg;
}

(** un programme LTL *)
type file = {
  funs : deffun list;
}

(** {2 Fonctions d'impression, pour debugger} *)

open Format
open Pp

let print_operand fmt = function
  | Reg r     -> fprintf fmt "%a" Register.print r
  | Spilled n -> fprintf fmt "%d(%%rbp)" n

let print_instr fmt = function
  | Econst (n, r, l) ->
      fprintf fmt "mov $%ld %a  --> %a" n print_operand r Label.print l
  | Eload (r1, n, r2, l) ->
      fprintf fmt "load %d(%a) %a  --> %a"
        n Register.print r1 Register.print r2 Label.print l
  | Estore (r1, r2, n, l) ->
      fprintf fmt "store %a %d(%a)  --> %a"
        Register.print r1 n Register.print r2 Label.print l
  | Emunop (op, r1, l) ->
      fprintf fmt "%a %a  --> %a" print_munop op print_operand r1 Label.print l
  | Embinop (Mmov, r1, r2, l) ->
      fprintf fmt "mov %a %a  --> %a" print_operand r1 print_operand r2 Label.print l
  | Embinop (op, r1, r2, l) ->
      fprintf fmt "%a %a %a  --> %a"
	print_mbinop op print_operand r1 print_operand r2 Label.print l
  | Emubranch (op, r, l1, l2) ->
      fprintf fmt "%a %a  --> %a, %a"
	print_mubranch op print_operand r Label.print l1 Label.print l2
  | Embbranch (op, r1, r2, l1, l2) ->
      fprintf fmt "%a %a %a  --> %a, %a"
	print_mbbranch op print_operand r1 print_operand r2
        Label.print l1 Label.print l2
  | Emcbranch (f, l1, l2) ->
      fprintf fmt "jmp-flag(%a) --> %a %a "
          print_flag f Label.print l1 Label.print l2
  | Euflags (o,l) ->
      fprintf fmt "set-flag(%a) --> %a"
          print_operand o Label.print l
  | Ebflags (f, o1, o2 ,l) ->
        fprintf fmt "set-flag(%a) for %a %a --> %a"
            Ops.print_flag f print_operand o1 print_operand o2 Label.print l
  | Epush (r, l) ->
      fprintf fmt "push %a  --> %a" print_operand r Label.print l
  | Epop (r, l) ->
      fprintf fmt "pop %a  --> %a" Register.print r Label.print l
  | Egoto l ->
      fprintf fmt "goto %a" Label.print l
  | Ecall (x, l) ->
      fprintf fmt "call %s  --> %a" x Label.print l
  | Ereturn ->
      fprintf fmt "return"

let succ = function
  | Econst (_,_,l)
  | Eload (_,_,_,l)
  | Estore (_,_,_,l)
  | Emunop (_,_,l)
  | Embinop (_,_,_,l)
  | Epush (_,l)
  | Epop (_,l)
  | Ecall (_,l)
  | Euflags (_,l)
  | Ebflags (_,_,_,l)
  | Egoto l ->
      [l]
  | Emubranch (_,_,l1,l2)
  | Embbranch (_,_,_,l1,l2)
  | Emcbranch (_,l1,l2) ->
      [l1; l2]
  | Ereturn ->
      []

let visit f g entry =
  let visited = Hashtbl.create 97 in
  let rec visit l =
    if not (Hashtbl.mem visited l) then begin
      Hashtbl.add visited l ();
      let i = Label.M.find l g in
      f l i;
      List.iter visit (succ i)
    end
  in
  visit entry

let print_graph fmt =
  visit (fun l i -> fprintf fmt "%a: %a@\n" Label.print l print_instr i)

let print_deffun fmt f =
  fprintf fmt "%s()@\n" f.fun_name;
  fprintf fmt "  @[";
  fprintf fmt "entry : %a@\n" Label.print f.fun_entry;
  print_graph fmt f.fun_body f.fun_entry;
  fprintf fmt "@]@."

let print_file fmt p =
  fprintf fmt "=== LTL ==================================================@\n";
  List.iter (print_deffun fmt) p.funs
