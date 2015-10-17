#!/bin/bash

curl -s http://www.cs.helsinki.fi/ukko/hpc-report.txt | awk '/ukko/ && $8 == "cs" && $4 == "yes"' | sort -k6 -n | head -n22 | awk -F'.' '{ print $1".hpc.cs.helsinki.fi" }' | head -n40 > hosts

touch cmsg
touch valid_hosts

echo "$(hostname).hpc.cs.helsinki.fi" > listy_location

hosts_num=0

# make sure the hosts we are using require password-less ssh.
while read host; do

	echo "$host"
	process_in_port=$(echo "$process_in_port" | grep nc | awk '{ print $2 }')
	parallel-ssh -H $host -i "cd $WORKING_DIR" && echo "$host" >> valid_hosts && \
		hosts_num=$((hosts_num+1))

done < hosts

mv valid_hosts hosts
