dune build @doc-private
rm -r doc/*
cp -r _build/default/_doc/_html/* doc/

# ocamldoc -d doc/ -html -I _build/src/process src/process/process.mli src/jack/jack.mli  src/sndfile/sndfile.mli 
