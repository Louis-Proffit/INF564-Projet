
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
Adds preferences edges for that instruction
*)
let label_preference (li:Ertltree.live_info) =
    begin match li.instr with
    | Ertltree.Embinop(Mmov,r1,r2,_) -> if r1<>r2 then add_pref r1 r2
    | _ -> ()
    end

(**
Adds interferecnce edges for that instruction
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
    let rec color_rec coloring colorability todo =
        let rec priority r (priority,solution) =
            begin
                (*
                Priority 4 : one color available only and an preference edge towards that color
                Priority 3 : one color available only
                Priority 2 : one edge towards a register for which the color is known
                Priority 1 : whichever register has an available color
                *)
                (* Priorities 4 and 2 are missing *)
                if priority < 3 && (Register.S.cardinal (Register.M.find r colorability)) == 1 then (3,r)
                else if priority < 1 then (1,r)
                else (priority,solution)
            end in
        if (Register.S.is_empty todo) then
        coloring
        else
        	let p,s = Register.S.fold priority todo (0,Register.tmp1) in
        	if (s = Register.tmp1) then (* No register found to color*)
        	    let r = Register.S.choose todo in
        	    color_rec (Register.M.add r (Spilled 0) coloring) colorability (Register.S.remove r todo)
        	else (* Register found *)
        	    let color = Register.S.choose (Register.M.find s colorability) in (* Find an appropriate color *)
        	    let colorability = Register.S.fold
        	    begin fun r cs ->
        	        Register.M.add r (Register.S.remove color (Register.M.find r cs)) cs
        	    end (Register.M.find s ig).intfs colorability in (* Update colorability by removing color from all neighbours of s *)
        	    color_rec (Register.M.add s (Reg color) coloring) colorability (Register.S.remove s todo)
        in
    let todo = Register.M.fold (fun r arc s -> Register.S.add r s) ig Register.S.empty in (* Registers to color *)
    let colorability = Register.M.map (fun arc  -> Register.S.diff Register.allocatable arc.intfs) ig in
    color_rec (Register.M.empty) colorability todo

let print_graph ig =
  Register.M.iter (
  fun r arcs ->
    Format.printf "%s: prefs=@[%a@] intfs=@[%a@]@." (r :> string) Register.print_set arcs.prefs Register.print_set arcs.intfs
  ) ig

let print_color fmt = function
  | Reg hr    -> fprintf fmt "%a" Register.print hr
  | Spilled n -> fprintf fmt "stack %d" n

let print fmt cm =
    print_graph !graph;
    Register.M.iter
    (fun r cr -> printf "%a -> %a@\n" Register.print r print_color cr) cm

let program (f:Ertltree.liveness_file) =
    List.iter (fun (f:Ertltree.liveness_fun) -> make f.live_info) f.funs_info;
    color !graph
