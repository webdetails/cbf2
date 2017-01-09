
# CBF2 - Community Build Framework 2.0

It's not community only; You don't actually build anything; But still rocks!


## Purpose

The goal of this project is to quickly spin a working Pentaho server on docker
containers. This will also provide script utilities to get the client tools.


## Requirements

* A system with docker
* A decent shell; either Minux or Mac should work out of the box, Cygwin should
	as well
* lftp

For docker, please follow the instructions for your specific operating system.
[Docker](http://docker.com) has clients for the main operating systems.

## How to use

There are a few utilities here: 

 * getBinariesFromBox.sh - Connects to box and builds the main images for the
	 servers (requires access to box. Later I'll do something that doesn't require
	 that)
 * cbf2.sh - What you need to use to build the images
 * getClients.sh - A utility to get the clients tools
 * startClient.sh - A utility to start the client tools


## The _software_ directory

This is the main starting point. If you're a pentaho employee you will have
access to using the _getBinariesFromBox.sh_ script, but all the rest of the
world can still use this by manually putting the files here.

You should put the official software files under the software/v.v.v directory.
It's very important that you follow this 3 number representation

This works for both _CE_ and _EE_. This actually works _better_ for EE, since
you can also put the patches there and they will be processed.

For EE, you should use the official _-dist.zip_ artifacts. For CE, use the
normal _.zip_ file.

## The _licenses_ directory

For EE, just place the _*.lic_ license files on the licenses subdirectory.
They will be installed on the images for EE builds.

### Released versions:

X.X.X, and inside drop the server, plugins and patches

### Nightly Builds

Drop the build artifacts directly in that directory


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

CBF1 was an ant script but CBF2 is a bash script. So yeah, you want cbf2.sh. If
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
[docker](http://docker.com), but in a nutshell there are two fundamental
concepts: _images_ and _containers_. An image is an inert, immutable file; The
container is an instance of an image, and it's a container that will run and
allow us to access the Pentaho platform


## Accessing the platform

When we run the container, it exposes a few ports, most importantly 8080. So in
order to see Pentaho running all we need to do is to access the machine where
docker is running. This part may vary depending on the operating system; On a
Mac, and using docker-machine, there's a separate VM running the things, so I'm
able to access the platform by using the following URL:

	http://192.168.99.100:8080/pentaho/Home


### Core images

These are the core images - a clean install out of one of the available
artifacts that are provided on the _software_ directory. So the first thing we
should do is add a core image. The option _[A]_ allows us to select which image
to add from an official distribution archive.

When we select this option, we are prompted to choose the version we want to
build: 

	> Select an entry number, [A] to add new image or [C] to create new project: A

	Servers found on the software dir:
	 [0]: biserver-ee-5.2.1.0-148-dist.zip
	 [1]: biserver-ce-5.4.0.0-128.zip
	 [2]: biserver-ee-5.4.1.0-169-dist.zip
	 [3]: biserver-ce-6.0.1.0-386.zip
	 [4]: biserver-ee-6.0.1.0-386-dist.zip
	 [5]: biserver-ee-6.1-qat-153-dist.zip
	 [6]: biserver-merged-ce-6.1-qat-153.zip
	 [7]: biserver-merged-ee-7.0-QAT-76-dist.zip

CBF2 will correctly know how to handle EE dist files, you'll be presented with
the EULA, patches will be automatically processed and licenses will be
installed.

Once an image is built, if we select that core image number you'll have the
option to launch a new container or delete the image:

	> Select an entry number, [A] to add new image or [C] to create new project: 0
	You selected the image baserver-ee-6.0.1.0-386
	> What do you want to do? (L)aunch a new container or (D)elete the image? [L]:


### Core containers

You can launch a container from a core image. This will allow us to explore a
completely clean version of the image you selected. This is useful for some
tests, but I'd say the big value would come out of the project images. Here are
the options available over containers:

	> Select an entry number, [A] to add new image or [C] to create new project: 3

	You selected the container baserver-merged-ce-6.1-qat-153-debug
	The container is running; Possible operations:

	 S: Stop it
	 R: Restart it
	 A: Attach to it
	 L: See the Logs

	What do you want to do? [A]:


Briefly, here are the options mean - even though they should be relatively
straightforward:

* _Stop it_: Stops the container. When the container is stopped you'll be able
	to delete the container or start it again
* _Restart it_: Guess what? It restarts it. Surprising, hein? :)
* _Attach to it_: Attaches to the docker container. You'll then have a bash
	shell and you'll be able to play with the server
* _See the Logs_: Gets the logs from the server


## Custom definitions

### Mapping ports

CBF2 allows you to run multiple containers at the same time. If some exposed port is already in use in the host by some service, CBF2 will look for a new free port and use it.

To include, change and/or delete exposed ports do the following:

* Edit the setPorts.sh file
* Do the proper changes in the PORTS list, at the top. Each line represents a port to be exposed, composed by a unique name and the default port used by the service inside the container.


### Mounting docker volumes

CBF2 allows you to mount Docker volumes as well.

To configure new Docker volumes, do the following:

* Create in the host the folder(s) to be mounted inside the container
* Create/edit the file dockerVolumes.sh in the cbf2/projects/<projectName>/config folder
* Define in the dockerVolumes.sh file the volumes to be mounted

Use the following sample to mount 2 folder:

	#!/bin/bash
	
	# Docker volumes mapping
	# "host_folder:container_folder"
	VOLUMES=(
		"/tmp/volumes/folder1:/folder1"
		"/tmp/volumes/folder2:/folder2"
	)


_NOTE_: To deal with permission folder issues, read the Docker manual. 


## Projects

### Definition and structure

A project is built on top of a core image. Instead of being a clean install
it's meant to replicate a real project's environment. As a best practice, it
should also have a well defined structure that can be stored on a VCS
repository.

Projects should be cloned / checked out in to the _projects_ directory. I recommend
every project to be versioned in a different _git_ or _svn_ repository. Here's
the structure that I have:

	pedro@orion:~/tex/pentaho/cbf2 (master *) $ tree  -l ./projects/
	./projects/
	└── project-nasa-samples -> ../../project-nasa-samples/
			├── _dockerfiles
			└── solution
					└── public
							├── Mars_Photo_Project
							│   ├── Mars_Photo_Project.cda
							│   ├── Mars_Photo_Project.cdfde
							│   ├── Mars_Photo_Project.wcdf
							│   ├── css
							│   │   └── styles.css
							│   ├── img
							│   │   └── nasaicon.png
							│   └── js
							│       └── functions.js
							├── exportManifest.xml
							└── ktr
									├── NASA\ API\ KEY.txt
									├── curiosity.ktr
									├── getPages.ktr
									└── mars.ktr

All the solution files are going to be automatically imported, including
metadata for datasources creation.

The directory \_dockerfiles is a special one; You can override the default
Dockerfile that's used to build a project image (the file in
_dockerfiles/buildProject/Dockerfile_) and just drop a project specific
_Dockerfile_ in that directory using the former one as an example. Note that you
should _not_ change the _FROM_ line, as it will be dynamically replaced. This is
what you want for project level configurations, like installing / restoring a
specific database, an apache server on front or any fine tuned configurations.


