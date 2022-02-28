
open Ltltree

let ltl_fun (f:Ertltree.liveness_fun) =
    let fun_def = f.fun_def in
    {
      fun_name = fun_def.fun_name;
      fun_entry = fun_def.fun_entry;
      fun_body = Label.M.empty;
    }

let program (f:Ertltree.liveness_file) =
    {
        funs = List.map ltl_fun f.funs_info;
    }