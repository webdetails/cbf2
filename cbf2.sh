#!/bin/bash

###############################################################################
# 
# Welcome to CBF 2.0.
#
# The goal of the project is to make my life easier when it comes to managing
# Pentaho projects' lifecycle. 
#
# Author: Pedro Alves
# License: Whatever... Apache2 if I have to pick one
#
###############################################################################

VERSION=0.9

# Lists the clients and starts / delets
BASEDIR=$(dirname $0)
source "$BASEDIR/utils.sh"
cd $BASEDIR


# We're going to do a few things here; 
# 1. Show the core images
# 2. Show the core container based on the previous images
# 3. Show the project images
# 4. Show the projects based on the previous images
#
# Each selection will have it's own option; On top of that we'll have the
# following:
# 1. Add new core images
# 2. Create new project



DOCKER_IMAGES=()
DOCKER_STATUS=()
DOCKER_IDS=()


# Get list of files

echo
echo "--------------------------------------------------------------"
echo "--------------------------------------------------------------"
echo "------       CBF2 - Community Build Framework 2        -------"
echo "------                 Version: $VERSION                    -------"
echo "------ Author: Pedro Alves (pedro.alves@webdetails.pt) -------"
echo "--------------------------------------------------------------"
echo "--------------------------------------------------------------"


echo
echo Core Images available:
echo ----------------------
echo


# 1. Search for what we have
IMAGES=$( docker images | egrep '^baserver-(ee|merged)' | cut -d' ' -f 1 )

IFS=$'\n';
n=-1

for image in $IMAGES
do
  ((n++))
  echo " [$n] $image"
  BUILD[$n]=$image
	TYPE[$n]="IMAGE"
done;


echo
echo Core containers available:
echo --------------------------
echo 


RUNNING_CONTAINERS=$( docker ps -a -f "name=baserver" --format "{{.ID}}XX{{.Names}}XX{{.Status}}" | grep -v 'pdu-' )

for container in $RUNNING_CONTAINERS
do
  ((n++))
	IFS='XX' read -a ENTRY <<< "$container"

	if [[ ${ENTRY[4]} =~ "Up " ]]; then
		DOCKER_STATUS[$n]="Running"
	else
		DOCKER_STATUS[$n]="Stopped"
	fi

	DOCKER_IMAGES[$n]=${ENTRY[2]}
	DOCKER_IDS[$n]=${ENTRY[0]}
	TYPE[$n]="CONTAINER"
	echo " [$n] (${DOCKER_STATUS[$n]}): ${ENTRY[2]} "
done


echo
echo Project images available:
echo -------------------------
echo


# 1. Search for what we have
IMAGES=$( docker images | egrep 'pdu-' | cut -d' ' -f 1 )
IFS=$'\n';

for image in $IMAGES
do
  ((n++))
  echo " [$n] $image"
  BUILD[$n]=$image
	TYPE[$n]="IMAGE"
done;


echo
echo Project containers available:
echo -----------------------------
echo 


RUNNING_CONTAINERS=$( docker ps -a -f "name=pdu" --format "{{.ID}}XX{{.Names}}XX{{.Status}}" )

for container in $RUNNING_CONTAINERS
do
  ((n++))
	IFS='XX' read -a ENTRY <<< "$container"

	if [[ ${ENTRY[4]} =~ "Up " ]]; then
		DOCKER_STATUS[$n]="Running"
	else
		DOCKER_STATUS[$n]="Stopped"
	fi

	DOCKER_IMAGES[$n]=${ENTRY[2]}
	DOCKER_IDS[$n]=${ENTRY[0]}
	TYPE[$n]="CONTAINER"
	echo " [$n] (${DOCKER_STATUS[$n]}): ${ENTRY[2]} "
done



echo
read -e -p "> Select an entry number, [A] to add new image or [C] to create new project: " choice

if [ -z $choice ]
then
	echo You have to make a selection
	exit 1
fi

# Add a new image
if [ $choice == "A" ]; then
	source "$BASEDIR/buildCoreImages.sh"
fi

# Create project
if [ $choice == "C" ]; then
	source "$BASEDIR/buildProjectImages.sh"
fi


if ! [ "$choice" -eq "$choice" ] || [ "$choice" -lt 0 ] || [ "$choice" -gt "$n" ] 2>/dev/null
then
	echo Invalid choice: $choice
	exit 1;
else

	if [ ${TYPE[$choice]} == "IMAGE" ]
	then

		# Action over the images
		build=${BUILD[$choice]}

		echo
		echo You selected the image $build
		echo

		read -e -p "> What do you want to do? (L)aunch a new container or (D)elete the image? [L]: " operation
		operation=${operation:-L}

		if ! [ $operation == "L" ] && ! [ $operation == "D" ]
		then
			echo Invalid selection
			exit 1;
		fi

		# Are we deleting it?

		if [ $operation == "D" ]
		then
			docker rmi $build
			echo Removed successfully
			exit 0
		fi


		# Are we launching it?

		if [ $operation == "L" ]
		then

			read -e -p "Do you want to start the image $build in debug mode? [y/N]: " -n 1 DEBUG

			DEBUG=${DEBUG:-"n"}

			if [ $DEBUG == "y" ] || [ $DEBUG == "Y" ]
			then
				docker run -p 8080:8080 -p 8044:8044 -p 9001:9001 --name $build-debug -e DEBUG=true $build
			else
				docker run -p 8080:8080 -p 9001:9001 --name $build-debug $build

			fi

		fi

	else

		# Action over the containers
		build=${BUILD[$choice]}

		echo
		echo You selected the container $build
		echo

		dockerImage=${DOCKER_IMAGES[$choice]}

		echo 

		# Now, different options depending on the status

		if [[ ${DOCKER_STATUS[$choice]} == "Running" ]]
		then

			echo "The container is running; Possible operations:"
			echo
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
				docker logs -f $dockerImage
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

			echo "The container is stopped; Possible operations:"
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


	fi

	echo all good so far

fi


cd $BASEDIR

exit 0

