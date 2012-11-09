#!/bin/bash

if test -z "$1"
then
  echo "Error: usage: debug_binary_data_file.sh <binary_file_path>"
  exit 1
fi

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

CURRENT_RVM=`rvm current`

rvm use 1.8.7

./ruby/binary_fact_debugger_bisect.rb $1

echo
echo
echo
echo "Processing binary data with ruby 1.8.7: "

./ruby/print_file_as_hex.rb ./bad_binary_data.out

echo
echo
echo
echo "Processing binary data with ruby 1.9.3: "

rvm use 1.9.3

./ruby/print_file_as_hex.rb ./bad_binary_data.out

echo
echo
echo
echo "Processing binary data with clojure 1.4: "

java -cp ./clj/clojure-1.4.0.jar clojure.main ./clj/print_file_as_hex.clj

echo
echo
echo

rvm use $CURRENT_RVM

