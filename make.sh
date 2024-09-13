#!/usr/bin/env bash

cd $(dirname "$0")

apt update -qq

set +e
latexmk --shell-escape -pdf -f -interaction=nonstopmode main.tex > log.log 2>&1
set -e
latexmk -c

