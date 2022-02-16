
(** {2 Explicit Register Transfer Language (ERTL)} *)

open Ops

type ident = string
  (** uniquement pour les fonctions *)

type register = Register.t

type label = Label.t

(** Les différentes instructions ERTL *)
type instr =
  (** les mêmes que dans RTL *)
  | Econst of int32 * register * label
  | Eload of register * int * register * label
  | Estore of register * register * int * label
  | Emunop of munop * register * label
  | Embinop of mbinop * register * register * label
  | Emubranch of mubranch * register * label * label
  | Embbranch of mbbranch * register * register * label * label
  | Egoto of label
  | Ecall of ident * int * label
      (** l'entier est le nombre de paramètres passés dans des registres *)
  | Ealloc_frame of label
  | Edelete_frame of label
  | Eget_param of int * register * label
      (** [r <- ofs(rbp)] *)
  | Epush_param of register * label
  | Ereturn

type cfg = instr Label.map
  (** Un graphe de flot de contrôle est un dictionnaire associant à des
      étiquettes des instructions ERTL. *)

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

(** Une fonction ERTL. *)
type deffun = {
  fun_name : ident;
  fun_formals : int; (* nb total d'arguments *)
  fun_locals : Register.set;
  fun_entry : label;
  fun_body : cfg;
}

(** Un programme ERTL. *)
type file = {
  funs : deffun list;
}

(** {2 Quelques fonctions qui seront utiles pour la phase suivante} *)

val succ: instr -> label list
  (** successeurs dans le graphe *)

val def_use: instr -> register list * register list
  (** calcul des définitions et utilisations de chaque instruction *)

val visit: (label -> instr -> live_info -> unit) -> lg -> label -> unit
  (** visite le graphe de flot de contrôle à partir d'une étiquette donnée *)

(** {2 Fonctions d'impression, pour debugger} *)

val print_instr: Format.formatter -> instr -> unit

val print_graph: Format.formatter -> lg -> label -> unit

val print_deffun: Format.formatter -> lg -> deffun -> unit

val print_file: Format.formatter -> lg -> file -> unit
