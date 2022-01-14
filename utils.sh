#!/bin/bash

#
# some utility functions...
#

#############################
######### Functions #########
#############################

promptUser() {

	# This function accepts a OPTIONS array and return an CHOICE index
	
	prompt=$1
	default=$2
	question=${3:-"Make a selection"}

	echo
	echo $prompt

	i=0
	for p in "${OPTIONS[@]}" 
	do
		echo " [$i]: $p"
		((i++))
	done
	echo

	read -e -p "$question [$default]: " CHOICE
	CHOICE=${CHOICE:-"$default"}


	if ! [ "$CHOICE" -eq "$CHOICE" ] || [ "$CHOICE" -lt 0 ] || [ "$CHOICE" -ge "${#OPTIONS[@]}" ] 2>/dev/null
	then
		echo Invalid choice: $CHOICE
		exit 1;
	fi

	echo


}

getTimeZone() {

	# Check to see if the user has a timezone set.
	TZ_HOST=${TZ}

	if [ -z ${TZ_HOST} ]
	then
		
		# Check to see if the system has timezone set
		TZ_HOST=`timedatectl 2>/dev/null | grep "Time zone:" | awk '{print $3}'`
		if [ -z ${TZ_HOST} ]
		then
			# Use default Timezone
			TZ_HOST="UTC"
		fi	
	fi
}
