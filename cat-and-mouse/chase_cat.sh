#!/bin/bash

LISTY_LOCATION=$(cat listy_location)
HOSTNAME=$(hostname)
WAIT_AFTER_ATTACK=8
SEARCH_TIME=1
ATTACK_TIME=1

MY_NAME=$2
ACTION=$1
TASK_TIME=$3
MOUSE_PORT=$(cat nc_port_number)
LISTY_PORT=$(cat nc_port_number)
TIMEOUT=1

function got_mouse() {
	# got the mouse
	echo "G $HOSTNAME $MY_NAME" | nc $LISTY_LOCATION $LISTY_PORT
	exit 1
}

function attack_mouse() {
	echo "MEOW" | nc localhost $MOUSE_PORT
	# non-blocking wait/sleep for mouse to interrupt process
	sleep $WAIT_AFTER_ATTACK &
	wait
	echo "Error! Something went wrong with the attack"
}

function search_for_mouse() {

	process_in_port=$(lsof -i :$MOUSE_PORT | grep nc | awk '{ print $2 }')

	if [[ "$process_in_port" != "" ]]; then
		echo "F $HOSTNAME $MY_NAME" | nc $LISTY_LOCATION $LISTY_PORT
	else
		echo "N $HOSTNAME $MY_NAME" | nc $LISTY_LOCATION $LISTY_PORT
	fi

}

trap got_mouse INT

if [[ "$ACTION" == "S" ]]; then
	sleep $SEARCH_TIME
	search_for_mouse
elif [[ "$ACTION" == "A" ]]; then
	sleep $ATTACK_TIME
	attack_mouse
else
	echo "Unknown action: '$ACTION'"
fi
