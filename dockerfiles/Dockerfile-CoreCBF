FROM    ubuntu:16.04
MAINTAINER  Pedro Alves <palves@pentaho.com>

# Set the locale

RUN apt-get clean && apt-get update && apt-get install -y locales && locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8 
ENV TERM xterm
RUN update-locale LANG=en_US.UTF-8 LC_MESSAGES=POSIX && \
    echo Building core image

# For jdk7, install oracle-java7-installer
# For jdk8, install oracle-java8-installer

RUN sed 's/main$/main universe/' -i /etc/apt/sources.list && \
	apt-get update && apt-get install -y software-properties-common unzip git lftp sudo && apt-get install postgresql postgresql-contrib -y && \
	apt-get update && apt-get upgrade -y && add-apt-repository ppa:webupd8team/java -y && \
	apt-get update && \
	echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
	# DISABLED - Oracle removed java7 from pub site :( # apt-get install -y oracle-java7-installer && \
	echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
	# DISABLED apt-get install -y oracle-java8-installer && \
	sudo apt install -y openjdk-8-jdk && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* && \
	echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
	rm -rf /tmp/*
    

ADD pg_hba.conf /etc/postgresql/9.5/main/pg_hba.conf

RUN echo "listen_addresses='*'" >> /etc/postgresql/9.5/main/postgresql.conf


