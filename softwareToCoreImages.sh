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

echo "Server chosen: $server ($serverChoiceIdx); File: $serverFile; Docker tag: $DOCKERTAG"

getTimeZone
echo "Timezone set to use: " ${TZ_HOST}


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

	echo Base image not found. Building cbf2-core...
	docker build -t cbf2-core --build-arg TZ_PARAM=${TZ_HOST} -f dockerfiles/Dockerfile-CoreCBF dockerfiles

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

	# 1 - Unzip everything
	echo Unzipping files...
	for file in $( dirname $serverFile )/[^S]*ee*.zip
	do 
		unzip $file -d $tmpDirInstallers > /dev/null
	done

	# 2 - EULA
	if [ -f $tmpDirInstallers/*server*/license.txt ]; then
		less $tmpDirInstallers/*server*/license.txt
	
		read -e -p "> Select 'Y' to accept the terms of the license agreement: " choice

		choice=$( tr '[:lower:]' '[:upper:]' <<< "$choice" )

		# Did the user accept it?
		if ! [ $choice == "Y" ]; then
			echo "Sorry, can't  continue without accepting the license agreement. Bye"
			exit 1
		fi
	else
		echo "The normal EULA was not found (pentaho-server/license.txt)."
		echo "Assuming a custom, patched Enterprise Edition implying accepted EULA."
		echo ""
		echo "Moving foward with image creation."
    fi

	# 3 - Call the installers
	# Pentaho Installer or Archive source fils folder (cbf2/dockerfiles/tmp/installers)
	tmpDirInstallers=$tmpDir/installers
	# Destination folder expected by the docker image and run scripts down the line.
	mkdir $tmpDir/pentaho

	# Customers outside of Hitachi have to run the installers and patch up
	# the server by themselves.  This means that a customer would have zipped a folder
	# structure that looks like this:
	# .
    # ├── jdbc-distribution
    # ├── license-installer
    # ├── pentaho_eula.txt
    # └── pentaho-server
	#
	# Inside that folder they would have run a zip command as follows
	# $ zip -r ../baserver-ee-8.2.0.6-dist.zip .
	#
	# That zip file would be in cbf2/software/8.2.0 and step #1 above would
	# yield contents in the cbf2/dockerfiles/tmp/installers folder:
	# .
    # ├── jdbc-distribution
    # ├── license-installer
    # ├── pentaho_eula.txt
    # └── pentaho-server
	#
    # We will test for the existence of the 3 folders and 1 file and move them
	# to dockerfiles/tmp/pentaho, which in turn makes it into the docker image
	# the cbf scripts expect to find.
    if [ -d "$tmpDirInstallers/jdbc-distribution" ]; then
		echo "Moving $tmpDirInstallers/jdbc-distribution -> $tmpDir/pentaho" 
		mv $tmpDirInstallers/jdbc-distribution $tmpDir/pentaho
	fi

    if [ -d "$tmpDirInstallers/pentaho-server" ]; then
		echo "Moving $tmpDirInstallers/pentaho-server -> $tmpDir/pentaho" 
		mv $tmpDirInstallers/pentaho-server $tmpDir/pentaho
	fi

    if [ -d "$tmpDirInstallers/license-installer" ]; then
		echo "Moving $tmpDirInstallers/license-installer -> $tmpDir/pentaho" 
		mv $tmpDirInstallers/license-installer $tmpDir/pentaho
	fi

	# If a pentaho-server folder was found above, there is no need to run any
	# installers or do patching, so we can skip to the copying of licenses and
	# create the docker image.

	if [ ! -d $tmpDir/pentaho/pentaho-server ]; then 
		# First, the server. Then the plugins. There's surely a smarter way to do this...
		# I guess I'm just not smart enough

		for dir in $tmpDirInstallers/*server*/
		do
			
			targetDir="../../pentaho"
			if [[ $dir =~ plugin ]]; then
				targetDir="../../pentaho/pentaho-server/pentaho-solutions/system"
			fi

			echo Installing $dir...

		pushd $dir > /dev/null

		cat <<EOT > auto-install.xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?> 
<AutomatedInstallation langpack="eng"> 
   <com.pentaho.engops.eula.izpack.PentahoHTMLLicensePanel id="licensepanel"/> 
   <com.izforge.izpack.panels.target.TargetPanel id="targetpanel"> 
      <installpath>$targetDir</installpath> 
   </com.izforge.izpack.panels.target.TargetPanel> 
   <com.izforge.izpack.panels.install.InstallPanel id="installpanel"/> 
</AutomatedInstallation>
EOT

		java -jar installer.jar auto-install.xml > /dev/null

			popd > /dev/null

		done

		for dir in $tmpDirInstallers/*plugin*/
		do
			pushd $dir > /dev/null

			targetDir="../../pentaho"
			if [[ $dir =~ plugin ]]; then
				targetDir="../../pentaho/pentaho-server/pentaho-solutions/system"
			fi

			echo Installing $dir...

		cat <<EOT > auto-install.xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?> 
