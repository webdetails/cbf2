#!/bin/bash

BASEDIR=$(dirname $0)
source "$BASEDIR/utils.sh"
cd $BASEDIR

# Processes the main software files to build the main images.
# The installation process is very different from CE and EE

# CE:
#   1) Unzip file to a directory
#   2) Call CE docker file
#
# EE:
#   1) Extract main server while accepting the EULA
#   2) Extract the other plugins
#   3) Extract the service packs
#   4) Get licenses in place
#   5) Call EE docker file


SOFTWARE_DIR=software
LICENSES_DIR=licenses


# Get list of files

SERVERFILES=$( ls -1 $SOFTWARE_DIR/*/biserver* )

IFS=$'\n';
n=-1

echo

SERVERFILESARRAY=()
OPTIONS=();

for serverFile in $SERVERFILES
do
	SERVERFILESARRAY=("${SERVERFILESARRAY[@]}" $serverFile)
	OPTIONS=("${OPTIONS[@]}" $(echo $serverFile | cut -d / -f3) )
done;


promptUser "Servers found on the $SOFTWARE_DIR dir:" $(( ${#OPTIONS[@]} - 1 )) "Choose the server to install" 
serverChoiceIdx=$CHOICE
server=${OPTIONS[$CHOICE]}
serverFile=${SERVERFILESARRAY[$serverChoiceIdx]}
DOCKERTAG=$(echo $server | sed -E -e 's/biserver/baserver/; s/(-dist)?\.zip//' | tr '[:upper:]' '[:lower:]')

# echo "Server chosen: $server ($serverChoiceIdx); File: $serverFile; Docker tag: $DOCKERTAG"


# 4. Dynamically change the project-specific dockerfile to change the FROM
tmpDir=dockerfiles/tmp

# We'll use one of two things: If we have a project-specific Dockerfile, we'll 
# go for that one; if not, we'll use a default. 
# We'll also build a tmp dir for processing the stuff

if [ -d $tmpDir ]
then
	rm -rf $tmpDir
fi

mkdir -p $tmpDir

# Now - we need to check if we have the cbf2-core docker image. Else, we need to build it

if  [[ ! $( docker images | grep cbf2-core ) ]]; then

	echo Base imagee not found. Building cbf2-core...
	docker build -t cbf2-core -f dockerfiles/Dockerfile-CoreCBF dockerfiles

fi


if [[ $server =~ -ce- ]]
then

	echo Unzipping files...
	mkdir $tmpDir/pentaho
	unzip $serverFile -d $tmpDir/pentaho > /dev/null

	echo Creating docker image...
	docker build -t $DOCKERTAG -f dockerfiles/Dockerfile-CE-FromFile dockerfiles


else

	echo	docker build --build-arg BOX_URL=$BOX_URL --build-arg BOX_USER=$BOX_USER --build-arg BOX_PASSWORD=$BOX_PASSWORD --build-arg BRANCH=$branch --build-arg BUILD=$buildno --build-arg PRODUCT=$product -t $DOCKERTAG -f dockerfiles/Dockerfile-EE dockerfiles

fi


if [ $? -ne 0 ] 
then
	echo
	echo An error occurred...
	exit 1
fi


echo Done. You may want to use the ./cff2.sh command

rm -rf $tmpDir
cd $BASEDIR
exit 0



echo  ... connecting to box to get the nightlies

for i in ${VERSIONS[@]}; do
	
	result=$(lftp -c "open -u $BOX_USER,$BOX_PASSWORD $BOX_URL ; cls -1 --sort date $i | head -n 1");

	BRANCH=$(echo $result | cut -f1 -d/)
	BUILD=$(echo $result | cut -f2 -d/)
	echo Nightly available - Branch: $BRANCH , Build number: $BUILD
done

# Are we done?
read -e -p "Do you want to build the image? [y/N]: " -n 1 ANSWER
ANSWER=${ANSWER:-"n"}

if ! [ $ANSWER == "y" ] || [ $ANSWER == "Y" ]
then
	exit 0;
fi

echo 

# Ask for branch
read -e -p "Which branch? [$BRANCH]: " branch
branch=${branch:-$BRANCH}

# Ask for buildno
read -e -p "Which build number? [$BUILD]: " buildno
buildno=${buildno:-$BUILD}

# Ask for product
read -e -p "Which server ('ee', 'merged-ee', 'ce' or 'merged-ce')? [$PRODUCT]: " product
product=${product:-$PRODUCT}

read -e -p 'Press any key to start building docker image. This will take a while...' -n 1 foo

# Docker doesn't accept tag names in uppercase
DOCKERTAG=$(echo "baserver-$product-$branch-$buildno" | tr '[:upper:]' '[:lower:]')


if [[ $product =~ ^.*ce$ ]]
then

	docker build --build-arg JAVA_VERSION=8 -t $DOCKERTAG -f dockerfiles/Dockerfile-CE-FromFile dockerfiles

else

	docker build --build-arg BOX_URL=$BOX_URL --build-arg BOX_USER=$BOX_USER --build-arg BOX_PASSWORD=$BOX_PASSWORD --build-arg BRANCH=$branch --build-arg BUILD=$buildno --build-arg PRODUCT=$product -t $DOCKERTAG -f dockerfiles/Dockerfile-EE dockerfiles

fi


if [ $? -ne 0 ] 
then
	echo
	echo An error occurred...
	exit 1
fi


# Suggest going to the nightly start
echo Done. You may want to use the ./startNightly.sh command

rm -rf $tmpDir
cd $BASEDIR
exit 0
