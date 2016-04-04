
# CBF2 - Community Build Framework 2.0

It's not community only; You don't actually build anything; But still rocks!


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

 * getBinariesFromBox.sh - Connects to box and builds the main images for the
	 servers (requires access to box. Later I'll do something that doesn't require
	 that)
 * cbf2.sh - What you need to use
 * getClients.sh - An utility to get the clients tools
 * startClient.sh - An utility to start the client tools


## The _software_ directory

This is the main starting point. If you're a pentaho employee you will have
access to using the _getBinariesFromBox.sh_ script, but all the rest of the
world can still use this.

You should put the official software files under the
software/v.v.v directory. It's important to follow this 3 number thingy

This works for both _CE_ and _EE_. This actually works _better_ for EE, since
you can also put the patches there and they will be processed.

For EE, you should use the official _-dist.zip_ artifacts. For CE, the normal
_.zip_ file.


### Released versions:

X.X.X, and inside drop the server, plugins and patches

### Nightly Builds

Have the build directly in that directory


Example:

	software/
	├── 5.2.1
	│   ├── SP201502-5.2.zip
	│   ├── biserver-ee-5.2.1.0-148-dist.zip
	│   ├── paz-plugin-ee-5.2.1.0-148-dist.zip
	│   ├── pdd-plugin-ee-5.2.1.0-148-dist.zip
	│   └── pir-plugin-ee-5.2.1.0-148-dist.zip
	├── 5.4.0
	│   └── biserver-ce-5.4.0.0-128.zip
	├── 5.4.1
	│   ├── SP201603-5.4.zip
	│   └── biserver-ee-5.4.1.0-169-dist.zip
	├── 6.0.1
	│   ├── SP201601-6.0.zip
	│   ├── SP201602-6.0.zip
	│   ├── SP201603-6.0.zip
	│   ├── biserver-ce-6.0.1.0-386.zip
	│   ├── biserver-ee-6.0.1.0-386-dist.zip
	│   ├── paz-plugin-ee-6.0.1.0-386-dist.zip
	│   ├── pdd-plugin-ee-6.0.1.0-386-dist.zip
	│   └── pir-plugin-ee-6.0.1.0-386-dist.zip
	├── 6.1-QAT-153
	│   ├── biserver-ee-6.1-qat-153-dist.zip
	│   ├── biserver-merged-ce-6.1-qat-153.zip
	│   ├── paz-plugin-ee-6.1-qat-153-dist.zip
	│   ├── pdd-plugin-ee-6.1-qat-153-dist.zip
	│   └── pir-plugin-ee-6.1-qat-153-dist.zip
	├── 7.0-QAT-76
	│   ├── biserver-merged-ee-7.0-QAT-76-dist.zip
	│   ├── pdd-plugin-ee-7.0-QAT-76-dist.zip
	│   └── pir-plugin-ee-7.0-QAT-76-dist.zip
	└── README.txt



## CBF2: The main thing

CBF1 was an ant script; CBF2 is a bash script. So yeah, you want cbf2.sh. If
you are on windows... well, not sure I actually care, but you should be able to
just use cygwin. 

Here's what you'll see when you run _./cbf2.sh_:

	--------------------------------------------------------------
	--------------------------------------------------------------
	------       CBF2 - Community Build Framework 2        -------
	------                 Version: 0.9                    -------
	------ Author: Pedro Alves (pedro.alves@webdetails.pt) -------
	--------------------------------------------------------------
	--------------------------------------------------------------

	Core Images available:
	----------------------

	 [0] baserver-ee-5.4.1.0-169
	 [1] baserver-ee-6.0.1.0-386
	 [2] baserver-merged-ce-6.1-qat-153
	 [3] baserver-merged-ee-6.1.0.0-192

	Core containers available:
	--------------------------

	 [4] (Stopped): baserver-ee-5.4.1.0-169-debug

	Project images available:
	-------------------------

	 [5] pdu-project-nasa-samples-baserver-ee-5.4.1.0-169
	 [6] pdu-project-nasa-samples-baserver-merged-ee-6.1.0.0-192

	Project containers available:
	-----------------------------

	 [7] (Running): pdu-project-nasa-samples-baserver-ee-5.4.1.0-169-debug
	 [8] (Stopped): pdu-project-nasa-samples-baserver-merged-ee-6.1.0.0-192-debug

	> Select an entry number, [A] to add new image or [C] to create new project:


There are 4 main concepts here:

* Core images
* Core containers
* Project images
* Project containers

These should be straightforward to understand if you're familiar with
[docker](http://docker.com)


### Core images

### Core containers

### Project images

### Project containers




Have fun. Tips and suggestions to pedro.alves _at_ webdetails.pt


