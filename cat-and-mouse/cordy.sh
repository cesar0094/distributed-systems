#!/bin/bash

WORKING_DIR="/cs/work/scratch/carodrig/distributed-systems/cat-and-mouse"
SECONDS_PER_LINE=4
PORT=$(cat nc_port_number)
NEXT_HOST_FILE="next_host"
NEXT_HOST_LOCK="next_host.lock"

who_found_mouse=""

IFS=$'\n' read -d '' -r -a host_list < hosts

next_host=0

function send_cat() {
	host=$1
	cat_name=$2
	action=$3

	# Since we have limited number of cats, we make sure to only use that number
	# a cat will be ready to go once it messages listy

	# acquire resource (cat)
	lockfile $cat_name".lock"

	echo "Sending $cat_name to $host with action $action"
	ssh $host "cd $WORKING_DIR; ./chase_cat.sh $action $cat_name" &>/dev/null

	# release the cat resource
	rm -f $cat_name".lock"
}

function send_cat_attack() {
	send_cat $1 $2 "A"
}

function send_cat_search() {
	send_cat $1 $2 "S"
}

function found_mouse() {
	host=$1".hpc.cs.helsinki.fi"
	cat_name=$2
	echo "Found mouse in $host by $cat_name"

	# If only one cat has found the mouse, we send the other to search
	# Else, we know that the two cats found the mouse, so we attack
	if [[ $who_found_mouse == "" ]]; then
		who_found_mouse=cat_name
		if [[ $cat_name == "Catty" ]]; then
			send_cat_search $host "Jazzy"
		elif [[ $cat_name  == "Jazzy" ]]; then
			send_cat_search $host "Catty"
		fi
	else
		if [[ $cat_name == "Catty" ]]; then
			send_cat_attack $host "Jazzy"
		elif [[ $cat_name  == "Jazzy" ]]; then
			send_cat_attack $host "Catty"
		fi
	fi
	# TODO: handle where one cat finds in and the other doesn't
}

function explore_next_host() {
	explored_host=$1
	cat_name=$2

	# (LOCK) protect access to next host
	lockfile $NEXT_HOST_LOCK

	next_host=$(cat $NEXT_HOST_FILE)
	another_host=${host_list[$((next_host))]}
	next_host=$((next_host+1))
	echo "$next_host" > $NEXT_HOST_FILE

	# (UNLOCK)
	rm -f $NEXT_HOST_LOCK

	send_cat_search $another_host $cat_name
}

function caught_mouse() {
	echo "Mouse caught in $host"
	echo "QUIT" | nc 127.0.0.1 $PORT
	exit 0
}

function terminate() {
	echo "QUIT" | nc 127.0.0.1 $PORT
	exit 0
}

trap terminate INT

process_in_port=$(lsof -i :$PORT)

if [[ "$process_in_port" != "" ]]; then
	process_in_port=$(echo "$process_in_port" | grep nc | awk '{ print $2 }')
	echo "$process_in_port is using port $PORT."
	exit
fi

# cmsg should be empty.
rm cmsg; touch cmsg

# (LOCK)
lockfile $NEXT_HOST_LOCK
# init next_host
echo "0" > $NEXT_HOST_FILE
# (UNLOCK)
rm -f $NEXT_HOST_LOCK

# start listy
./listy.sh &
LISTY_PID=$!

# start the cats
explore_next_host S Jazzy &
sleep 1
explore_next_host S Catty &
sleep 1

# now we listen to cmsg file to see what to do next
echo "Listening to cmsg"
tail -n0 -F cmsg | \
while read line; do

	# match the pattern: F ukkoXXX catname
  	if [[ $line =~ [FGN]\ [a-z0-9]+\ (Jazzy|Catty) ]]
	then
		action=$(echo $line | awk '{ print $1 }')
		host=$(echo $line | awk '{ print $2 }')
		cat_name=$(echo $line | awk '{ print $3 }')

		if [[ "$action" == "F" ]]; then
			found_mouse $host $cat_name &
		elif [[ "$action" == "N" ]]; then
			echo "Mouse not found in $host by $cat_name"
			# only explore next host if the other cat hasn't found the mouse
			if [[ "$who_found_mouse" == "" ]]; then
				explore_next_host $host $cat_name &
			fi
		elif [[ "$action" == "G" ]]; then
			caught_mouse
		fi

	else
		echo "Unable to parse message: '$line'"
	fi

	# can only read one line per 4 seconds
	sleep $SECONDS_PER_LINE

done
