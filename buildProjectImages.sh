#!/bin/bash

# Builds a project that is in the project subdirectory. It always uses
# a local pentaho server image to build from, so that has to exist previously

# 1. Check if we have local images; if not, send to listBuilds
# 2. List the projects we have; Ask to select one
# 3. After selecting a project, select the base image to use
# 4. Dynamically change the project-specific dockerfile to change the FROM
# 5. Zip the solutions and prepare to drop them in default-content
# 6. Find a way to create the datasources. Maybe with the patches?
# 7. Build it

BASEDIR=$(dirname $0)
cd $BASEDIR
PROJECTS_DIR="projects"


# 1. Search for what we have
IMAGES=$( docker images | egrep '^baserver-(ee|merged)' | cut -d' ' -f 1 )

if ((  $(grep -c . <<< "$IMAGES" ) == 0 ))
then
  echo No valid local images found. Please create one
  exit 1
fi



# 2. List the projects; Choose one

PROJECTS=$(ls -d -1 $PROJECTS_DIR/*/)

if ((  $(grep -c . <<< "$PROJECTS" ) == 0 ))
then
  echo No projects found in the $PROJECTS_DIR directory. Maybe you forgot to link / clone?
  exit 1
fi

echo
echo "Choose a project to build an image for:"
echo

IFS=$'\n';
n=-1

for project in $PROJECTS
do
  ((n++))
	projectname=$(echo $project | rev | cut -d/ -f2 | rev)
  echo " [$n] $projectname"
  PROJECT_LIST[$n]=$projectname
done;

echo


# Which version do you want to start?
read -e -p "> Choose project: " PROJECTNO
PROJECTNO=${PROJECTNO:-"-1"}

if [ $PROJECTNO == "-1" ] 
then
	echo Invalid selection
	exit 1;
fi


project=${PROJECT_LIST[$PROJECTNO]}

if [ -z $project ]
then
  echo Invalid selection [$PROJECTNO]
  exit 1
fi


# 3. Select the base image to use


echo
echo Select the image to use for the project
echo



IFS=$'\n';
n=-1

for image in $IMAGES
do
  ((n++))
  echo " [$n] $image"
  IMAGE[$n]=$image
done;

echo


# Which version do you want to start?
read -e -p "> Choose image: " IMAGENO
IMAGENO=${IMAGENO:-"-1"}

if [ $IMAGENO == "-1" ] 
then
	echo Invalid selection
	exit 1;
fi

image=${IMAGE[$IMAGENO]}

if [ -z $image ]
then
  echo Invalid selection [$IMAGENO]
  exit 1
fi

echo you chose: Project: $project, Image: $image 


# 4. Dynamically change the project-specific dockerfile to change the FROM
tmpDir=tmp/buildProjectTmp

# We'll use one of two things: If we have a project-specific Dockerfile, we'll 
# go for that one; if not, we'll use a default. 
# We'll also build a tmp dir for processing the stuff

if [ -d $tmpDir ]
then
	rm -rf $tmpDir
fi

mkdir -p $tmpDir

if [ -f $PROJECTS_DIR/$project/_dockerfiles/Dockerfile ]
then
	echo " Found a project specific dockerfile. That's what we'll use"
	cp -r $PROJECTS_DIR/$project/_dockerfiles/* $tmpDir

else
	echo " Project specific dockerfile not found. Using default"
	cp -r dockerfiles/buildProject/* $tmpDir
fi

sed -i '' -e "s/BUILDPROJECTFROMIMAGE/$image/" $tmpDir/Dockerfile



# 5. Zip the solutions and prepare to drop them in default-content

echo 
echo Adding the structure to the build
echo

mkdir $tmpDir/public
cp -R $PROJECTS_DIR/$project/[^_]* $tmpDir/public
pushd $tmpDir
zip -r solution.zip public/
popd

DOCKERTAG=pdu-$project-$image

echo
echo All set - building docker image $DOCKERTAG
echo


# 6. Find a way to create the datasources. Maybe with the patches?


# 7. Build it

docker build -t $DOCKERTAG $tmpDir

# 8. Clean it

rm -rf $tmpDir

echo 
echo Project image built successfully
echo

cd $BASEDIR

exit 0
