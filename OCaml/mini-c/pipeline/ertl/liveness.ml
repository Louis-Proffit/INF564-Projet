
open Format
open Ertltree

let add lg l li = lg := Label.M.add l li !lg

let liveness_succ_def_use lg (l:Label.M.key) (i:instr) =
    let defs, uses = def_use i in
    let succ = succ i in
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

let liveness lg (f:deffun) =
    Label.M.iter (liveness_succ_def_use lg) f.fun_body;
    Label.M.iter (liveness_pred lg) !lg;
    let ws = ref Label.S.empty in
    Label.M.iter (fun l li -> ws := Label.S.add l !ws;()) !lg;
    killdal lg ws

let liveness (f:file) =
    {
        funs_info = List.map (fun x -> let lg = ref Label.M.empty in liveness lg x;{fun_def=x;live_info=(!lg);}) f.funs;
    }