
type ident = string

type label = Label.t

type register = Register.t

type instr = Ertltree.instr

type cfg = instr Label.map

type live_info = {
         instr: instr;
          succ: Label.t list;
  mutable pred: Label.set;
          defs: Register.set;
          uses: Register.set;
  mutable  ins: Register.set;
  mutable outs: Register.set;
}

type lg = live_info Label.map

type arcs
type igraph

type color = Ltltree.operand
type coloring = color Register.map

type deffun = {
               fun_name : ident;
               fun_entry : label;
               fun_body : cfg;
               fun_stack_count : int;
               fun_coloring : coloring;
           }

type file = {
    funs : deffun list
}

val program : Ertltree.file -> file

val print : Format.formatter -> coloring -> unit
