#!/bin/bash

# This thing connects to box, checks the latest builds and downloads the client tools

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
VERSIONS=(8.0-QAT 8.1-QAT)
BOX_URL=${BOX_URL:-ftp.box.com/CI}
DIR=clients


## Print a quick status of current dir
## I uncommented this cause it's mostly useless
# if ! [ -d $DIR ]
# then
#   echo No local client tools found
#   echo
# else
#   echo Latest build found for client tools: $( ls -d $DIR/*/ | cut -f2 -d'/' | sort -n -r | head -n 1 )
# fi

# Stable builds

echo Release available - Branch: 5.4.0.9 , Buind number: 162
echo Release available - Branch: 6.0.1.0 , Buind number: 386
echo Release available - Branch: 7.0.0.0 , Buind number: 25
echo Release available - Branch: 7.1.0.0 , Buind number: 12
echo Release available - Branch: 8.0.0.0 , Buind number: 28


# Get list of files

echo  ... connecting to box to get the nightlies

for i in ${VERSIONS[@]}; do
	
	result=$(lftp -c "open -u $BOX_USER,$BOX_PASSWORD $BOX_URL ; cls -1 --sort date $i | head -n 1");

	BRANCH=$(echo $result | cut -f1 -d/)
	BUILD=$(echo $result | cut -f2 -d/)
	echo Nightly available - Branch: $BRANCH , Build number: $BUILD
done


echo 

# Ask for branch
read -e -p "Which branch to download from? [$BRANCH]: " branch
branch=${branch:-$BRANCH}

# Ask for buildno
read -e -p "Which build number? [$BUILD]: " buildno
buildno=${buildno:-$BUILD}


PRODUCTS=(pdi-ee-client pdi-ce prd-ee prd-ce pme-ee pme-ce psw-ee psw-ce pad-ee pad-ce)

echo Available client tools
echo

i=0
for p in ${PRODUCTS[@]} 
do
  echo [$i]: $p
  ((i++))
done
echo


# Ask for product
read -e -p "Which client tool to download? [0]: " productIdx
product=${PRODUCTS[$productIdx]}

if [ -z $product ]
then
  echo Invalid selection
  exit 1
fi



path="ee"
appender="-dist"
IS_DIST=1

if [[ $product =~ ce  ]]; then
	echo " -- You selected a CE product"
	path="ce"
	appender=""
	IS_DIST=0
fi


tooldir=$DIR/$product/$branch/$buildno/


echo you selected $product. Downloading to $tooldir

if [ -d $tooldir ]
then
  echo Dir already exists. Won\'t download again
  exit 1
else
  mkdir -p $tooldir
fi



# Downloading. We need to take into account the fact that mondrian stuff doesnt respect the same naming pattern
# Also - don't download mac stuff

lftp -c "lcd $tooldir; open -u $BOX_USER,$BOX_PASSWORD $BOX_URL ; \
  cd $branch/$buildno/$path/client-tools; \
  mget $product-[^m]*-$buildno$appender.zip \
  ";



unzip $tooldir/$product-*-$buildno$appender.zip -d $tooldir

if [ $IS_DIST == "1" ]
then
		echo Installing $dir...

		pushd $tooldir > /dev/null
		cd $prod*/

		cat <<EOT > auto-install.xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?> 
<AutomatedInstallation langpack="eng"> 
   <com.pentaho.engops.eula.izpack.PentahoHTMLLicencePanel id="licensepanel"/> 
   <com.izforge.izpack.panels.target.TargetPanel id="targetpanel"> 
      <installpath>../</installpath> 
   </com.izforge.izpack.panels.target.TargetPanel> 
   <com.izforge.izpack.panels.install.InstallPanel id="installpanel"/> 
</AutomatedInstallation>
EOT

    java -jar installer.jar auto-install.xml > /dev/null

		popd > /dev/null

fi

rm -rf $tooldir/$product-*-$buildno*


echo Done. You may want to use the ./startClient.sh command

exit 0
