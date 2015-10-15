#!/bin/bash

curl -s http://www.cs.helsinki.fi/ukko/hpc-report.txt | awk '/ukko/ && $8 == "cs" && $4 == "yes"' | sort -k6 -n | head -n22 | awk -F'.' '{ print $1".hpc.cs.helsinki.fi" }' | head -n5 > hosts

# parallel-ssh -h hosts -i -A uptime
touch cmsg

