#!/bin/bash

BASEDIR=$(dirname $0)

echo
echo Core Images found:
echo ---------------------
echo



# 1. Search for what we have
IMAGES=$( docker images | egrep '^baserver-(ee|merged)' | cut -d' ' -f 1 )

IFS=$'\n';
n=-1


for image in $IMAGES
do
  ((n++))
  echo  [$n] $image
  BUILD[$n]=$image
done;

echo


# Which image?
read -e -p "Select an image: " IMAGENO
IMAGENO=${IMAGENO:-"-1"}

if [ $IMAGENO == "-1" ] 
then
	echo Invalid selection
	exit 1;
fi

build=${BUILD[$IMAGENO]}

if [ -z $build ]
then
  echo Invalid selection [$IMAGENO]
  exit 1
fi

echo
echo You selected $build

read -e -p "What do you want to do? (L)aunch it or (D)elete it? [L]: " operation
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

cd $BASEDIR
exit 0

