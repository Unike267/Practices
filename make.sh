#/usr/bin/env bash

cd $(dirname "$0")

set +e
latexmk -pdf -f -interaction=nonstopmode main.tex > log.log 2>&1
set -e
latexmk -c

