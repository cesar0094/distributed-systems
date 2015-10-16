#!/bin/bash

WORKING_DIR="/cs/work/scratch/carodrig/distributed-systems/cat-and-mouse"
SECONDS_PER_LINE=1
PORT=$(cat nc_port_number)

who_found_mouse=""

IFS=$'\n' read -d '' -r -a host_list < hosts

next_host=0

function send_cat() {
	host=$1
	cat_name=$2
	action=$3
	task_time=$4
	echo "Sending $cat_name to $host with action $action"
	parallel-ssh -H ${host_list[$((next_host))]} -i "cd $WORKING_DIR; ./chase_cat.sh $action $cat_name $task_time"
}

function send_cat_attack() {
	send_cat $1 $2 "A" 6
}

function send_cat_search() {
	send_cat $1 $2 "S" 12
}

function found_mouse() {
	host=$1
	cat_name=$2
	echo "Found mouse in $host by $cat_name"

	# If only one cat has found the mouse, we send the other to search
	# Else, we know that the two cats found the mouse, so we attack
	if [[ $who_found_mouse == "" ]]; then
		if [[ $cat_name == "Catty" ]]; then
			send_cat_search $host "Jazzy"
		elif [[ $cat_name  == "Jazzy" ]]; then
			send_cat_search $host "Catty"
		fi
	else
		who_found_mouse=cat_name
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
	another_host=$host_list[$((next_host))]
	next_host=$((next_host+1))
	send_cat_search $another_host $cat_name
}

function caught_mouse() {
	echo "Mouse caught in $host"
	exit 0
}

function terminate() {
	kill $LISTY_PID
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

# start listy
./listy.sh &
LISTY_PID=$!

explore_next_host S Jazzy
explore_next_host S Catty

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

		if [[ $action == "F" ]]; then
			found_mouse $host $cat_name
		elif [[ $action == "N" ]]; then
			echo "Mouse not found in $host by $cat_name."
			explore_next_host $host $cat_name
		elif [[ $action == "G" ]]; then
			caught_mouse
		fi

	else
		echo "Unable to parse message: '$line'"
	fi

	# can only read one line per 4 seconds
	sleep $SECONDS_PER_LINE

done
