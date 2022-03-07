
open Format

type ident = string

type label = Label.t

type instr = Ertltree.instr

type register = Register.t

type cfg = Ertltree.instr Label.map

type live_info = {
         instr: Ertltree.instr;
          succ: label list;
  mutable pred: Label.set;
          defs: Register.set;
          uses: Register.set;
  mutable  ins: Register.set;
  mutable outs: Register.set;
}

type lg = live_info Label.map

type arcs = { mutable prefs: Register.set; mutable intfs: Register.set }
type igraph = arcs Register.map

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
    funs : deffun list;
}


(* ---------------------------------- *)

let graph = ref Register.M.empty
let lg = ref Label.M.empty

let add lg l li = lg := Label.M.add l li !lg

let liveness_succ_def_use lg (l:Label.M.key) (i:Ertltree.instr) =
    let defs, uses = Ertltree.def_use i in
    let succ = Ertltree.succ i in
    add lg l {
      instr = i;
      succ = succ;
      pred = Label.S.empty;
      defs = Register.S.of_list defs;    (* définitions *)
      uses = Register.S.of_list uses;    (* utilisations *)
      ins = Register.S.empty;    (* variables vivantes en entrée *)
      outs = Register.S.empty;    (* variables vivantes en sortie *)
    }

let liveness_pred lg (l:Label.M.key) (li:live_info) =
    Label.M.iter (fun il mli -> if (List.mem l mli.succ) then li.pred <- (Label.S.add il li.pred)) !lg

let outs lg li =
    let s = ref Register.S.empty in
    List.iter (fun l -> s := Register.S.union !s (Label.M.find l !lg).ins) li.succ;
    !s

let ins lg li =
    Register.S.union li.uses (Register.S.diff li.outs li.defs)

let rec killdal lg ws =
    if (Label.S.is_empty !ws) then () else
    let l = Label.S.choose !ws in
    ws := Label.S.remove l !ws;
    let li = Label.M.find l !lg in
    let old_in = (Label.M.find l !lg).ins in
    li.outs <- outs lg li;
    li.ins <- ins lg li;
    begin if not (Register.S.equal old_in li.ins) then ws := Label.S.union !ws li.pred end;
    killdal lg ws

let liveness lg (f:Ertltree.deffun) =
    Label.M.iter (liveness_succ_def_use lg) f.fun_body;
    Label.M.iter (liveness_pred lg) !lg;
    let ws = ref Label.S.empty in
    Label.M.iter (fun l li -> ws := Label.S.add l !ws;()) !lg;
    killdal lg ws

let print_set = Register.print_set

let print_live_info fmt li =
  fprintf fmt "d={%a}@ u={%a}@ i={%a}@ o={%a}"
    print_set li.defs print_set li.uses print_set li.ins print_set li.outs

let print_graph_li fmt =
    Ertltree.visit (fun l i -> printf "%s\n" (l :> string);let li = Label.M.find l !lg in fprintf fmt "  %a: %a -> %a\n" Label.print l Ertltree.print_instr i print_live_info li)

(**
Adds a preference edge (twice, to be undirected)
*)
let add_pref r1 r2 =
    let arc1 = try Register.M.find r1 !graph with Not_found -> (let arc1 = {prefs=Register.S.empty;intfs=Register.S.empty} in graph := Register.M.add r1 arc1 !graph;arc1) in
    arc1.prefs<-Register.S.add r2 arc1.prefs;
    let arc2 = try Register.M.find r2 !graph with Not_found -> (let arc2 = {prefs=Register.S.empty;intfs=Register.S.empty} in graph := Register.M.add r2 arc2 !graph;arc2) in
    arc2.prefs<-Register.S.add r1 arc2.prefs

(**
Adds a interference edge (twice, to be undirected)
*)
let add_intf (r1:Register.t) (r2:Register.t) =
    (*print_string (r1 :> string);
    print_string " ";
    print_endline (r2 :> string);*)
    let arc1 = try Register.M.find r1 !graph with Not_found -> (let arc1 = {prefs=Register.S.empty;intfs=Register.S.empty} in graph := Register.M.add r1 arc1 !graph;arc1) in
    arc1.intfs<-Register.S.add r2 arc1.intfs;
    let arc2 = try Register.M.find r2 !graph with Not_found -> (let arc2 = {prefs=Register.S.empty;intfs=Register.S.empty} in graph := Register.M.add r2 arc2 !graph;arc2) in
    arc2.intfs<-Register.S.add r1 arc2.intfs;
    arc1.prefs<-Register.S.remove r2 arc1.prefs;
    arc2.prefs<-Register.S.remove r1 arc2.prefs

(**
Adds preference edges for that instruction
*)
let label_preference (li:live_info) =
    begin match li.instr with
    | Ertltree.Embinop(Mmov,r1,r2,_) -> if r1<>r2 then add_pref r1 r2
    | _ -> ()
    end

(**
Adds interference edges for that instruction
*)
let label_interference (li:live_info) =
    begin match li.instr with
    | Ertltree.Embinop(Mmov,r1,r2,_) ->
        Register.S.iter
        begin fun x ->
            Register.S.iter
            begin fun y ->
                if (r2 <> x || r1 <> y) && (r1 <> x || r2 <> y) && (x <> y) then (add_intf x y)
            end
            li.outs
        end
        li.defs
    | _ ->
        Register.S.iter
        begin fun x ->
            Register.S.iter
            begin fun y ->
                if (x <> y) then (add_intf x y)
            end
            li.outs
        end
        li.defs
    end

