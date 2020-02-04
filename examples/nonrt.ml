open Process

(* writing an audio file in nonrt *)
let _ =
  let snd = Sndfile.fromSeq (44100 * 10) 44100 [sinosc ~.500.; sinosc ~.410.] in
  (* adjust path *)
  Sndfile.write snd "/home/luc/Work/sounds/sines.wav" Sndfile.WAV_16
