(** An audio synthesis library based on OCaml's [Seq] type. *)

(** {2 Globals} *)

val sample_rate : float ref
(** All processes that need to take the current sample rate into
   account need to refer to this variable.*)

val input_array : float array
(** The array of input values. This should accessed using the [input] function. *)

val input_channels : int ref
(** The number of input channels*)

val pi : float

val two_pi : float

val empty_state : 'a array

type sample_counter = int

type 'output t

(** {2 Creating and Accessing Processes} *)

val mk : float array -> (float array -> int -> float array * 'a) -> 'a -> 'a t

val mk_no_state : (float array -> int -> float array * 'a) -> 'a -> 'a t

val last_value : 'a t -> 'a

val idx : int -> int

val previous_value : 'a t -> int -> 'a

val generate_next : 'a t -> 'a

val value_at : 'a t -> sample_counter -> 'a

val generate : 'a t -> sample_counter -> 'a

val toLst : int -> 'a t -> 'a list

val toSeq : 'a t -> 'a Seq.t

val const : 'a -> 'a t

val ( ~. ) : 'a -> 'a t

val from_ref : 'a ref -> 'a t

(** {2 Applying Functions on Processes} *)

val map : ('a -> 'b) -> 'a t -> 'b t

val zip : ('a -> 'b -> 'c) -> 'a t -> 'b t -> 'c t

(** {2 Arithmetic Operations} *)

val add : float t -> float t -> float t

val sum : float t list -> float t

val ( +~ ) : float t -> float t -> float t

val ( *~ ) : float t -> float t -> float t

val ( -~ ) : float t -> float t -> float t

val ( /~ ) : float t -> float t -> float t

val ( **~ ) : float t -> float t -> float t

(** {2 Audio Input} *)

val input : int -> float t

(** {2 Delays} *)

val del1 : 'a t -> 'a t

(** {2 Recursive Connections} *)

val recursive : 'a -> ('a t -> 'a t) -> 'a t

(** {2 Integration} *)

val integrate : float t -> float t

val inc : float -> float -> float t

val inc_int : int -> int -> int t

(** {2 Noise} *)

val rnd : float t

(** {2 Oscillators} *)

val sinosc : float t -> float t

val fm_feedback : float t * float t -> float t * float t -> (float * float) t

val calc_diffs : float list -> float list

val kuramoto : float list -> float -> float -> float list t

val impulse : float t -> float t

(** {2 Filters} *)

val lpf1_static : float t -> float -> float t

val biquad_static :
  float t -> float -> float -> float -> float -> float -> float -> float t

val blpf_static : float -> float -> float t -> float t

val bhpf_static : float -> float -> float t -> float t

val bbpf_static : float -> float -> float t -> float t

val map_succ : ('a -> 'a -> 'b) -> 'a list -> 'b list

val geo_series : int -> float -> float -> float list

val geo_from_to : int -> float -> float -> float list

val min_sub_freq : float -> float -> float

val min_sub_freqs : float list -> float list

val casc2_band : float -> float -> float -> float t -> float t

val casc_bank : float -> int -> float -> float -> float t -> float t list

val fbank_subtract :
     (float -> 'a -> float t -> float t)
  -> 'a
  -> int
  -> float
  -> float
  -> float t
  -> float t list

val fbank_map :
  (float -> 'a -> 'b -> 'c) -> 'a -> int -> float -> float -> 'b -> 'c list

(** {2 Analysis} *)

val rms : float -> float t -> float t

(** {2 Multichannel Operations} *)

val evert : 'a list t -> 'a t list

val pan2 : float t -> float t -> float t list

val pan2_const : float t -> float -> float t list

val splay : float t list -> float t list

val split : ('a * 'a) t -> 'a t list

val ( |>> ) : 'a list -> ('a -> 'b) list -> 'b list

val ( ||> ) : 'a list -> ('a -> 'b) -> 'b list
