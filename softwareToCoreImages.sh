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

SERVERFILES=$( ls -1 $SOFTWARE_DIR/*/*server* )

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
DOCKERTAG=$(echo $server | sed -E -e ' s/pentaho-/ba/; s/biserver/baserver/; s/(-dist)?\.zip//' | tr '[:upper:]' '[:lower:]')

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

	# 1 - Unzip everything
	# 2 - Present eula
	# 3 - Call the installers
	# 4 - Process the patches
	# 5 - Copy the relevant stuff to Pentaho dir
	# 6 - Copy licenses
	# 7 - Call docker file

	tmpDirInstallers=$tmpDir/installers
	mkdir $tmpDirInstallers 

	
	echo Unzipping files...
	for file in $( dirname $serverFile )/[^S]*ee*.zip
	do 
		unzip $file -d $tmpDirInstallers > /dev/null
	done

	# EULA
	less $tmpDirInstallers/*server*/license.txt
	echo
	read -e -p "> Select 'Y' to accept the terms of the license agreement: " choice

	choice=$( tr '[:lower:]' '[:upper:]' <<< "$choice" )

	# Did the user accept it?
	if ! [ $choice == "Y" ]; then
		echo "Sorry, can't  continue without accepting the license agreement. Bye"
		exit 1
	fi

	# 3 - Call the installers

	tmpDirInstallers=$tmpDir/installers

	mkdir $tmpDir/pentaho

	for dir in $tmpDirInstallers/*/
	do
		
		targetDir="../../pentaho"
		if [[ $dir =~ plugin ]]; then
			targetDir="../../pentaho/biserver-ee/pentaho-solutions/system"
		fi

		echo Installing $dir...

		pushd $dir > /dev/null

		cat <<EOT > auto-install.xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?> 
<AutomatedInstallation langpack="eng"> 
   <com.pentaho.engops.eula.izpack.PentahoHTMLLicencePanel id="licensepanel"/> 
   <com.izforge.izpack.panels.target.TargetPanel id="targetpanel"> 
      <installpath>$targetDir</installpath> 
   </com.izforge.izpack.panels.target.TargetPanel> 
   <com.izforge.izpack.panels.install.InstallPanel id="installpanel"/> 
</AutomatedInstallation>
EOT

    java -jar installer.jar auto-install.xml > /dev/null

		popd > /dev/null

	done

	# 4 - Patches

	tmpDirPatches=$tmpDir/patches
	mkdir $tmpDirPatches

	echo Unzipping patches...
	tmpDirPentahoPatches=$tmpDirPatches/pentahoPatches
	mkdir $tmpDirPentahoPatches

	for file in $( dirname $serverFile )/[S]*zip
	do 
		if [ -f $file ]; then
			unzip $file -d $tmpDirPatches > /dev/null
		fi
	done

	# We're only interested in by server patches...
	for patch in $tmpDirPatches/BIServer/*zip $tmpDirPatches/*/BIServer/*zip
	do
		if [ -f $patch ]; then
			echo Processing $patch
			unzip -o $patch -d $tmpDirPentahoPatches > /dev/null
		fi
	done

	# Now we need to find all jars that are on the pentaho dir with the same name,
	# delete them (old patches required this...) and copy all the stuff over

	pushd $tmpDirPentahoPatches
	find . -iname \*jar | while read jar
	do

		rm $( echo ../../pentaho/biserver-ee/$jar | sed -E -e 's/(.*\/[^\]*-)[0-9]*.jar/\1/' )* 2>/dev/null

	done

	# and copy them...
	cp -R * ../../pentaho/biserver-ee/ > /dev/null 2>&1
	popd

	echo Copying licenses...
	cp -R licenses $tmpDir

	echo Creating docker image...
	docker build -t $DOCKERTAG -f dockerfiles/Dockerfile-EE-FromFile dockerfiles

fi


if [ $? -ne 0 ] 
then
	echo
	echo An error occurred...
	exit 1
fi


rm -rf $tmpDir
echo Done. You may want to use the ./cbf2.sh command

cd $BASEDIR
exit 0


