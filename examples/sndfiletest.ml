open Process

(* reading the first channel of an audio file *)
let _ =
  (* replace with another  audio file *)
  let snd_file = Sndfile.read "/home/luc/Work/sounds/aurora.wav" in
  let snd = Sndfile.toProc snd_file 0 in
  let filtered = bhpf_static 1350. 1. snd *~ ~.0.3 in
  Jack.play 0 Process.sample_rate [filtered]
