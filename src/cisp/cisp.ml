open Seq

(* Seq is a thunk that when forced returns a value and a thunk to get the tail *)

(* 
this is the same as 
let thunk x = fun () -> x 
 *)

let samplerate = ref (!Process.sample_rate)

let id x = x
               
let thunk x () = x

let emptySt () = Nil

let force l = l ()

let ( |> ) x f = f x

let ( <| ) f x = f x

let ( >> ) f g x = g (f x)

let ( << ) f g x = f (g x)

let fst (x, _) = x

let snd (_, x) = x

let mapFst f (a,b) =
  (f a,b) 
                   

let flip f a b = f b a

let minimum a b =
  if a > b then b else a

let maximum a b =
  if a > b then a else b

let sec s = !Process.sample_rate *. s
let seci s = !Process.sample_rate *. s |> Int.of_float

let two_pi = Float.pi *. 2.0
 
let rec ofRef rf () = Cons (!rf, ofRef rf)

let rdRef rf () = Cons(!rf,ofRef rf)

let wrRef rf valueSq = map (fun x -> rf := x) valueSq
                     
           
let singleton a =
  [a]

let rec takeLst n lst =
  match n with
  | 0 -> []
  | n ->
     match lst with
     | h::tl -> h::takeLst (n-1) tl
     | [] -> []
  
let rec listRepeat n x =
  if n < 0 then
    []
  else 
  match n with
  | 0 -> []
  | n -> x::listRepeat (n-1) x
  

  
(* List a -> (List a -> b) -> List b *)

let rec zip a b () =
  match a () with
  | Nil -> Nil
  | Cons (a, atl) -> (
    match b () with Nil -> Nil | Cons (b, btl) -> Cons ((a, b), zip atl btl) )