<AutomatedInstallation langpack="eng"> 
   <com.pentaho.engops.eula.izpack.PentahoHTMLLicensePanel id="licensepanel"/> 
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
		# Since at least mid 2018 patches are comprehesive and there is no
		# requirement to unzip, delete existing jars and carefully copy the patch files
		# to the correct destination.
		#
		# I will test for .bin files with the
#		for file in $( dirname $serverFile )/[^S]*SP*.bin
#		do 
#			if [[ ! -x $file ]]; then
#				echo "Making $file executable."
#				chmod +x $file
#			fi
#			echo "Installing $file"
#			targetDir="../../pentaho/pentaho-server"
			
#			cat <<EOT > auto-install.xml
#<?xml version="1.0" encoding="UTF-8" standalone="no"?> 
#<AutomatedInstallation langpack="eng"> 
#   <com.pentaho.engops.eula.izpack.PentahoHTMLLicencePanel id="licensepanel"/> 
#   <com.izforge.izpack.panels.target.TargetPanel id="targetpanel"> 
#      <installpath>$targetDir</installpath> 
#   </com.izforge.izpack.panels.target.TargetPanel> 
#   <com.izforge.izpack.panels.install.InstallPanel id="installpanel"/> 
#</AutomatedInstallation>
#EOT
#			java -jar installer.jar auto-install.xml > /dev/null

#			popd > /dev/null

#		done
		#read -n 1 -s -r -p "Press any key to continue"

#
#		As of version 9.1 a newer updater was implemented.  In order to support the new installer
#		a new block of of code is added to keep backwards compatibility and support the new installer.
#

#		Analyze the server version being processed.
		major_version=`echo $server | awk -F- '{print $4}' | cut -d '.' -f 1`
		minor_version=`echo $server | awk -F- '{print $4}' | cut -d '.' -f 2`
		
		if ([[ $major_version -ge 9 ]] && [[ $minor_version -ge 1 ]]) || ([[ $major_version -eq 8 ]] && [[ $minor_version -ge 3 ]])  
		then
			echo "Processing with the newer 9.1 updater style."
			# 1) Find the most up-to-date update file.
			# 2) Unzip into tmp/updater tmp directory.
			# 3) Process the updater from the updater directory.
			
			tmpDirUpdater=$tmpDir/updater
			mkdir $tmpDirUpdater

			# Get the most recent update file that exists.  You only need the most recent.
			UPDATER_ZIPFILE=`ls $(dirname $serverFile)/pentaho-update*.zip 2>/dev/null | sort -r | head -1`
			
			if [ ! -z ${UPDATER_ZIPFILE} ] && [ -f ${UPDATER_ZIPFILE} ]
			then
				echo "Using Updater zipfile: " ${UPDATER_ZIPFILE}
				echo "unzipping updater file: "
				unzip ${UPDATER_ZIPFILE} -d $tmpDirUpdater

				if [ -f $tmpDirUpdater/pentaho-update*.bin ]
				then
					INSTALLED_DIR=`pwd`'/'${tmpDir}'/pentaho/' 
					
					pushd $tmpDirUpdater
					#
					# I would have used a relative location (../pentaho) for the install dir
					# but the installer was wonky.  So I simply used a fully qualified directory.
					# no big deal.
					#
					echo "Processing updater file: pentaho-update*.bin -i silent -DEULA=true -DUSER_INSTALL_DIR=${INSTALLED_DIR}"
					./pentaho-update*.bin -i silent -DEULA=true -DUSER_INSTALL_DIR=${INSTALLED_DIR} 
					echo "Finished processing updater file: "  ${UPDATER_FILE}
					popd
				fi 
				if [ -d ~/.pentaho/backups ]
				then
					echo "Removing backup files from host build machine."
					rm -rf ~/.pentaho/backups
				fi
				
				# Added to clean up temporary updater directory
				if [ -d $tmpDirUpdater ]; then
					echo "Removing updater files before creating docker container."
					rm -rf $tmpDirUpdater
				fi
			fi
		else 

			tmpDirPatches=$tmpDir/patches
			mkdir $tmpDirPatches

			echo Unzipping patches if they exist...
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

				rm $( echo ../../pentaho/*server*/$jar | sed -E -e 's/(.*\/[^\]*-)[0-9]*.jar/\1/' )* 2>/dev/null

			done

			# and copy them...
			cp -R * ../../pentaho/*server*/ > /dev/null 2>&1
			popd
		fi	#Ends the code block for patching method (either: version 9.1+ or prior)
	fi # Ends the running of installers and Patching section of code.
	
	if [ -d $tmpDir/installers ]; then
		echo "Removing installer files before creating docker container."
	     rm -rf $tmpDir/installers
	fi

    #read -n 1 -s -r -p "Press any key to continue"
	echo "Copying licenses to $tmpDir"
	cp -R licenses $tmpDir

	echo "Creating docker image using dockerfiles/Dockerfile-EE-FromFile"
	docker build --build-arg CURRENT_HOST_UID=$(id -u) --build-arg CURRENT_HOST_GID=$(id -g) -t $DOCKERTAG -f dockerfiles/Dockerfile-EE-FromFile dockerfiles

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
