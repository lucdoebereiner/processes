#!/bin/bash
dune exec ./decoherence.exe &
sleep 4

jack_lsp

sleep 1
#echo "ok start connecting"

jack_connect system:capture_1 ocaml:input_0
jack_connect system:capture_1 ocaml:input_3
jack_connect system:capture_1 ocaml:input_4
jack_connect system:capture_1 ocaml:input_0
jack_connect system:capture_1 ocaml:input_3
jack_connect system:capture_1 ocaml:input_4
jack_connect system:capture_1 ocaml:input_0
jack_connect system:capture_1 ocaml:input_3

sleep 1