let syncEffect sq effectSq =
  (* just update an effect stream in sync with sq, but don't use its return value *) 
  let both = zip sq effectSq in
  map (fun (signal, effect) -> effect; signal) both

let effectSync effectSq sq =
  (* just update an effect stream in sync with sq, but don't use its return value *) 
  let both = zip effectSq sq in
  map (fun (effect, signal) -> effect; signal) both
  
let effect = effectSync
  
let currentSampleCounter = ref 0

let updateCurrentSample () =
  currentSampleCounter := !currentSampleCounter + 1

let rec masterClock () =
  Cons ( updateCurrentSample () , masterClock )

let inTime lst =
  match lst with
   | h :: ts -> (syncEffect h masterClock) :: ts
   | [] -> []

let withEffect effect lst = 
  match lst with
  | h :: ts -> syncEffect h effect :: ts
  | [] -> []

let test sq =
  map print_float sq

(* applicative functor for seq.t 
   can be used to map functions with more than two arguments to take seqs as arguments
   for example:
   
    map (fun a b c = a * b * c) seq1 |> andMap seq2 |> andMap seq3 
 *)
let andMap seq seqOfFuns =
  let zipped = zip seq seqOfFuns in
  map (fun (x, f) -> f x) zipped
                 
let optionLiftA2 f a b =
  match (a,b) with
  | (Some a, Some b) -> Some (f a b)
  | (_,_) -> None

let optionAndMap a f =
  match (f,a) with
  | (Some f,Some a) -> Some (f a)
  | (_,_) -> None

let ofInt = Float.of_int

let ofFloat = Int.of_float

let rec length sq = match sq () with Nil -> 0 | Cons (_, tl) -> 1 + length tl

let fromBinary b =
  let rec aux b base =
    if b = 0 then 0 else (b mod 10 * base) + aux (b / 10) (base * 2)
  in
  aux b 1

let rec append a b () =
  match a () with Nil -> b () | Cons (h, ls) -> Cons (h, append ls b)

(*
let rec appendSeq a b =
  match a () with
  | Nil -> b
  | Cons (this_a, rest) -> fun () -> Cons (this_a, appendSeq rest b)

let rec appendAlt a b () =
  match a () with
  | Nil -> b ()
  | Cons (h, tl) -> fun () -> Cons(h, appendAlt tl b)
*)

let rec cycle a () =
  let rec cycle_append current_a () =
    match current_a () with
    | Nil -> cycle a ()
    | Cons (this_a, rest) -> Cons (this_a, cycle_append rest)
  in
  cycle_append a ()

let rec range
  a b () = if a >= b then Nil else Cons (a, range (a +. 1.0) b)

let rangei a b =
  let rec aux a b () =
    if a = b then
      Cons(a, fun () -> Nil)
    else
      Cons(a,aux (a+1) b)
  in
  if b < a then
    aux b a
  else
    aux a b
                     
(* not sure about these *)
let head ll = match ll () with Nil -> None | Cons (h, _) -> Some h

let tail ll = match ll () with Nil -> None | Cons (_, tl) -> Some (tl ())

(* this is not the same as ofList, but should be! 
let from_list list () =
  List.fold_right (fun x acc -> Cons (x, acc |> thunk)) list Nil
  *)

let ofList l =
  let rec aux l () = match l with [] -> Nil | x :: l' -> Cons (x, aux l') in
  aux l

let rec toList ls =
  match ls () with Nil -> [] | Cons (h, ts) -> h :: toList ts

let rec take n lst () =
  if n <= 0 then Nil
  else match lst () with Nil -> Nil | Cons (h, ts) -> Cons (h, take (n - 1) ts)



let for_example lst = lst |> take 40 |> toList

let rec drop n lst () =
  if n <= 0 then lst ()
  else match lst () with Nil -> Nil | Cons (_, tail) -> drop (n - 1) tail ()

let rec group chunkSize sq () =
  match chunkSize () with
  | Nil -> Nil
  | Cons(n,ntl) ->
     let chunk = take n sq in
     let sqTail = drop n sq in
     Cons(chunk, group ntl sqTail)

let rec nth n sq = if n = 0 then head sq else nth (n - 1) sq

let reverse lst =
  let rec aux acc arg () =
    match arg () with
    | Nil -> acc
    | Cons (h, ts) -> aux (Cons (h, thunk acc)) ts ()
  in
  aux Nil lst

let rec split n lst =
  if n <= 0 then (thunk Nil, lst)
  else
    match lst () with
    | Nil -> (thunk Nil, thunk Nil)
    | Cons (x, xs) ->
        let f, l = split (n - 1) xs in
        (thunk (Cons (x, f)), l)

let rec filter f lst () =
  match lst () with
  | Nil -> Nil
  | Cons (h, tl) ->
      if f h then Cons (h, fun () -> filter f tl ()) else filter f tl ()

let list_fold_left1 f lst =
  match lst with
  | x::xs -> Some (List.fold_left f x xs)
  | [] -> None
    
let rec foldr f z ll =
  match ll () with Nil -> z | Cons (h, tl) -> f h (foldr f z tl)

let rec fold_right f s acc =
  match s () with Nil -> acc | Cons (e, s') -> f e (fold_right f s' acc)

                                       

let rec concat str () =
  match str () with
  | Nil -> Nil
  | Cons (h, ls) -> (
    match h () with
    | Cons (h', ls') ->
        let newtail () = Cons (ls', ls) in
        Cons (h', concat newtail)
    | Nil -> concat ls () )

let concatMap f sq () = map f sq |> concat

let mozes f lst =
  let rec aux lsta lstb lst =
    match lst with
     | (h::ts) ->
        if f h then aux (h::lsta) lstb ts else aux lsta (h::lstb) ts 
     | [] ->
        (lsta,lstb)
  in
  aux [] [] lst

type 'a sorted = Sorted of 'a list

let sortedAsList (Sorted lst) = lst

let mkSorted f lst =
  Sorted (List.sort f lst)
  
let mozesSorted f sortedLst =
  let rec aux lsta (Sorted lst) =
    match lst with
      (h::tail) ->
       if f h then
         aux (h::lsta) (Sorted tail)
       else (Sorted (List.rev lsta),Sorted (h::tail))
    | [] -> (Sorted lsta,Sorted [])
  in aux [] sortedLst
  
                      
let hd lst =
  match lst () with
  | Nil -> raise (Invalid_argument "empty list has no head")
  | Cons (h, _) -> h

let tl lst =
  match lst () with
  | Nil -> raise (Invalid_argument "empty list has no tail")
  | Cons (_, tl) -> tl

let for_all f sq =
  let rec aux sq start =
    match sq () with
    | Nil -> true
    | Cons (h, tl) -> if f h then aux tl start else false
  in
  aux sq true

let is_empty sq = match sq () with Nil -> true | _ -> false

let has_more sq = is_empty sq |> not

let foldHeads x acc =
  match x () with Nil -> acc | Cons (h, _) -> Cons (h, fun () -> acc)

let headsOfStreams sq () = fold_right foldHeads sq Nil

let foldTails x acc =
  match x () with Nil -> acc | Cons (_, ts) -> Cons (ts, fun () -> acc)

let tailsOfStreams sq () = fold_right foldTails sq Nil

let rec transpose sq () =
  match sq () with
  | Nil -> Nil
  | Cons (sqs, sqss) -> (
    match sqs () with
    | Cons (x, xs) ->
        Cons
          ( (fun () -> Cons (x, headsOfStreams sqss))
          , transpose <| thunk (Cons (xs, tailsOfStreams sqss)) )
    | Nil -> transpose sqss () )

let transcat sq =
  sq |> transpose |> concat

let transList lst =
  lst |> ofList |> transcat

let rec transpose_list lst =
  let foldHeads acc x = match x with [] -> acc | h :: _ -> h :: acc in
  let foldTails acc x = match x with [] -> acc | _ :: ts -> ts :: acc in
  match lst with
  | [] -> []
  | [] :: xss -> transpose_list xss
  | (x :: xs) :: xss ->
      (x :: List.fold_left foldHeads [] xss)
      :: transpose_list (xs :: List.fold_left foldTails [] xss)

let rec st a () =
  (* static *)
  Cons (a, st a)

let normalizeNumberOfChannels channelsA channelsB = 
  let na,nb = List.length channelsA, List.length channelsB in
  if na = nb then (channelsA,channelsB) else
    let fillMissing n channels =
      let nCh = List.length channels in
      let diff = n - nCh in
      if diff <= 0 then
        takeLst n channels
      else
        channels @ listRepeat diff (st 0.0)  
    in
    let n = maximum (List.length channelsA) (List.length channelsB) in
    (fillMissing n channelsA, fillMissing n channelsB)
  
  


let rec countFrom n () = Cons (n, countFrom (n + 1))

let count = countFrom 0

let countTill n =
  let rec aux current n () = (* 0 10 *) 
    if current < n then
      Cons (current, aux (current + 1) n)
    else 
      Cons (0, aux 1 n)
  in
  aux 0 n
          


let rec zipList a b =
  match a with
  | [] -> []
  | x :: xs -> ( match b with [] -> [] | y :: ys -> (x, y) :: zipList xs ys )

let unzip sq =
  (map fst sq , map snd sq)
 
  
let unzip3 sq =
  let first (x,_,_) = x in
  let second (_,x,_) = x in
  let third (_,_,x) = x in
  (map first sq, map second sq, map third sq) 
  

let rec zip3 a b c () =
  match (a (), b (), c ()) with
  | Cons (ha, lsa), Cons (hb, lsb), Cons (hc, lsc) ->
      Cons ((ha, hb, hc), zip3 lsa lsb lsc)
  | _ -> Nil

let rec zip4 a b c d () =
  match (a (), b (), c (),d ()) with
  | Cons (ha, lsa), Cons (hb, lsb), Cons (hc, lsc), Cons(hd, lsd) ->
     Cons((ha,hb,hc,hd), zip4 lsa lsb lsc lsd)
  | _ -> Nil

let rec zipWith f a b () =
  match a () with
  | Nil -> Nil
  | Cons (a, atl) -> (
    match b () with
    | Nil -> Nil
    | Cons (b, btl) -> Cons (f a b, zipWith f atl btl) )

let rec zipWith4 f a b c d () =
  match a () with
  | Nil -> Nil
  | Cons(a, atl) -> (
    match b () with
    | Nil -> Nil
    | Cons (b, btl) -> (
      match c () with
      | Nil -> Nil
      | Cons (c, ctl) -> (
        match d () with
        | Nil -> Nil
        | Cons (d, dtl) -> 
          Cons (f a b c d, zipWith4 f atl btl ctl dtl))))


(* static versions, so you do not have to use st *)

let ( *.- ) x sq = map ( ( *. ) x ) sq

let (+.-) x sq = map ((+.) x) sq

let (-.-) x sq = map ((-.) x) sq

let (/.-) x sq = map ((/.) x) sq

(* dual seq operators *)
                   
let ( +.~ ) = zipWith (fun a b -> a +. b)

let ( *.~ ) = zipWith (fun a b -> a *. b)

let ( /.~ ) = zipWith (fun a b -> a /. b)

let ( -.~ ) = zipWith (fun a b -> a -. b)

let ( +~ ) = zipWith (fun a b -> a + b)

let ( *~ ) = zipWith (fun a b -> a * b)

let ( /~ ) = zipWith (fun a b -> a / b)

let ( -~ ) = zipWith (fun a b -> a - b)

let addChannelLsts channelAList channelBList =
  let (aChs,bChs) = normalizeNumberOfChannels channelAList channelBList in
  List.map2 (+.~) aChs bChs


let linlin inA inB outA outB input =
  let a = minimum inA inB in
  let b = maximum inA inB in
  let c = minimum outA outB in
  let d = maximum inA inB in
  (((input -. a) /. (b -. a)) *. (d -. c)) +. c

let mapLinlin inA inB outA outB input =
  map linlin inA |> andMap inB |> andMap outA |> andMap outB |> andMap input

    

let rec mkLots n thing =
  let sum =
    if n > 1 then
      thing () +.~ (mkLots (n-1) thing) 
    else
      thing ()
  in
  let attenuate =
    0.71 /. (Float.of_int n)
  in
  sum |> map (( *. ) attenuate)


let mixList lst () = List.fold_left ( +~ ) lst

(* zipped list will be lenght of shortest list *)

let clip low high x = if x < low then low else if x > high then high else x

                    

let wrapf low high x =
  let range = low -. high |> abs_float in
  let modded = mod_float (x -. low) range in
  if modded < 0.0 then high +. x else low +. x

let wrap low high x =
  let range = low - high |> abs in
  let modded = (x - low) mod range in
  if modded < 0 then high + x else low + x

let rec recursive control init update evaluate () =
  match control () with
  | Nil -> Nil
  | Cons (x,xs) ->
     let nextState = update x init in
     Cons ( evaluate init, recursive xs nextState update evaluate )

(* recursive no control seq. Allows for non-trivial control update *)
let rec simpleRecursive init update evaluate () =
  let nextState = update init in
  Cons ( evaluate init, simpleRecursive nextState update evaluate )
  
let walki start steps =
  recursive
    steps
    start
    (fun x start -> x + start)
    id
    
 
  
let rec walk start steps () =
  match steps () with
  | Cons (h, ls) ->
      let next = start +. h in
      Cons (start, walk next ls)
  | Nil -> Nil

let rec iterwalk start f steps () =
  match steps () with
  | Cons (h, ls) ->
      let next = f start h in
      Cons (start, iterwalk next f ls)
  | Nil -> Nil

(* operator is a function 
   to get the next value *)
let rec boundedFuncWalk start steps operator wrapfunc () =
  match steps () with
  | Cons (h, ls) ->
      let next = operator start h in
      Cons (wrapfunc start, boundedFuncWalk next ls operator wrapfunc)
  | Nil -> Nil

let boundedWalk start steps wrapfunc =
  let rec aux start steps () =
    match steps () with
    | Nil -> Nil
    | Cons (h, ls) ->
        let next = wrapfunc (start + h) in
        Cons (start, aux next ls)
  in
  aux start steps

let boundedWalkf start steps wrapfunc =
  let rec aux start steps () =
    match steps () with
    | Nil -> Nil
    | Cons (h, ls) ->
        let next = start +. h in
        Cons (wrapfunc start, aux next ls)
  in
  aux start steps

let cap arr =
  Array.length arr


  
let safeIdx len idx =
  let result = idx mod len in
  if result >= 0 then result
  else
    result + len

(* guarentee that we are using a power of two *)
type powerOfTwo = PowerOfTwo of int

let isPowerOfTwo = function
  | 0 -> false
  | x -> (x land (x - 1) = 0)
    
let rec pow a = function
  | 0 -> 1
  | 1 -> a
  | n -> 
    let b = pow a (n / 2) in
    b * b * (if n mod 2 = 0 then 1 else a)
                              
let mkPowerOfTwo n =
  PowerOfTwo (pow 2 n)
                    
let fastSafeIdx (PowerOfTwo len) idx =
  idx land (len - 1)
                    
let indexArr len arr idx =
  arr.(safeIdx len idx)

let fastIndexArr len arr idx =
  arr.(fastSafeIdx len idx) 

let getSafeIndexFun arr =
  let size = Array.length arr in
  if isPowerOfTwo size then
    fastIndexArr (PowerOfTwo size) arr
  else
    indexArr size arr

let getSafeWriteFun arr =
  let writeArr len arr idx value =
    arr.(safeIdx len idx) <- value
  in
  let writeArrFast len arr idx value =
    arr.(fastSafeIdx len idx) <- value
  in
  let size = Array.length arr in
  if isPowerOfTwo size then
    writeArrFast (PowerOfTwo size) arr
  else 
    writeArr size arr
    
let index arr indexer =
  let arrIndexFun =
    getSafeIndexFun arr
  in
  map (fun idx -> arrIndexFun idx) indexer

let listWalk arr step () =
  let wrapFunc = wrap 0 (Array.length arr) in
  index arr (boundedWalk 0 step wrapFunc)

type 'a weightList = Weights of (int * 'a) list

let mkWeights lst = match lst with [] -> None | w -> Some (Weights w)

let weights weightLst () =
  let sumWeights = List.fold_left (fun acc (_, w) -> w + acc) 0 weightLst in
  let rec lookupWeight lst curr pick =
    match lst with 
    | [] -> raise <| Invalid_argument "weight not found"
    | [(value, _)] -> value
    | (value, weight) :: ws ->
        let nextCurr = weight + curr in
        if pick < nextCurr then value else lookupWeight ws nextCurr pick
  in
  let rec aux weights max () =
    Cons (lookupWeight weights 0 (Random.int max), aux weights max)
  in
  aux weightLst sumWeights ()

let rec sometimes x y p () =
  let head () =
    let rnd = Random.int p in
    if rnd < 1 then y else x
  in
  Cons (head (), sometimes x y p)

let linInterp xa xb px = ((xb -. xa) *. px) +. xa
(*
https://www.musicdsp.org/en/latest/Other/93-hermite-interpollation.html
James Mcarty
inline float hermite2(float x, float y0, float y1, float y2, float y3)
{
    // 4-point, 3rd-order Hermite (x-form)
    float c0 = y1;
    float c1 = 0.5f * (y2 - y0);
    float c3 = 1.5f * (y1 - y2) + 0.5f * (y3 - y0);
    float c2 = y0 - y1 + c1 - c3;

    return ((c3 * x + c2) * x + c1) * x + c0;
}*)

let getBiggerPowerOfTwo x =
  let rec aux x count =
    if x = 0 then
      count
    else aux (x asr 1) (count + 1)
  in
  aux x 0 |> pow 2 

let mkBuffer minimumSizeInSeconds =
  let size = (!samplerate |> Int.of_float) * minimumSizeInSeconds in
  let optimumSize = getBiggerPowerOfTwo size in
  Array.make optimumSize 0.0
  
                       
let hermit x y0 y1 y2 y3 =
  let c0 = y1 in
  let c1 = 0.5 *. (y2 -. y0) in
  let c3 = 1.5 *. (y1 -. y2) +. 0.5 *. (y3 -. y0) in
  let c2 = y0 -. y1 +. c1 -. c3 in
  ((c3 *. x +. c2) *. x +. c1) *. x +. c0
  
let indexLin arr indexer =
  let len = Array.length arr in
  let arrIndexFun =
    getSafeIndexFun arr
  in
  let f idx =
      begin
      let xa = idx |> Float.floor |> Int.of_float in
      let xb = (xa + 1) mod len in
      let xp = idx -. Float.of_int xa in
      linInterp (arrIndexFun xa) (arrIndexFun xb) xp
      end
  in
  map f indexer
 
      
      

let indexCub arr indexer =
  let len = Array.length arr in
  let ifun =
    getSafeIndexFun arr
  in
  (* a____b__x__c___d *)
  let f idx =
    let b = idx |> Int.of_float in
    let a = match b - 1 with
      | -1 -> len
      | other -> other
    in
    let c = b + 1 in
    let d = b + 2 in
    let (y0,y1,y2,y3) = (ifun a,ifun b, ifun c, ifun d) in
    hermit (idx -. (Float.of_int b)) y0 y1 y2 y3
  in
  map f indexer
    
                      
    
      
 

let sineseg wavesamps =
  let incr = 1.0 /. Float.of_int wavesamps in
  let f x = 2.0 *. Float.pi *. x |> sin in
  let rec aux x () = if x >= 1.0 then Nil else Cons (f x, aux (x +. incr)) in
  aux 0.0

let arr_of_seq str = Array.of_seq str

(* TODO
let rec iterates start fs =
  match fs () with Nil -> Nil | Cons (h, ls) -> start () fs *)

let rec repeat n x () = if n > 0 then Cons (x, repeat (n - 1) x) else Nil

let hold repeats source =
  let ctrl = zip repeats source in
  map (fun (n, src) -> repeat n src) ctrl |> concat

let embed str () = Cons (str, thunk Nil) (* create a singleton stream *)

(* returnes the loops and the tail of the source
   preferably source is infinite *)
let oneLoop size n str () =
  let snippet, tail = split size str in
  (snippet |> repeat n |> concat, tail)

let loop size n src =
  let control = zip size n in
  let rec loops ctrl src () =
    match ctrl () with
    | Nil -> Nil
    | Cons ((size, num), nextCtrl) ->
        let currLoop, rest = oneLoop size num src () in
        Cons (currLoop, loops nextCtrl rest)
  in
  loops control src |> concat

let trunc = map Int.of_float

let floatify = map Float.of_int

let rvfi low high =
  let range = abs_float (low -. high) in
  let offset = min low high in
  Random.float range +. offset

let rvi low high =
  let range = abs (low - high) in
  let offset = min low high in
  Random.int range + offset

let rv low high =
  let control = zip low high in
  map (fun (l, h) -> rvi l h) control

let rvf low high =
  let control = zip low high in
  map (fun (l, h) -> rvfi l h) control

let pickOne arr =
  let picker = rvi 0 (Array.length arr) in
  arr.(picker)
  
(* choice *)
let ch arr =
  let picker = rv (st 0) (st (Array.length arr)) in
  index arr picker

let mtof midi = 440.0 *. (2.0 ** ((midi -. 69.0) /. 12.0))

let ftom freq = (12.0 *. log (freq /. 440.0)) +. 69.0

(* input -> state -> (state, value) *)

let rec collatz n () =
  if n = 1 then Nil (* lets end it here, normally loops 1 4 2 1 4 2.. *)
  else
    let even x = x mod 2 = 0 in
    let next = if even n then n / 2 else (n * 3) + 1 in
    Cons (next, collatz next)

(* use floats as arguments to somethign that expects streams *)
let lift f a b = f (st a) (st b)

let pair a b = (a, b)

let lineSegment curr target n () =
  let rate = (target -. curr) /. n in
  let reachedEnd =
    if rate > 0.0 then fun x -> x >= target else fun x -> x <= target
  in
  let rec segment curr () =
    if reachedEnd curr then Nil else Cons (curr, segment (curr +. rate))
  in
  segment curr

   
let rec selfChain sq () =
  match sq () with
  | Nil -> Nil
  | Cons (h, tail) ->
     match tail () with
     | Nil -> Nil 
     | Cons(h2, _) ->
        Cons((h,h2),  selfChain tail)

let seq lst = lst |> ofList |> cycle

let lin ns targets =
  let targs = selfChain targets in
  let control = zip targs ns in
  map (fun ((a, b), n) -> lineSegment a b n ()) control |> concat

let line targets ns =
  let targs = selfChain targets in
  let control = zip targs ns in
  map (fun ((a, b), n) -> lineSegment a b n ()) control |> concat

(* audio only, linear interpolation *)
let mkDel max del src () =
  let delay = Bigarray.Array1.create Bigarray.float64 Bigarray.c_layout max in
  let index = map (fun x -> x mod max) count in
  let parameters = zip index src in
  let wr = map (fun (idx, src) -> delay.{idx} <- src) parameters in
  let readParameters = zip3 index del wr in
  map
    (fun (idx, del, wr) ->
      let maxf = ofInt max in
      let idxf = ofInt idx in
      let later = mod_float (maxf +. idxf -. del) maxf in
      let x0_idx = Int.of_float later in
      let x0 = delay.{x0_idx} in
      let x1 = delay.{(x0_idx + 1) mod max} in
      let xp = later -. Float.of_int x0_idx in
      let value = linInterp x0 x1 xp in
      wr ; value)
    readParameters

let genSine size =
  let twopi = 2.0 *. Float.pi in
  let gen i = ofInt i /. ofInt size *. twopi |> sin in
  Array.init size gen

let waveOsc arr frq =
  let arraySize = Array.length arr |> Float.of_int in
  let incr = frq /. !samplerate *. arraySize in
  let phasor = walk 0.0 (st incr) in
  index arr (trunc <| phasor)

let waveOscL arr frq =
  let arraySize = Array.length arr |> Float.of_int in
  let incr = frq /. !samplerate *. arraySize in
  let phasor = walk 0.0 (st incr) in
  indexLin arr phasor


(* combine two Seq's: a, b, a, b, a, b etc.. *)
let rec interleave xs ys () =
  match (xs (), ys ()) with
  | Nil, Nil -> Nil
  | xs', Nil -> xs'
  | Nil, ys' -> ys'
  | Cons (x, xtl), Cons (y, ytl) ->
      Cons (x, fun () -> Cons (y, interleave xtl ytl))

(*
Similar to interleave, but now you can provide in which pattern the seqs needs to be combined.
For example if the pattern is true;false;fase;true;false 
mkand a = 1,2,3,4
and b = 11,12,13,14
then you will get
1, 11, 12, 2, 13, 14
This is different from zipWith3, since there are no values thrown away
 *)
let rec weavePattern pattern xs ys () =
  match (xs (), ys ()) with
  | Nil, Nil -> Nil
  | xs, Nil -> xs
  | Nil, ys -> ys
  | Cons (x, xtl), Cons (y, ytl) -> (
    match pattern () with
    | Cons (true, ptl) -> Cons (x, weavePattern ptl xtl ys)
    | Cons (false, ptl) -> Cons (y, weavePattern ptl xs ytl)
    | Nil -> Nil )

let weave = weavePattern

let weaveArray arr indexer =
  let fIdx = getSafeIndexFun arr in
  let fWr = getSafeWriteFun arr in
    map (fun idx ->
      let sq = fIdx idx in
      match sq () with
      | Cons (h,tail) -> fWr idx tail; h 
      | Nil -> 0.0
    ) indexer
   
    
  

let mkPattern sqA sqB nA nB =
  seq [sqA;sqB] |> hold (interleave nA nB)

let interval reps =
  reps |> map (fun n () -> Cons (true, repeat n false)) |> concat

let pulse n sq filler =
  let p = interval n in
  weavePattern p sq filler

let pulsegen freqSq =
  let n = map ((/.) !Process.sample_rate) freqSq in
  n |> trunc |> map (fun n () -> Cons (1.0, repeat (clip 0 441000 (n-1)) 0.0)) |> concat
  

(* f(a -> b) -> fa -> fb *)
(* (a -> b) -> fa -> fb *)
let applicative sqF sq =
  map sqF sq |> concat

let getPreciseTime () =
  (!currentSampleCounter |> Float.of_int) /. 44100.0
(*Mtime_clock.elapsed () |> Mtime.Span.to_uint64_ns |> Int64.to_float |> ( *. ) Mtime.ns_to_s*)
    


  
type tLineState =
  { oldT : float
  ; oldX : float
  ; targetT : float
  ; targetX : float
  ; control : (float * float) Seq.t 
  }
  
let tline timeToNext sq =
  let valueNow oldT oldX targetT targetX () =
    let now = getPreciseTime () in
      let segmentDur = targetT -. oldT in
      let diffT = now -. oldT in
      ( oldX +. (( diffT /. segmentDur ) *. (targetX -. oldX)))
  in
  let ctrl = zip timeToNext sq in
  let updateControl c =
    match c () with
        | Nil -> ((0.0,10.0),fun () -> Nil)
        | Cons ((tt,tx),tl) -> ((tt,tx), tl)
  in
    
  let initial =
    let now = getPreciseTime () in
    let ((targetX,targetT), ctrlTail) =
      updateControl ctrl
    in           
    { oldT = now
    ; oldX = 0.0
    ; targetT = targetT
    ; targetX = targetX
    ; control = ctrlTail
    }
  in
  let update state =
    let now = getPreciseTime () in
    if state.targetT > now then
      state (* no changes *)
    else
      let ((tarT,tarX),tail) =
        updateControl state.control
      in
      { oldT = state.targetT
      ; oldX = state.targetX
      ; targetT = tarT +. now
      ; targetX = tarX
      ; control = tail
      }
  in
  let evaluate state =
    (*state.targetX*)
    valueNow state.oldT state.oldX state.targetT state.targetX ()
  in                
  simpleRecursive initial update evaluate
  

  

  
      
    
  



let timed intervalSeconds sq =
  let rec aux valueTime startValue later () =
    let now = getPreciseTime () in
    if
      later < now
    then
      match valueTime () with
          | Nil -> Nil
          | Cons((v,t),xs) ->
             let newLater = abs_float t +. now in (* abs -> make sure we don't go back in time! *)
             Cons(v,aux xs v newLater)
    else
      Cons( startValue, aux valueTime startValue later )
      
  in
  let startTime = getPreciseTime () in
  let control = zip sq intervalSeconds in
  match control () with
  | Nil -> fun () -> Nil
  | Cons((firstV,firstT), rest) ->
     aux rest firstV (abs_float firstT +. startTime) 
     
let tmd = timed

let phase_inc = 1.0 /. !Process.sample_rate
     
let oscPhase freq startPhase =
  recursive
    freq
    startPhase
    (fun freq phase -> phase +. (freq *. phase_inc) |> (fun x -> mod_float x 1.0))
    (fun x -> sin(x *. two_pi))
     
let osc freq =
  oscPhase freq 0.0 
  (*let f = makeFastOsc () in
  f freq 0.0*)

let fm_osc freq ratio index =
  let modFreq = freq *.~ ratio in
  let modAmp = modFreq *.~ index in
  let modSig = osc modFreq *.~ modAmp in
  osc (freq +.~ modSig)

let rec funWalk start f () =
  Cons( start, funWalk (f start) f )


  
let mupWalk start ratioSq =
  recursive
    ratioSq
    start
    ( ( *. ) ) 
    id

let bouncyWalk start lower higher stepSq =
  recursive
    stepSq
    start
    (fun previous control ->
      if (previous > higher) then
        previous -. abs_float control
      else
        (if (previous < lower) then
              previous +. abs_float control
     else
       (previous +. control)))
    id

let rec until condition sq () =
  match sq () with
  | Nil -> Nil
  | Cons(x,xs) -> if condition x then
                    Cons(x, until condition xs)
                  else
                    Nil
  
let resetWalk walk stepSq resetN source =
  let control = zip resetN source in
  let rec controlWithSteps ctrl stepSeq () =
    match ctrl () with
    | Nil -> Nil
    | Cons((n,src), ctrlTail) ->
       let stepTail = drop n stepSeq in
       Cons ((src,take n stepSeq), controlWithSteps ctrlTail stepTail )
  in
  let allWalks = 
    map
      (fun (start, stepper) -> walk start stepper )
      (controlWithSteps control stepSq)
  in concat allWalks
       
      
let rec fromRef reference () =
  Cons (!reference, fromRef reference)

(* let boundedMupWalk start ratioSq *)
  
let grow start ratio n =
  mupWalk start (st ratio) |> take n |> toList

let write arr index value =
  let control = zip index value in
  map (fun (idx, value) -> arr.(idx) <- value) control

let fractRandTimer timerSeq =
  tmd timerSeq
    (tmd timerSeq
       (tmd timerSeq timerSeq))

let rec fractRandTimerN n timerSeq =
  if n < 1 then
    tmd timerSeq timerSeq
  else
    tmd timerSeq (fractRandTimerN (n - 1) timerSeq)

let slowNoise speed = 
  let arr = rvf (st 0.0) (st 1.0) |> take (1024 * 512) |> Array.of_seq in
  let index = walk 0.0 speed in
  indexCub arr index
 
(* https://www.w3.org/2011/audio/audio-eq-cookbook.html *)
let biquad_static a0 a1 a2 b0 b1 b2 x =
  let b0a0 = b0 /. a0 in
  let b1a0 = b1 /. a0 in
  let b2a0 = b2 /. a0 in
  let a1a0 = a1 /. a0 in
  let a2a0 = a2 /. a0 in
  recursive
    x
    [|0.;0.;0.;0.;0.|]
    (fun i state ->
        let x1 = state.(0) in
        let x2 = state.(1) in
        let y1 = state.(2) in
        let y2 = state.(3) in
        let new_y =
          (i *. b0a0) +. (b1a0 *. x1) +. (b2a0 *. x2) -. (a1a0 *. y1)
          -. (a2a0 *. y2)
        in
        ([|i; x1; new_y; y1; new_y|]))
    (fun s -> s.(4))

let blpf_static f q x =
  let w = two_pi *. (f /. !samplerate) in
  let a = sin w /. (q *. 2.) in
  let cosw = cos w in
  let b1 = 1. -. cosw in
  let b0 = b1 /. 2. in
  let b2 = b0 in
  let a0 = 1. +. a in
  let a1 = -2. *. cosw in
  let a2 = 1. -. a in
  biquad_static a0 a1 a2 b0 b1 b2 x

let bhpf_static f q x =
  let w = two_pi *. (f /. !samplerate) in
  let a = sin w /. (q *. 2.) in
  let cosw = cos w in
  let b0 = (1. +. cosw) /. 2. in
  let b1 = (1. +. cosw) *. -1. in
  let b2 = b0 in
  let a0 = 1. +. a in
  let a1 = -2. *. cosw in
  let a2 = 1. -. a in
  biquad_static a0 a1 a2 b0 b1 b2 x

let bbpf_static f q x =
  let w = two_pi *. (f /. !samplerate) in
  let a = sin w /. (q *. 2.) in
  let cosw = cos w in
  let b0 = a in
  let b1 = 0. in
  let b2 = a *. -1. in
  let a0 = 1. +. a in
  let a1 = -2. *. cosw in
  let a2 = 1. -. a in
  biquad_static a0 a1 a2 b0 b1 b2 x


type dcFilterState =
    { previousX : float
    ; out : float
    }

(* TESTED, from supercollider, using 0.995 as factor 
   y[n] = x[n] - x[n-1] + coef * y[n-1] *)
  
  
let leakDC coef inputSq =
  recursive
    inputSq
    ({ out = 0.0
    ; previousX = 0.0
     })
    (fun xIn state ->
      let newOut =  (xIn -. state.previousX) +. (coef *. state.out)  in
      { previousX = xIn
      ; out = newOut })
    (fun state -> state.out)

      
type timedSection
  = TimedSection of { startSample : int
                    ; duration : int
                    ; seq : float Seq.t} 

let mkSection start duration seq =
  TimedSection { startSample = start ; duration = duration ; seq = seq }
    
                  
let addStreo (seq1L,seq1R) (seq2L,seq2R) =
  (seq1L +.~ seq2L,seq1R +.~ seq2R)
                  
let compareSection (TimedSection sectA) (TimedSection sectB) =
  compare (sectA.startSample) (sectB.startSample)
                  
type playingSection
  = PlayingSection of { endSample : int
                      ; seq : float Seq.t
                      }

let printPlayingSect (PlayingSection s) =
  let open Format in
  printf "end %i\n" s.endSample 
      
                    
type score =
  Score of timedSection sorted
                    
let toPlay now (TimedSection section) =
  PlayingSection { endSample = now + section.duration
                 ; seq = section.seq }
  
type sectionScheduler =
  SectionScheduler of { score : timedSection sorted
                      ; playingScore : timedSection sorted
                      ; now : int
                      ; currentSecs : playingSection list
                      ; currentOut : float
                      }

let schedWithOffset (SectionScheduler score) offsetInSmps =
  SectionScheduler { score with now = offsetInSmps }
  
                    
let schedulerOfScore (Score sortedTimedSecs) =
  SectionScheduler { playingScore = sortedTimedSecs
                   ; score = sortedTimedSecs
                   ; now = 0
                   ; currentSecs = []
                   ; currentOut = 0.0 }

let mkScore sectionLst =
  Score (mkSorted compareSection sectionLst)

let updateScheduler (SectionScheduler scheduler) =
  let dropFinished playingSects =
    List.filter (fun (PlayingSection playing) -> playing.endSample > scheduler.now)  playingSects
  in
  let (newCurrentSecs, future) = 
    scheduler.playingScore
    |> mozesSorted (fun (TimedSection e) ->
           e.startSample <= scheduler.now)
    |> mapFst (fun (Sorted playableEvts) -> List.map (toPlay scheduler.now) playableEvts)
  in
  let currentSects = newCurrentSecs @ (dropFinished scheduler.currentSecs) in
  let f (sum,tails) (PlayingSection playingSeq) = (* this takes the heads of secs sums them, and updates the remaining part in the state *)
    match playingSeq.seq () with
    | Nil -> (sum +. 0.0, tails)
    | Cons(x,tail) -> (sum +. x, (PlayingSection { playingSeq with seq = tail })::tails)                  
  in
  let (out,newPlayingSecs) =
    List.fold_left f (0.0,[]) currentSects
  in
  match (future, newPlayingSecs) with (* to deal with reset, if there is no future, then we reset the score *)
  | (Sorted [], []) -> (SectionScheduler 
                    { scheduler with
                     playingScore = scheduler.score
                    ; now = 0
                    ; currentSecs = []
                    ; currentOut = out })
  | (Sorted futureEvts,_) -> (SectionScheduler
                            { scheduler with 
                              playingScore = Sorted futureEvts
                            ; now = scheduler.now + 1
                            ; currentSecs = newPlayingSecs
                            ; currentOut = out })
                       
let printTimedSectionLst timedSectionList =
  let open Format in
  let printSection i (TimedSection s) =
    printf "-section nr %i\nstartSample %i\nduration %i\n" i s.startSample s.duration
  in
  List.iteri printSection timedSectionList
  
  
let printScheduler (SectionScheduler sch) =
  let open Format in
  printf "\n** now: %i **\n score=\n" sch.now;
  printTimedSectionLst (sortedAsList sch.score);
  printf "playing: \n";
  List.iter printPlayingSect sch.currentSecs
  
  
let evaluateScheduler (SectionScheduler scheduler) =
  scheduler.currentOut
    
let playScore score =
  simpleRecursive
    (schedulerOfScore score)
    updateScheduler
    evaluateScheduler

let decay fb inSq =
  recursive
    inSq
    0.0
    (fun input state ->
          (state +. input) *. fb)
    id

let decayPulse fb inSq =
  recursive
    inSq
    0.0
    (fun input state ->
      if input > 0.0 then
        input
      else
        (state +. input) *. fb)
    id
         
