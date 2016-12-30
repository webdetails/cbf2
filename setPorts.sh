#!/bin/bash

# Mapping ports
PORTS=( "httpPort:8080"
        "httpsPort:8443"
        "ajp13Port:8009"
        "pgPort:5432"
        "debugPort:8044"
        "disPort:9001"
      )
      
NAMES=()
DEFAULTS=()
USED=()
        
n=-1        
for port in "${PORTS[@]}" ; do

    ((n++))
    
    portName=${port%%:*}
    portValue=${port#*:}
    
    if [ "$portName" == "debugPort" ]
    then
        read $portName <<<$portValue
    else

        NAMES[$n]=$portName
        DEFAULTS[$n]=$portValue

        # Check if the port is already been used
        #opened=$(lsof -i :$portValue)
        opened=$(netstat -na | grep -i -E "^tcp.*[\.|:]$portValue\s+")

        # If the port is used, look for the next one free
        while ! [ -z "$opened" ]; do

            ((portValue++))
            #opened=$(lsof -i :$portValue)
            opened=$(netstat -na | grep -i -E "^tcp.*[\.|:]$portValue\s+")

        done

        USED[$n]=$portValue

    fi
    
done

exposePorts=""
for index in ${!NAMES[*]}
do
    exposePorts+=" -p ${USED[$index]}:${DEFAULTS[$index]}"
done

#echo $exposePorts
#echo $debugPort
