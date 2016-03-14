#!/bin/bash

BASEDIR=$(dirname $0)
source "$BASEDIR/utils.sh"
cd $BASEDIR


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
SOFTWARE_DIR=software

# Create the dir if doesn't exist
if ! [ -d $SOFTWARE_DIR ]; then
	mkdir $SOFTWARE_DIR
fi


VERSIONS=(6.1-QAT 7.0-QAT)
BOX_URL=${BOX_URL:-ftp.box.com/CI}
SOFTWARE_PATH=ee
PRODUCT=ee


echo
echo Software download utility.
echo Connects to box with user \'$BOX_USER\' and downloads stuff
echo

# Get
OPTIONS=("Nightly Builds" "Stable releases")
promptUser "Which Release do you want to download? " "0"
b=${OPTIONS[$CHOICE]}


if [ $CHOICE -eq 0 ]; then

	# Stable version. Get the list of them
	echo Connecting to box to get the latest nightly builds


elif [ "$CHOICE" -eq 1 ]
then

	echo Connecting to box to get the latest stable versions...

	result=$(lftp -c "open -u $BOX_USER,$BOX_PASSWORD $BOX_URL ; cls -1 --sort=name [0-9]*Releases ");

	OPTIONS=();
	for versionDir in $result
	do
		OPTIONS=("${OPTIONS[@]}" $(echo $versionDir | cut -d- -f1) )
	done;

	promptUser "Stable versions found " "0" "Choose a version" 
	version=${OPTIONS[$CHOICE]}


	# Now for the minor vesions

	echo Connecting to box to get the latest dot versions for $version...
	subVersions=$(lftp -c "open -u $BOX_USER,$BOX_PASSWORD $BOX_URL/$version-Releases/ ; cls -1 --sort=name [0-9]* ");

	minorVersions=$(echo "$subVersions" | egrep -o '^\d+\.\d+\.\d+' | sort -u )

	echo "Minor versions found: $minorVersions"
	read -a OPTIONS <<< $minorVersions
	echo Options size: ${#OPTIONS[@]}

	promptUser "Stable versions found " "0" "Choose a version" 
	minorVersion=${OPTIONS[$CHOICE]}

	echo Minor version: $minorVersion



	OPTIONS=("ee" "ce")
	promptUser "You want EE or CE?" "0"
	variant=${OPTIONS[$CHOICE]}

	if [ "$variant" == "ce" ]; then

		# CE is actually easier; We'll download from $version-Releases/$version-.0.0/ce/baserver
		echo Downloading $minorVersion CE...
		lftp -c "open -u $BOX_USER,$BOX_PASSWORD $BOX_URL/$version-Releases/$minorVersion.0/ce/; mget -O $SOFTWARE_DIR biserver-ce-*zip";

	else
		echo WIP

	fi
	

else 
	echo Somethings wrong, doc...
	exit 1
fi



echo GOOD SO FAR...

cd $BASEDIR
exit 0
