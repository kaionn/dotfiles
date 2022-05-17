#!/bin/sh

file="${HOME}/.zsh.d/famous-saying.json"
num=$(cat ${file} | jq length | xargs -I{} expr $RANDOM % {})
cat ${file} | jq -r '.['${num}'] | .result = .saying + " - " + .person | .result'
