FROM BUILDPROJECTFROMIMAGE
LABEL maintainer="Brandon Jackson <usbrandon@gmail.com>"

USER pentaho
# Dockerfile to work with CBF2 and BA Server 8.2
# This dockerfile assumes a certain structure. Don't change unless you know what
# you're doing
#
# If you want to override with a project specific dockerfile, you need to reuse
# these instructions


# Add the solution
ADD solution.zip /pentaho
RUN mv /pentaho/solution.zip /pentaho/pentaho-server/pentaho-solutions/system/default-content/


#Add and install Community Test Editor
ADD --chown=pentaho:pentaho /dev/cte-8.0-SNAPSHOT.zip /pentaho/pentaho-server/pentaho-solutions/system/
RUN unzip /pentaho/pentaho-server/pentaho-solutions/system/cte-8.0-SNAPSHOT.zip -d /pentaho/pentaho-server/pentaho-solutions/system \
 && rm /pentaho/pentaho-server/pentaho-solutions/system/cte-8.0-SNAPSHOT.zip

#Add and install Sparkl "Application Builder"
ADD --chown=pentaho:pentaho /dev/sparkl-8.2.0.0-342.zip /pentaho/pentaho-server/pentaho-solutions/system/
RUN unzip /pentaho/pentaho-server/pentaho-solutions/system/sparkl-8.2.0.0-342.zip -d /pentaho/pentaho-server/pentaho-solutions/system \
 && rm /pentaho/pentaho-server/pentaho-solutions/system/sparkl-8.2.0.0-342.zip

#Add and install the Log Manager pluging
ADD --chown=pentaho:pentaho https://github.com/cdeptula/logManager/releases/download/2.0.0/logManager.zip /pentaho/pentaho-server/pentaho-solutions/system/
RUN unzip /pentaho/pentaho-server/pentaho-solutions/system/logManager.zip -d /pentaho/pentaho-server/pentaho-solutions/system \
 && rm /pentaho/pentaho-server/pentaho-solutions/system/logManager.zip


# Add patches
ADD patches/ /pentaho/patches
RUN sudo chown -R pentaho.pentaho /pentaho/patches && \
	cp -R /pentaho/patches/* /pentaho/pentaho-server/ 


# This is a example how define a kettle variable to load your data in PDI 
# copy your data file to /pentaho/pentaho-server/tomcat/webapps/pentaho-style/data
# and define your kettle variable, example  SVGCAR_DATA_DIR
#
 RUN mkdir -p /home/pentaho/.kettle && \
	touch /home/pentaho/.kettle/kettle.properties && \
	echo SVGCAR_DATA_DIR = /pentaho/pentaho-server/tomcat/webapps/pentaho-style/data >> /home/pentaho/.kettle/kettle.properties


#Change logo image
# Path's changed in 8.2 - disabling for now.
#Change the logo.svg in folder 	logo-image
#ADD logo-image/ /pentaho/logo-image
#RUN cp -R /pentaho/logo-image/logo.svg /pentaho/pentaho-server/pentaho-solutions/system/common-ui/resources/themes/myTheme/images/

	
# Configure mondrian logs
RUN perl -ibak -p0e 's#(</log4j:configuration>)#   <category name="mondrian">      <priority value="DEBUG"/>   </category>   <category name="mondrian.sql">      <priority value="DEBUG"/>   </category><category name="mondrian.olap.fun"><priority value="INFO"/></category><category name="mondrian.rolap.NoCacheMemberReader"><priority value="INFO"/></category><category name="mondrian.i18n.LocalizingDynamicSchemaProcessor"><priority value="INFO"/></category><category name="mondrian.rolap.RolapConnection"><priority value="INFO"/></category><category name="mondrian.olap.ResultBase"><priority value="INFO"/></category><category name="mondrian.rolap.agg.AggregationManager"><priority value="INFO"/></category><category name="mondrian.rolap.SqlStatement"><priority value="INFO"/></category><category name="mondrian.olap.RoleImpl"><priority value="INFO"/></category><category name="mondrian.rolap.RolapMember"><priority value="INFO"/></category>$1#s' /pentaho/pentaho-server/tomcat/webapps/pentaho/WEB-INF/classes/log4j.xml && \
 perl -ibak -p0e 's/(PENTAHOCONSOLE.*?value=.)(?:ERROR|INFO)/$1DEBUG/s' /pentaho/pentaho-server/tomcat/webapps/pentaho/WEB-INF/classes/log4j.xml
 

#Set CTools Plugin properties
 RUN perl -ibak -p0e 's/<!--|-->//g' /pentaho/pentaho-server/pentaho-solutions/system/pentaho-cdf-dd/plugin.xml && \
	sed -i.bak 's/<!--//g;s/-->//g' /pentaho/pentaho-server/pentaho-solutions/system/cda/plugin.xml


# Allow fonts to be imported
RUN	perl -ibak -p0e 's#(<MimeTypeDefinitions>)#$1<MimeTypeDefinition mimeType="application/x-font-woff" hidden="true"><extension>woff</extension></MimeTypeDefinition><MimeTypeDefinition mimeType="application/vnd.ms-fontobject" hidden="false"><extension>eot</extension></MimeTypeDefinition><MimeTypeDefinition mimeType="application/x-font-otf" hidden="false"><extension>otf</extension></MimeTypeDefinition><MimeTypeDefinition mimeType="application/x-font-ttf" hidden="false"><extension>ttf</extension></MimeTypeDefinition>#s' /pentaho/pentaho-server/pentaho-solutions/system/ImportHandlerMimeTypeDefinitions.xml && \
		perl -ibak -p0e 's/("org.pentaho.platform.plugin.services.importer.LocaleImportHandler".*?<value>xcdf<\/value>)/$1<value>eot<\/value><value>ttf<\/value><value>woff<\/value><value>otf<\/value>/s' /pentaho/pentaho-server/pentaho-solutions/system/importExport.xml && \
		perl -ibak -p0e 's/("org.pentaho.platform.plugin.services.importexport.DefaultExportHandler".*?<value>.xcdf<\/value>)/$1<value>.eot<\/value><value>.ttf<\/value><value>.woff<\/value><value>.otf<\/value>/s' /pentaho/pentaho-server/pentaho-solutions/system/importExport.xml && \
		perl -ibak -p0e 's/("convertersMap".*?"streamConverter"\/>)/$1<entry key="eot" value-ref="streamConverter"\/><entry key="ttf" value-ref="streamConverter"\/><entry key="woff" value-ref="streamConverter"\/><entry key="otf" value-ref="streamConverter"\/>/s' /pentaho/pentaho-server/pentaho-solutions/system/importExport.xml

 

# Enable Pentaho Marketplace
RUN perl -ibak -p0e 's/pentaho-big-data-ee-plugin-osgi-obf/pentaho-big-data-ee-plugin-osgi-obf,pentaho-marketplace/' /pentaho/pentaho-server/pentaho-solutions/system/karaf/etc/org.apache.karaf.features.cfg

# It's pretty much this for now, actually...
