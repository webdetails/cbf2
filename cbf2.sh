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



DOCKER_CONTAINERS=()
DOCKER_STATUS=()
DOCKER_IDS=()
DOCKER_IMAGES=()


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
IMAGES=$( docker images | egrep '^baserver' | cut -d' ' -f 1 )

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


RUNNING_CONTAINERS=$( docker ps -a -f "name=baserver" --format "{{.ID}}XX{{.Names}}XX{{.Status}}XX{{.Image}}" | grep -v 'pdu-' )

for container in $RUNNING_CONTAINERS
do
  ((n++))
	IFS='XX' read -a ENTRY <<< "$container"

	if [[ ${ENTRY[4]} =~ "Up " ]]; then
		DOCKER_STATUS[$n]="Running"
	else
		DOCKER_STATUS[$n]="Stopped"
	fi

	DOCKER_CONTAINERS[$n]=${ENTRY[2]}
	DOCKER_IDS[$n]=${ENTRY[0]}
  	DOCKER_IMAGES[$n]=${ENTRY[6]}
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


RUNNING_CONTAINERS=$( docker ps -a -f "name=pdu" --format "{{.ID}}XX{{.Names}}XX{{.Status}}XX{{.Image}}" )

for container in $RUNNING_CONTAINERS
do
  ((n++))
	IFS='XX' read -a ENTRY <<< "$container"

	if [[ ${ENTRY[4]} =~ "Up " ]]; then
		DOCKER_STATUS[$n]="Running"
	else
		DOCKER_STATUS[$n]="Stopped"
	fi

	DOCKER_CONTAINERS[$n]=${ENTRY[2]}
	DOCKER_IDS[$n]=${ENTRY[0]}
  	DOCKER_IMAGES[$n]=${ENTRY[6]}
	TYPE[$n]="CONTAINER"
	echo " [$n] (${DOCKER_STATUS[$n]}): ${ENTRY[2]} "
done



echo
read -e -p "> Select an entry number, [A] to add new image or [C] to create new project: " choice

choice=$( tr '[:lower:]' '[:upper:]' <<< "$choice" )

if [ -z $choice ]
then
	echo You have to make a selection
	exit 1
fi