### Project images

The first thing that we need to do is to create a project. To do that is very
simple: we select one of the projects on our _projects_ directory and a core
image to install it against. This separations aims at really simplifying
upgrades / tests / etc


	> Select an entry number, [A] to add new image or [C] to create new project: C

	Choose a project to build an image for:

	 [0] project-nasa-samples

	> Choose project: 0

	Select the image to use for the project

	 [0] baserver-ee-6.0.1.0-386
	 [1] baserver-merged-ce-6.1-qat-153
	 [2] baserver-merged-ee-6.1.0.0-192

	> Choose image: 2


Once we have the project image created, we have access to the same options we
had for the core images, which is basically launching a container or deleting
the image.


### Project containers

Like the images, project containers work very similarly to core containers. But
we'll also have two extra options available:

* _Export the solution_: Exports the solution to our project folder
* _Import the solution_: Imports the solution from our project folder into the
	running containers. This would be equivalent to rebuilding the image

Note that by design CBF2 only exports the folders in public that are already
part of the project. You'll need to manually create the directory if you add a
top level one.


## The client tools

This also provides two utilities to handle the client tools; One of them, the
_getClients.sh_, is probably something you can't use since it's for internal
pentaho people only. 

The other one, _startClients.sh_, may be more useful; It requires the client
tools to be downloaded into a dir called _clients/_ with a certain structure:

	pedro@orion:~/tex/pentaho/cbf2 (master *) $ tree -L 4 clients/
	clients/
	├── pad-ce
	│   └── 6.1.0.0
	├── pdi-ce
	│   ├── 6.1-QAT
	│   │   └── 156
	│   │       └── data-integration
	│   ├── 6.1.0.0
	│   │   └── 192
	│   │       └── data-integration
	│   └── 7.0-QAT
	│       └── 57
	│           └── data-integration
	├── pdi-ee-client
	│   └── 6.1.0.0
	│       └── 192
	│           ├── data-integration
	│           ├── jdbc-distribution
	│           └── license-installer
	├── pme-ce
	│   └── 6.1.0.0
	│       └── 182
	│           └── metadata-editor
	├── prd-ce
	│   └── 6.1.0.0
	│       └── 182
	│           └── report-designer
	└── psw-ce
			└── 6.1.0.0

