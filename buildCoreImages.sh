#!/bin/bash

#
# These are the variables that need to be set
#

#BOX_USER=pedro.alves@pentaho.com
#BOX_PASS=XXXXXX

if [ -z $BOX_USER ]
then
	echo The following variables have to be set:
  echo BOX_USER
  echo BOX_PASSWORD
  echo "Optionally, override BOX_URL (set to ftp.box.com/CI)"
  exit 1
fi

#VERSIONS=()
VERSIONS=(6.1-QAT 7.0-QAT)
BOX_URL=${BOX_URL:-ftp.box.com/CI}
PRODUCT=ee

# Stable builds

echo Release available - Branch: 5.4.0.9 , Buind number: 162
echo Release available - Branch: 6.0.1.0 , Buind number: 386

# Get list of files
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

	docker build --build-arg BOX_URL=$BOX_URL --build-arg BOX_USER=$BOX_USER --build-arg BOX_PASSWORD=$BOX_PASSWORD --build-arg BRANCH=$branch --build-arg BUILD=$buildno --build-arg PRODUCT=$product -t $DOCKERTAG -f dockerfiles/Dockerfile-CE dockerfiles


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


exit 0
