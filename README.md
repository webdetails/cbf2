
# Pentaho Docker Utilities

## Purpose

The goal of this project is to quickly spin a working pentaho server on docker
containers. 

Also provides script utilities to get the client tools


## Requirements

* A system with docker. I'm on a mac, so I have docker-machine
* A decent shell; either linux or mac should work, cygwin should as well

For docker, please follow the instructions for your operating system. I use a
mac with homebrew, so I use docker machine (4Gb mem, 40Gb disk, YMMV)

	brew install docker
	brew install docker-machine
	docker-machine create -d virtualbox --virtualbox-memory 4096 --virtualbox-disk-size 2000 env


## How to use

There are a few utilities here: 

 * getBinariesFromBox.sh - Connects to box and builds the main images for the servers
	 (requires access to box. Later I'll do something that doesn't require that)
 * cbf2.sh - What you need to use
 * getClients.sh - An utility to get the clients tools
 * startClient.sh - An utility to start the client tools


Have fun. Tips and suggestions to pedro.alves _at_ webdetails.pt


