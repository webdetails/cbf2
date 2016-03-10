FROM BUILDPROJECTFROMIMAGE
MAINTAINER  Pedro Alves <palves@pentaho.com>


# Dockerfile to work with PDU - Pentaho Docker Utils;
# This dockerfile assumes a certain structure. Don't change unless you know what
# you're doing



# Add the solutions

ADD solution.zip /pentaho
RUN mv /pentaho/solution.zip /pentaho/biserver-*/pentaho-solutions/system/default-content/

# It's pretty much this for now, actually...
