
open Format
open Ltltree

type arcs = { mutable prefs: Register.set; mutable intfs: Register.set }
type igraph = arcs Register.map

type color = Ltltree.operand
type coloring = color Register.map

let graph = ref Register.M.empty

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
let add_intf r1 r2 =
    let arc1 = try Register.M.find r1 !graph with Not_found -> (let arc1 = {prefs=Register.S.empty;intfs=Register.S.empty} in graph := Register.M.add r1 arc1 !graph;arc1) in
    arc1.intfs<-Register.S.add r2 arc1.intfs;
    let arc2 = try Register.M.find r2 !graph with Not_found -> (let arc2 = {prefs=Register.S.empty;intfs=Register.S.empty} in graph := Register.M.add r2 arc2 !graph;arc2) in
    arc2.intfs<-Register.S.add r1 arc2.intfs

(**
Adds preference edges for that instruction
*)
let label_preference (li:Ertltree.live_info) =
    begin match li.instr with
    | Ertltree.Embinop(Mmov,r1,r2,_) -> if r1<>r2 then add_pref r1 r2
    | _ -> ()
    end

(**
Adds interference edges for that instruction
*)
let label_interference (li:Ertltree.live_info) =
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
let make (lg:Ertltree.lg) =
    graph := Register.M.empty;
    Label.M.iter (fun l li -> label_preference li) lg;
    Label.M.iter (fun l li -> label_interference li) lg

(**
Colors the graph
*)
let color ig =
    let stack_index = ref 0 in
    let rec color_rec coloring colorability todo =
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
                (Register.M.find r ig).prefs false) then (4, r, Reg single_color)
                else (3, r, Reg single_color)
            else
                let has_pref_with_color, new_c = Register.S.fold
                    begin
                        fun r_pref (current,color_loc) ->
                        if current then (current,color_loc) else begin try (true, Register.M.find r_pref coloring) with Not_found -> (false, color_loc) end
                    end (Register.M.find r ig).prefs (false,Reg Register.tmp1) in
                if (priority < 2 && has_pref_with_color) then (2, r, new_c) else
                if (priority < 1) then begin try (1, r, Reg (Register.S.choose (Register.M.find r colorability))) with Not_found -> (priority,solution,c) end
                else (priority,solution,c)
            in
        if (Register.S.is_empty todo) then coloring
        else
        	let p,s,c = Register.S.fold priority todo (0, Register.tmp1, Reg Register.tmp1) in
        	if (p = 0) then (* No register found to color *)
        	    let r = Register.S.choose todo in
        	    stack_index := !stack_index + 1;
        	    color_rec (Register.M.add r (Spilled !stack_index) coloring) colorability (Register.S.remove r todo)
        	else (* Register found *)
        	    match c with
        	    | Reg register ->
        	        let colorability = Register.S.fold
                    begin fun r _colorability ->
                        if not (Register.is_hw r) then
                            Register.M.add r (Register.S.remove register (Register.M.find r _colorability)) _colorability
                        else _colorability
                    end (Register.M.find s ig).intfs colorability in (* Update colorability by removing color from all neighbours of s *)
                    color_rec (Register.M.add s c coloring) colorability (Register.S.remove s todo)
                | _ -> assert false (* The priority function doesn't return a spilled value *)
        in
    let todo = Register.M.fold (fun r arc s -> Register.S.add r s) ig Register.S.empty in (* Registers to color *)
    let colorability = Register.M.fold (fun r arc cs -> Register.M.add r (Register.S.diff Register.allocatable arc.intfs) cs) ig Register.M.empty in
    let coloring = Register.S.fold (fun r co -> if (Register.S.mem r Register.allocatable) then Register.M.add r (Reg r) co else co) todo (Register.M.empty) in
    color_rec coloring colorability todo

let print_graph ig =
  Register.M.iter (
  fun r arcs ->
    Format.printf "%s: prefs=@[%a@] intfs=@[%a@]@." (r :> string) Register.print_set arcs.prefs Register.print_set arcs.intfs
  ) ig

let print_color fmt = function
  | Reg hr    -> fprintf fmt "%a" Register.print hr
  | Spilled n -> fprintf fmt "stack %d" n

let print fmt cm =
    Register.M.iter
    (fun r cr -> printf "%a -> %a@\n" Register.print r print_color cr) cm

let program (f:Ertltree.liveness_file) =
    List.iter (fun (f:Ertltree.liveness_fun) -> make f.live_info) f.funs_info;
    color !graph