If you use this, then the _startClients.sh_ simplifies launching them; Note
that, unlike the platform, this will run on the local machine, not on a docker
VM:

pedro@orion:~/tex/pentaho/cbf2 (master *) $ ./startClients.sh

	Clients found:
	--------------

	 [0] pdi-ce: 6.1-QAT-156
	 [1] pdi-ce: 6.1.0.0-192
	 [2] pdi-ce: 7.0-QAT-57
	 [3] pdi-ee-client: 6.1.0.0-192
	 [4] pme-ce: 6.1.0.0-182
	 [5] prd-ce: 6.1.0.0-182

	Select a client:




## Taking it further

This is, first and foremost, a developer's tool and methodology. I'll make no
considerations or recommendations in regards to using these containers in a
production environment or not because I have simply no idea how that works as
we're mostly agnostic on those methods.

Pentaho's stance is clearly explained
[here](https://support.pentaho.com/hc/en-us/articles/210384343):


	As deployments increase in complexity and our clients rapidly add new software
	components and expand software footprints, we have seen a definitive shift
	away from traditional installation methods to more automated/scriptable
	deployment approaches. At Pentaho, our goal is to ensure our clients continue
	to enjoy flexibility to adapt our technology to their environments and
	individual standards.

	Throughout 2015, Pentaho worked with customers who use various deployment
	technologies in development, test, and production environments. We have seen
	that the range of technologies used for scripted software deployment can vary
	as widely as the internal IT standards of our clients. In short, we have not
	found critical mass in any single deployment pattern.

	To support our clients in their adoption of these technologies, Pentaho takes
	the perspective that our clients should continue to be autonomous in their
	selection and implementation of automated deployment and configuration
	management.

	Pentaho will provide documented best practices, based on our experience and
	knowledge of our product, to assist our clients in understanding the
	scriptable and configurable options within our product, along with our
	deployment best practices. Due to the diversity of technology options, Pentaho
	customer support will remain focused on the behavior of the Pentaho software
	and will provide expertise on the Pentaho products to help customers
	troubleshoot individual scripts or containers.


Have fun. Tips and suggestions to pedro.alves _at_ webdetails.pt