(**
Adds all interference and preference labels
*)
let make lg =
    graph := Register.M.empty;
    Label.M.iter (fun l li -> label_preference li) lg;
    Label.M.iter (fun l li -> label_interference li) lg

(**
Colors the graph
*)
let color ig =
    let rec color_rec coloring colorability todo stack_count =
        let rec priority r (priority,solution,c) =
            (*
            Priority 4 : one color available only and an preference edge towards that color
            Priority 3 : one color available only
            Priority 2 : one edge towards a register for which the color is known
            Priority 1 : whichever register has an available color
            *)
            (* Priorities 4 and 2 are missing *)
            if (priority = 4) then (priority,solution,c) else
            if (priority < 3 && Register.S.cardinal (Register.M.find r colorability) = 1) then
                let single_color = Register.S.choose (Register.M.find r colorability) in
                if (Register.S.fold
                begin
                    fun r_pref current ->
                    if not (Register.is_hw r_pref) then
                     current || (Register.S.mem single_color (Register.M.find r_pref colorability))
                     else current
                end
                (Register.M.find r ig).prefs false) then (4, r, Ltltree.Reg single_color)
                else (3, r, Ltltree.Reg single_color)
            else
                let has_pref_with_color, new_c = Register.S.fold
                    begin
                        fun r_pref (current,color_loc) ->
                        if current then (current,color_loc) else
                        begin
                            let new_color = try Register.M.find r_pref coloring with Not_found -> color_loc in
                            match new_color with
                            | Ltltree.Reg reg_loc -> if (Register.S.mem reg_loc (Register.M.find r colorability)) then (true, new_color) else (false, new_color)
                            | Ltltree.Spilled i -> (false, color_loc)
                        end
                    end (Register.M.find r ig).prefs (false,Ltltree.Reg Register.tmp1) in
                if (priority < 2 && has_pref_with_color) then (2, r, new_c) else
                if (priority < 1) then begin try (1, r, Ltltree.Reg (Register.S.choose (Register.M.find r colorability))) with Not_found -> (priority,solution,c) end
                else (priority,solution,c)
            in
        if (Register.S.is_empty todo) then (coloring,stack_count)
        else
        	let p,s,c = Register.S.fold priority todo (0, Register.tmp1, Ltltree.Reg Register.tmp1) in
        	if (p = 0) then (* No register found to color *)
        	    let r = Register.S.choose todo in
        	    color_rec (Register.M.add r (Ltltree.Spilled stack_count) coloring) colorability (Register.S.remove r todo) (stack_count + 1)
        	else (* Register found *)
        	    match c with
        	    | Ltltree.Reg register ->
        	        (*printf "%s -> %s,%d\n" (s :> string) (register :> string) p;*)
        	        let colorability = Register.S.fold
                    begin fun r _colorability ->
                        if not (Register.is_hw r) then
                            Register.M.add r (Register.S.remove register (Register.M.find r _colorability)) _colorability
                        else _colorability
                    end (Register.M.find s ig).intfs colorability in (* Update colorability by removing color from all neighbours of s *)
                    color_rec (Register.M.add s c coloring) colorability (Register.S.remove s todo) stack_count
                | _ -> assert false (* The priority function doesn't return a spilled value *)
        in
    let colorability = Register.M.fold (fun r arc cs -> Register.M.add r (Register.S.diff Register.allocatable arc.intfs) cs) ig Register.M.empty in
    let todo = Register.M.fold (fun r arc s -> if not (Register.is_hw r) then Register.S.add r s else s) ig Register.S.empty in (* Registers to color *)
    let coloring = Register.S.fold (fun r co -> if (Register.is_hw r) then Register.M.add r (Ltltree.Reg r) co else co) todo (Register.M.empty) in
    color_rec coloring colorability todo 0

let print_graph ig =
  Register.M.iter (
  fun r arcs ->
    Format.printf "%s: prefs=@[%a@] intfs=@[%a@]@." (r :> string) Register.print_set arcs.prefs Register.print_set arcs.intfs
  ) ig

let print_color fmt = function
  | Ltltree.Reg hr    -> fprintf fmt "%a" Register.print hr
  | Ltltree.Spilled n -> fprintf fmt "stack %d" n

let print fmt f =
    List.iter (fun x -> print_graph_li fmt x.fun_body x.fun_entry) f.funs;
    List.iter (fun x -> Register.M.iter
                            (fun r cr -> printf "%a -> %a@\n" Register.print r print_color cr) x.fun_coloring) f.funs

let program_fun (df:Ertltree.deffun) =
    lg := Label.M.empty;
    graph := Register.M.empty;
    liveness lg df;
    make !lg;
    let coloring, stack_count = color !graph in
    {
        fun_name = df.fun_name;
        fun_entry = df.fun_entry;
        fun_body = df.fun_body;
        fun_stack_count = stack_count;
        fun_coloring = coloring;
    }

let program (f:Ertltree.file) =
    {
        funs = List.map program_fun f.funs
    }
