#!/bin/bash

BASEDIR=$(dirname $0)
source "$BASEDIR/utils.sh"
cd $BASEDIR


#
# These are the variables that need to be set
#

#BOX_USER=pedro.alves@pentaho.com
#BOX_PASSWORD=XXXXXX

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
LICENSES_DIR=licenses

# Create the dirs if they don't exist
if ! [ -d $SOFTWARE_DIR ]; then
	mkdir $SOFTWARE_DIR
fi
if ! [ -d $LICENSES_DIR ]; then
	mkdir $LICENSES_DIR
fi


VERSIONS=(6.1-QAT 7.0-QAT)
BOX_URL=${BOX_URL:-ftp.box.com/CI}
SOFTWARE_PATH=ee
VARIANT=ee


echo
echo Software download utility.
echo Connects to box with user \'$BOX_USER\' and downloads stuff
echo

# Get
OPTIONS=("Nightly Builds" "Stable releases")
promptUser "Which Release do you want to download? " "0"
b=${OPTIONS[$CHOICE]}


if [ $CHOICE -eq 0 ]; then

	# Nightly builds. Get the list of them
	echo Connecting to box to get the latest nightly builds...

	result=$(lftp -c "open -u $BOX_USER,$BOX_PASSWORD $BOX_URL ;cls -1  * | grep -e '^[0-9].*' |  grep -v \"Releases\" | grep -v \"NIGHTLY\" | grep -v \"SNAPSHOT\"" );

	OPTIONS=();
	for versionDir in $result
	do
		OPTIONS=("${OPTIONS[@]}" $(echo $versionDir | cut -d/ -f1) )
	done;

	promptUser "Nightly versions found " $(( ${#OPTIONS[@]} - 1 )) "Choose a version" 
	version=${OPTIONS[$CHOICE]}

	# Getting the latest build number

	result=$(lftp -c "open -u $BOX_USER,$BOX_PASSWORD $BOX_URL ; cls -1 --sort date $version | head -n 1");
	BUILD=$(echo $result | cut -f2 -d/)


	# Ask for buildno
	read -e -p "Latest build is $BUILD. Which one do you want to download? [$BUILD]: " buildno
	buildno=${buildno:-$BUILD}

	# Ask for product
	read -e -p "Which server ('ee', 'merged-ee', 'ce' or 'merged-ce')? [$VARIANT]: " variant
	variant=${variant:-$VARIANT}

	DOWNLOAD_DIR=$SOFTWARE_DIR/$version-$buildno
	mkdir -p $DOWNLOAD_DIR

	if [[ $variant =~ ce  ]]; then

		echo Downloading $version-$buildno $variant...
		lftp -c "open -u $BOX_USER,$BOX_PASSWORD $BOX_URL/$version/$buildno/; mget -O $DOWNLOAD_DIR biserver-$variant-*-$buildno.zip";

	else

		# EE - download the bundles (ba and plugins)
		echo Downloading $version-$buildno $variant and plugins...

		lftp -c "open -u $BOX_USER,$BOX_PASSWORD $BOX_URL/$version/$buildno/; mget -O $DOWNLOAD_DIR biserver-$variant-*-$buildno-dist.zip \
			paz-plugin-ee-*-dist.zip \
			pir-plugin-ee-*-dist.zip \
			pdd-plugin-ee-*-dist.zip"

	fi


elif [ "$CHOICE" -eq 1 ]
then

	echo Connecting to box to get the latest stable versions...

	result=$(lftp -c "open -u $BOX_USER,$BOX_PASSWORD $BOX_URL ; cls -1 --sort=name [5-9]*Releases ");

	OPTIONS=();
	for versionDir in $result
	do
		OPTIONS=("${OPTIONS[@]}" $(echo $versionDir | cut -d- -f1) )
	done;

	promptUser "Stable versions found " $(( ${#OPTIONS[@]} - 1 )) "Choose a version" 
	version=${OPTIONS[$CHOICE]}


	# Now for the minor vesions

	echo Connecting to box to get the latest dot versions for $version...
	subVersions=$(lftp -c "open -u $BOX_USER,$BOX_PASSWORD $BOX_URL/$version-Releases/ ; cls -1 --sort=name '[0-9S]*' " | grep -v '\-C');

	minorVersions=$(echo "$subVersions" | egrep -o '^[0-9]+\.[0-9]+\.[0-9]+' | sort -u )

	echo "Minor versions found: $minorVersions"
	read -a OPTIONS <<< $minorVersions
	echo Options size: ${#OPTIONS[@]}

	promptUser "Minor versions found for $version " $(( ${#OPTIONS[@]} - 1 )) "Choose a version" 
	minorVersion=${OPTIONS[$CHOICE]}

	echo Minor version: $minorVersion
	DOWNLOAD_DIR=$SOFTWARE_DIR/$minorVersion
	mkdir -p $DOWNLOAD_DIR

	OPTIONS=("ee" "ce" "merged-ce" "merged-ee")
	promptUser "You want EE or CE?" "0"
	variant=${OPTIONS[$CHOICE]}


	# Caveat - In 6.1 (at least?) the stable version is actually 6.1.0.1, and not
	# 6.1.1.0.... Yay for coherency...
	dotDotVersion=0;

	if [ "$minorVersion" == "6.1.0" ]; then
		dotDotVersion=1;
	fi
	echo  Sable release is $minorVersion.$dotDotVersion

	if [[ $variant =~ ce ]]; then

		# CE is actually easier; We'll download from $version-Releases/$version-.$minorVersion.0/ce/baserver
		echo Downloading $minorVersion CE...
		lftp -c "open -u $BOX_USER,$BOX_PASSWORD $BOX_URL/$version-Releases/$minorVersion.$dotDotVersion/; mget -O $DOWNLOAD_DIR biserver-$variant-*zip ce/biserver-$variant-*zip"; 2>/dev/null

	else

		# EE - download the bundles (ba and plugin), and then the patches
		echo " Downloading $minorVersion EE and plugins..."
		lftp -c "open -u $BOX_USER,$BOX_PASSWORD $BOX_URL/$version-Releases/$minorVersion.$dotDotVersion/; mget -O $DOWNLOAD_DIR biserver-[^m]*zip ee/biserver-[^m]*zip \
			paz-plugin-ee-*.zip ee/paz-plugin-ee-*.zip \
			pir-plugin-ee-*.zip ee/pir-plugin-ee-*.zip \
			pdd-plugin-ee-*.zip ee/pdd-plugin-ee-*.zip" 2>/dev/null

		## Find dot versions that are relevant
		for subV in $subVersions
		do
			# echo subversion: $subV
			if [[ $subV =~ $minorVersion\.[^0][0-9.-]*/$ ]]; then
				echo " Downloading $subV patches..."

				# There are 2 possible formats - right on the dir and on a patches subdir
				lftp -c "open -u $BOX_USER,$BOX_PASSWORD $BOX_URL/$version-Releases/$subV/; mget -O $DOWNLOAD_DIR SP*zip patch/SP*zip" 2>/dev/null

			fi
		done

		# Older releases have the patches on the top level dir
		lftp -c "open -u $BOX_USER,$BOX_PASSWORD $BOX_URL/$version-Releases/; mget -O $DOWNLOAD_DIR SP*zip patch/SP*zip" 2>/dev/null


	fi


	# If EE... also get licenses

	if [[ $variant =~ ee  ]]; then
		rm $LICENSES_DIR/*lic
		lftp -c "open -u $BOX_USER,$BOX_PASSWORD $BOX_URL/DEV_LICENSES/; mget -O $LICENSES_DIR *lic";

	fi


else 
	echo Somethings wrong, doc...
	exit 1
fi



echo Done! You can now launch CBF2

cd $BASEDIR
exit 0
