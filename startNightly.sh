#!/bin/bash

# 1. Search for what we have
IMAGES=$( docker images | egrep 'baserver-(ee|merged)' | cut -d' ' -f 1 )

IFS=$'\n';
n=-1


for image in $IMAGES
do
  ((n++))
  echo  [$n] $image
  BUILD[$n]=$image
done;

echo


# Which version do you want to start?
read -e -p "Which image to start?: " IMAGENO
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

# Are we done?

read -e -p "Do you want to start the image $build in debug mode? [y/N]: " -n 1 DEBUG

DEBUG=${DEBUG:-"n"}

if [ $DEBUG == "y" ] || [ $DEBUG == "Y" ]
then
  docker run -p 8080:8080 -p 8044:8044 -p 9001:9001 --name $build-debug -e DEBUG=true $build
else
  docker run -p 8080:8080 -p 9001:9001 --name $build-debug $build

fi

