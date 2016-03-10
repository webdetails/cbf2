
# Pentaho Docker Utilities

## Purpose

The goal of this project is to quickly spin a working pentaho server on docker
containers. 

Also provides script utilities to get the client tools


## Requirements

* A system with docker. I'm on a mac, so I have docker-machine
* A decent shell; either linux or mac should work, cygwin should as well

## How to use

There are a few utilities here: 

 * listBuilds.sh - Connects to box and builds the main images for the servers
	 (requires access to box. Later I'll do something that doesn't require that)
 * startNightly.sh - Spuns up containers for images that were previously built
 * getClients.sh - An utility to get the clients tools
 * startClient.sh - An utility to start the client tools
 * buildProjectImage.sh - Builds a project on top of an existing image
 * startProjectFromImage.sh - Spuns up a container based on a project image
 * listProjects.sh - Some utilities to handle the project containers


Have fun. Tips and suggestions to pedro.alves _at_ webdetails.pt


