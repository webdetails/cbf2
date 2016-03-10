#!/bin/bash

# Lists the clients and starts / delets
BASEDIR=$(dirname $0)


DOCKER_IMAGES=()
DOCKER_STATUS=()
DOCKER_IDS=()


# Get list of files


echo
echo Containers
echo -----------
echo 

n=-1;

RUNNING_CONTAINERS=$( docker ps -a -f status=running -f "name=pdu" --format "{{.ID}}XX{{.Names}}XX{{.Status}}" )

IFS=$'\n';

for container in $RUNNING_CONTAINERS
do
  ((n++))
	IFS='XX' read -a ENTRY <<< "$container"
	echo " [$n] (Running): ${ENTRY[2]} "
	DOCKER_IMAGES[$n]=${ENTRY[2]}
	DOCKER_STATUS[$n]="Running"
	DOCKER_IDS[$n]=${ENTRY[0]}
done


STOPPED_CONTAINERS=$( docker ps -a -f status=exited -f status=paused -f "name=pdu" --format "{{.ID}}XX{{.Names}}XX{{.Status}}" )

IFS=$'\n';

for container in $STOPPED_CONTAINERS
do
  ((n++))
	IFS='XX' read -a ENTRY <<< "$container"
  echo " [$n] (Stopped): ${ENTRY[2]} "
	DOCKER_IMAGES[$n]=${ENTRY[2]}
	DOCKER_STATUS[$n]="Stopped"
	DOCKER_IDS[$n]=${ENTRY[0]}
done

echo

# Get a selection

read -e -p "Select a container: " containerNo

if [ -z $containerNo ] || [ -z ${DOCKER_IMAGES[$containerNo]} ]
then
	echo Invalid option: $containerNo
	exit 1
fi

dockerImage=${DOCKER_IMAGES[$containerNo]}

echo 

# Now, different options depending on the status

if [[ ${DOCKER_STATUS[$containerNo]} == "Running" ]]
then

	echo "  The container is running"

	echo "Possible operations:"
	echo " S: Stop it"
	echo " R: Restart it"
	echo " A: Attach to it"
	echo " L: See the Logs"
	echo " E: Export the solution"
	echo " I: Import the solution"
	echo

	read -e -p "What do you want to do? [A]: " operation
	operation=${operation:-A}

	if ! [ $operation == "S" ] && ! [ $operation == "R" ]  && ! [ $operation == "A" ] && ! [ $operation == "E" ] && ! [ $operation == "I" ] && ! [ $operation == "L" ] 
	then
		echo Invalid selection
		exit 1;
	fi

	if [ $operation == "S" ]; then
		echo Stopping...
		docker stop $dockerImage
		echo $dockerImage stopped successfully
		exit 0
	fi

	if [ $operation == "R" ]; then
		echo Restarting...
		docker stop $dockerImage
		echo $dockerImage restarted successfully
		exit 0
	fi

	if [ $operation == "A" ]; then
		docker exec -it $dockerImage bash
		echo Done
		exit 0
	fi

	if [ $operation == "L" ]; then
		docker logs $dockerImage | less
		echo Done
		exit 0
	fi

	if [ $operation == "E" ]; then
		echo "[Error] Not done yet"
		exit 1
	fi

	if [ $operation == "I" ]; then
		echo "[Error] Not done yet"
		exit 1
	fi

else

	# Stopped

	echo "Possible operations:"
	echo " S: Start it"
	echo " D: Delete it"
	echo

	read -e -p "What do you want to do? [S]: " operation
	operation=${operation:-S}

	if ! [ $operation == "S" ]   && ! [ $operation == "D" ]
	then
		echo Invalid selection
		exit 1;
	fi

	if [ $operation == "S" ]; then
		echo Starting...
		docker start $dockerImage
		echo $dockerImage started successfully
		exit 0
	fi

	if [ $operation == "D" ]; then
		docker rm $dockerImage
		echo Done
		exit 0
	fi

fi



cd $BASEDIR

exit 0


