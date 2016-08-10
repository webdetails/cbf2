#!/bin/bash

# Lists the clients and starts / delets
BASEDIR=$(dirname $0)


#VERSIONS=()
VERSIONS=(6.0-NIGHTLY 6.1.0.0)
BOX_URL=${BOX_URL:-ftp.box.com/CI}
DIR=clients
CLIENTS=()
BRANCHES=()
BUILDNOS=()


# Get list of files

DIRS=$(find $DIR -type d -maxdepth 3 -d 3)

echo
echo Clients found:
echo --------------
echo 

n=0;
for i in ${DIRS[@]}; do

	read -a foo <<< $(echo $i | sed 's/\// /g')
	CLIENTS+=(${foo[1]});
	BRANCHES+=(${foo[2]});
	BUILDNOS+=(${foo[3]});

	echo \ [$n] ${CLIENTS[$n]}: ${BRANCHES[$n]}-${BUILDNOS[$n]}
	n=$((n+1))
done

echo

# What ?

read -e -p "Select a client: " clientNo

if [ -z $clientNo ] || [ -z ${CLIENTS[$clientNo]} ]
then
	echo Invalid option: $clientNo
	exit 1
fi

echo 
echo You selected ${CLIENTS[$clientNo]}: ${BRANCHES[$clientNo]}-${BUILDNOS[$clientNo]}

read -e -p "What do you want to do? (L)aunch it or (D)elete it? [L]: " operation
operation=${operation:-L}

if ! [ $operation == "L" ] && ! [ $operation == "D" ]
then
	echo Invalid selection
	exit 1;
fi

# Are we deleting it?

if [ $operation == "D" ]
then
	rm -rf $DIR/${CLIENTS[$clientNo]}/${BRANCHES[$clientNo]}/${BUILDNOS[$clientNo]}
	echo Removed successfully
	exit 0
fi


# Are we launching it?

if [ $operation == "L" ]
then
	cd $DIR/${CLIENTS[$clientNo]}/${BRANCHES[$clientNo]}/${BUILDNOS[$clientNo]}

	# This is the part where we need to be specific...
	# PRODUCTS=(pdi-ee-client pdi-ce prd-ee prd-ce pme-ee pme-ce psw-ee psw-ce pad-ee pad-ce)

	if [ ${CLIENTS[$clientNo]} == "pdi-ee-client" ] || [ ${CLIENTS[$clientNo]} == "pdi-ce" ]
	then
		cd data-integration
		sed -i '' -e 's/^# OPT=/OPT=/' ./spoon.sh
		./spoon.sh

	elif [ ${CLIENTS[$clientNo]} == "prd-ee" ] || [ ${CLIENTS[$clientNo]} == "prd-ce" ]
	then
		cd report-designer
		./report-designer.sh

	elif [ ${CLIENTS[$clientNo]} == "pme-ee" ] || [ ${CLIENTS[$clientNo]} == "pme-ce" ]
	then
		cd metadata-editor
		./metadata-editor.sh

	elif [ ${CLIENTS[$clientNo]} == "psw-ee" ] || [ ${CLIENTS[$clientNo]} == "psw-ce" ]
	then
		cd schema-workbench
		./workbench.sh

	elif [ ${CLIENTS[$clientNo]} == "pad-ee" ] || [ ${CLIENTS[$clientNo]} == "pad-ce" ]
	then
		cd pentaho-aggdesigner-ui
		./startaggregationdesigner.sh

	else
		echo The author was probably lazy enough to not implement what to do with ${CLIENTS[$clientNo]}...
		cd $BASEDIR
		exit 1
	fi

fi


echo done

cd $BASEDIR

exit 0