# Add a new image
if [ $choice == "A" ]; then
	source "$BASEDIR/softwareToCoreImages.sh"
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

		read -e -p "> What do you want to do? (L)aunch a new container, (D)elete the image or (I)nspect before launch)? [L]: " operation
		operation=${operation:-L}

		operation=$( tr '[:lower:]' '[:upper:]' <<< "$operation" )

		if ! [ $operation == "L" ] && ! [ $operation == "D" ] && ! [ $operation == "I" ]
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
            
            source "$BASEDIR/setPorts.sh"
            
            # Check for docker volumes
            projectName=$(echo $build | egrep 'pdu-' | cut -d' ' -f 1 | cut -d'-' -f 2)

            if ! [ -z $projectName ] && [ -f $BASEDIR/projects/$projectName/config/dockerVolumes.sh ]
            then
                source "$BASEDIR/projects/$projectName/config/dockerVolumes.sh"

                volumeList=""
                for volume in "${VOLUMES[@]}" ; do

                    pathHost=${volume%%:*}
                    pathContainer=${volume#*:}

                    volumeList+=" -v $pathHost:$pathContainer"
                done
            fi
                        
			if [ $DEBUG == "y" ] || [ $DEBUG == "Y" ]
			then
				eval "docker run $exposePorts -p $debugPort:8044 --name $build-debug -e DEBUG=true $volumeList $build"
			else
				eval "docker run $exposePorts --name $build-debug $volumeList $build"
			fi

		fi

		# Are we inspecting it? it?

		if [ $operation == "I" ]
		then

			docker run --entrypoint bash -i -t --rm $build
			exit 0

		fi

	else

		# Action over the containers
		dockerId=${DOCKER_IMAGES[$choice]}
        dockerImage=${DOCKER_CONTAINERS[$choice]}

		echo
		echo "You selected the container $dockerImage"
		echo


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
			echo " P: See exposed ports"

			if [[ $dockerImage =~ ^pdu ]]; then
				echo " E: Export the solution"
				echo " I: Import the solution"
			fi
			echo

			read -e -p "What do you want to do? [A]: " operation
			operation=${operation:-A}

			operation=$( tr '[:lower:]' '[:upper:]' <<< "$operation" )

			if ! [ $operation == "S" ] && ! [ $operation == "R" ]  && ! [ $operation == "A" ] && ! [ $operation == "E" ] && ! [ $operation == "I" ] && ! [ $operation == "L" ] && ! [ $operation == "P" ] 
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
				docker logs --tail 500 -f $dockerImage
				echo Done
				exit 0
			fi

			if [ $operation == "P" ]; then
                echo "[Container] -> [Host]"
				docker port $dockerImage
				echo Done
				exit 0
			fi

			if [ $operation == "E" ]; then

				read -e -p "Username for the export operation? [admin]: " user
				user=${user:-admin}
				read -e -p "Password for the export operation? [password]: " password
				password=${password:-password}

				project=$(echo $dockerImage | sed -E -e 's/pdu-(.*)-baserver.*/\1/ ' )
				serverDir=ee;
				if [[ $dockerImage =~ ce ]]; then
					serverDir=ce;
				fi

				echo "Exporting $dockerImage to project $project."
				
				echo "Please note that by design CBF2 only exports the folders in public that are already part of the project. You'll need to manually create the directory if you add a top level one."
				echo

				pushd projects/$project/solution/public/ > /dev/null
				
				DIRS=$( ls -d -1 */ )
				IFS=$'\n';

				for dir in $DIRS
				do
					dir=$( echo $dir | sed -E -e 's/\/$//')
					echo Exporting public/$dir...

					docker exec $dockerImage bash -c "cd /pentaho/*server* ; ./import-export.sh --export -a http://127.0.0.1:8080/pentaho -u $user -p $password  -w true -fp /pentaho/export.zip -f /public/$dir"
					docker cp $dockerImage:/pentaho/export.zip .
					unzip -o export.zip > /dev/null
					rm export.zip

				done;

				echo

				popd > /dev/null

			fi

			if [ $operation == "I" ]; then

				read -e -p "Username for the import operation? [admin]: " user
				user=${user:-admin}
				read -e -p "Password for the import operation? [password]: " password
				password=${password:-password}

				project=$(echo $dockerImage | sed -E -e 's/pdu-(.*)-baserver.*/\1/ ' )
				serverDir=ee;
				if [[ $dockerImage =~ ce ]]; then
					serverDir=ce;
				fi

				echo "Importing project $project to $dockerImage..."

				# Zipping the files
				pushd projects/$project/solution/ > /dev/null
				zip -r import.zip public -x "*.DS_Store"

				# Sending it and importing
				docker cp import.zip $dockerImage:/pentaho/ 
				
				docker exec $dockerImage bash -c "cd /pentaho/*server* ; ./import-export.sh --import -a http://127.0.0.1:8080/pentaho -u $user -p $password -fp /pentaho/import.zip -r true --permission=true -f / -c UTF-8 -o true > /dev/null "

				rm import.zip
				popd > /dev/null

			fi

		else

			# Stopped

			echo "The container is stopped; Possible operations:"
			echo " S: Start it"
			echo " D: Delete it"
			echo

			read -e -p "What do you want to do? [S]: " operation
			operation=${operation:-S}

			operation=$( tr '[:lower:]' '[:upper:]' <<< "$operation" )

			if ! [ $operation == "S" ]   && ! [ $operation == "D" ]
			then
				echo Invalid selection
				exit 1;
			fi

			if [ $operation == "S" ]; then
            
                read -e -p "Do you want to start the image $dockerImage in debug mode? [y/N]: " -n 1 DEBUG

                DEBUG=${DEBUG:-"n"}

                source "$BASEDIR/setPorts.sh"
                
                # Check for docker volumes
                projectName=$(echo $dockerImage | egrep 'pdu-' | cut -d' ' -f 1 | cut -d'-' -f 2)
                
                if ! [ -z $projectName ] && [ -f $BASEDIR/projects/$projectName/config/dockerVolumes.sh ]
                then
                    source "$BASEDIR/projects/$projectName/config/dockerVolumes.sh"

                    volumeList=""
                    for volume in "${VOLUMES[@]}" ; do

                        pathHost=${volume%%:*}
                        pathContainer=${volume#*:}

                        volumeList+=" -v $pathHost:$pathContainer"
                    done
                fi

				echo Starting...

                if [ $DEBUG == "y" ] || [ $DEBUG == "Y" ]
                then
                    eval "docker rm -v $dockerImage; docker run $exposePorts -p $debugPort:8044 -e DEBUG=true --name $dockerImage $volumeList $dockerId"
                else
                    eval "docker rm -v $dockerImage; docker run $exposePorts --name $dockerImage $volumeList $dockerId"
                fi
            
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

