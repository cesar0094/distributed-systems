#!/bin/bash

curl -s http://www.cs.helsinki.fi/ukko/hpc-report.txt | awk '/ukko/ && $8 == "cs"' | sort -k6 -n | head -n22 | awk -F'.' '{ print $1".hpc.cs.helsinki.fi" }' | head -n5 > hosts

pssh -h hosts -i -A uptime
touch cmsg

MOUSE_LOCATION=$(shuf -n 1 hosts)
cat mouse.sh | parallel-ssh -H $MOUSE_LOCATION -i "mkdir cat-and-mouse; cd cat-and-mouse; cat > mouse.sh; sh mouse.sh"

