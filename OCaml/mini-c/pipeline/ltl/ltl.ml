
open Ltltree

let graph = ref Label.M.empty

let add l i =
    graph := Label.M.add l i !graph

let lookup c r =
  if Register.is_hw r then Reg r else Register.M.find r c

let instr c frame_size = function
  | Ertltree.Econst (n, r, l) -> Econst (n, lookup c r, l)


let ltl_fun (c:Graph.coloring) (f:Ertltree.liveness_fun) =
    graph := Label.M.empty;
    let fun_def = f.fun_def in
    {
      fun_name = fun_def.fun_name;
      fun_entry = fun_def.fun_entry;
      fun_body = !graph;
    }

let program (c:Graph.coloring) (f:Ertltree.liveness_file)  =
    {
        funs = List.map (ltl_fun c) f.funs_info;
    }