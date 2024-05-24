#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

cd ../sim/slink

echo "Start test"

./run.py -v
DESIGN=mult ./latency.py -v
DESIGN=multp-wfifos ./latency.py -v
DESIGN=multp ./latency.py -v
DESIGN=mult ./throughput.py -v
DESIGN=multp-wfifos ./throughput.py -v
DESIGN=multp ./throughput.py -v

echo "Test completed"
