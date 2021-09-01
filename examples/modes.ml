module ModalMap = Map.Make(Int)

(* idea what if we base our graph not on 12 notes, but on some complex network of mupwalks *)

type pitchClass =
  | PitchClass of int

let makePitchClass x =
  PitchClass (x mod 12)

type musicMode =
   { modmap : int list ModalMap.t
   ; previous : int
   }

type performingMode =
  { modmapKnows : (int * bool) list ModalMap.t
  ; previous : int
  }

let findStart modMap =
  ModalMap.min_binding_opt modMap

let makePlayable modMap =
  let f lst =
    List.map (fun x -> (false, x))
  in
  ModalMap.map f modMap

let rec findUnplayed lst =
  match lst with
  | [] -> None
  | (false,x)::_ -> Some x
  | (true,_)::xs -> findUnplayed xs

(* IDEA: could take a whenStuckF
   if no value found use whenStuck, takes a modalmap and produces a value*)
let run { modmapKnows ; previous } =
  let rec aux prev () =
    let next = ModalMap.find_opt prev modmapKnows |> Option.bind findUnplayed in
    match next with
    | Some option ->
       Seq.Cons ( next, aux option)
    | None -> Seq.Cons ( next, aux prev )
  in
  aux previous
     
  


let insertSorted f lst a =
  (* note, insertSorted (<) [1;2;3;4;5] 3 -returns- [1;2;3;3;4;5] *)
  let rec aux lst a =
    match lst with
    | [] -> [a]
    | h :: tl -> if f a h then a :: h :: tl else h :: aux tl a
  in
  aux lst a

let rec insertIfNew lst a =
    match lst with
    | [] -> [a]
    | h :: tl ->
       let comp = (a = h,a > h) in
       match comp with
       | (true,_) -> lst
       | (_,true) -> a :: h :: tl
       | (_,false) -> h :: insertIfNew tl a
      

let printResult res =
  Seq.iter print_int res;
  print_newline ()

let init note =
  { modmap = ModalMap.empty
  ; previous = note }

let update note ({ modmap ; previous }) =
  let updateFun opt =
    Option.map
      (fun lst ->
        if List.mem note lst then
          lst
       else
          (insertIfNew lst note))
      opt
  in
  let newMap = ModalMap.update previous updateFun modmap in
  { modmap = newMap
  ; previous = note
  }

let runEval sq =
  let evaluate { modmap ; _ } = modmap in
  Cisp.recursive sq init update evaluate

let test = [0;7;5;0;7;5] 


                 (* Seq.map (Option.map f) *)






  
  

(*
  a b c d
a x
b   x x 
c
d       x
 
maybe interesting to have something
 *)

