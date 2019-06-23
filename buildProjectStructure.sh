#!/bin/bash

# Builds a project that is in the project subdirectory. It always uses
# a local pentaho server image to build from, so that has to exist previously

# 1. Define project/folder  Name
# 2. Do you want to define a custom theme?
# 3. Clean it

BASEDIR=$(dirname $0)
cd $BASEDIR
PROJECTS_DIR="projects"


# 1. Define project/folder  Name
read -e -p "> Define project Name: " PROJECTNA
PROJECTNA=${PROJECTNA:-"-1"}
if [ $PROJECTNA == "-1" ] #check if variable is empty
then
	echo "Please define a project Name"
	exit 1;
fi
	mkdir $PROJECTS_DIR/$PROJECTNA
	#1.1 Check if folder exist
	if [ $? -eq 0 ]
	then
	  echo
	  echo "Created project structure for: "$PROJECTNA
	  echo
	else
	  echo "Project name already exists. Won't continue"
	  exit $?
	fi


# 2. Do you whant define a custom theme
read -e -p "> Do you want to define a custom theme? [y/N]: " CUSTOMTHEME 
CUSTOMTHEME=${CUSTOMTHEME:-N}

tmpDir=tmp/buildProjectTmp
# 2.1 By Default Option is N remove themes
if [ $CUSTOMTHEME == "n" ]  || [ $CUSTOMTHEME == "N" ]
then
	cp -r newProjectStructure/* $PROJECTS_DIR/$PROJECTNA
else
	mkdir -p $tmpDir
	cp -r newProjectStructure/* $tmpDir
	cp -r newProjectStructure/_dockerfiles/theme-patches/* $tmpDir/_dockerfiles/patches
	# 2.2 Define Main Color and second Color
	read -e -p "> Define Main Color [#cc0000]:" COLOR1
	COLOR1=${COLOR1:-"#cc0000"}
	read -e -p "> Define Second Color [#7C0B2B]:" COLOR2
	COLOR2=${COLOR2:-"#7C0B2B"}
	
	echo
	echo "Updated project: "$PROJECTNA
	echo  "Main Color: " $COLOR1
	echo  "Second Color: " $COLOR2
	echo  "To change logo image update logo.svg in folder _dockerfiles\logo-image (size recomended 250*65)" 
	echo
	
	
	sed -i.bak "s/\${MAINCOLOR}/$COLOR1/g;s/\${SECONDCOLOR}/$COLOR2/g" $tmpDir/_dockerfiles/patches/pentaho-solutions/system/analyzer/styles/themes/myTheme/anamyTheme.css && \
	sed -i.bak "s/\${MAINCOLOR}/$COLOR1/g;s/\${SECONDCOLOR}/$COLOR2/g" $tmpDir/_dockerfiles/patches/pentaho-solutions/system/common-ui/resources/themes/myTheme/globalmyTheme.css && \
	sed -i.bak "s/\${MAINCOLOR}/$COLOR1/g;s/\${SECONDCOLOR}/$COLOR2/g" $tmpDir/_dockerfiles/patches/tomcat/webapps/pentaho/mantle/themes/myTheme/mantlemyTheme.css
	
	cp -r $tmpDir/* $PROJECTS_DIR/$PROJECTNA
fi

# 3. Clean it

rm -rf $tmpDir

echo 
echo Project folder built successfully
echo

cd $BASEDIR

exit 0
