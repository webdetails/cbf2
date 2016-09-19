FROM BUILDPROJECTFROMIMAGE
MAINTAINER  Pedro Alves <palves@pentaho.com>


# Dockerfile to work with CBF2
# This dockerfile assumes a certain structure. Don't change unless you know what
# you're doing
#
# If you want to override with a project specific dockerfile, you need to reuse
# these instructions



# Add the solutions

ADD solution.zip /pentaho
RUN mv /pentaho/solution.zip /pentaho/*server*/pentaho-solutions/system/default-content/


# Configure mondrian logs

RUN perl -ibak -p0e 's#(</log4j:configuration>)#   <category name="mondrian">      <priority value="DEBUG"/>   </category>   <category name="mondrian.sql">      <priority value="DEBUG"/>   </category><category name="mondrian.olap.fun"><priority value="INFO"/></category><category name="mondrian.rolap.NoCacheMemberReader"><priority value="INFO"/></category><category name="mondrian.i18n.LocalizingDynamicSchemaProcessor"><priority value="INFO"/></category><category name="mondrian.rolap.RolapConnection"><priority value="INFO"/></category><category name="mondrian.olap.ResultBase"><priority value="INFO"/></category><category name="mondrian.rolap.agg.AggregationManager"><priority value="INFO"/></category><category name="mondrian.rolap.SqlStatement"><priority value="INFO"/></category><category name="mondrian.olap.RoleImpl"><priority value="INFO"/></category><category name="mondrian.rolap.RolapMember"><priority value="INFO"/></category>$1#s' /pentaho/*server*/tomcat/webapps/pentaho/WEB-INF/classes/log4j.xml && \
 perl -ibak -p0e 's/(PENTAHOCONSOLE.*?value=.)(?:ERROR|INFO)/$1DEBUG/s' /pentaho/*server*/tomcat/webapps/pentaho/WEB-INF/classes/log4j.xml



# Allow fonts to be imported

RUN perl -ibak -p0e 's#(<MimeTypeDefinitions>)#$1<MimeTypeDefinition mimeType="application/x-font-woff" hidden="true"><extension>woff</extension></MimeTypeDefinition><MimeTypeDefinition mimeType="application/vnd.ms-fontobject" hidden="false"><extension>eot</extension></MimeTypeDefinition><MimeTypeDefinition mimeType="application/x-font-otf" hidden="false"><extension>otf</extension></MimeTypeDefinition><MimeTypeDefinition mimeType="application/octet-stream" hidden="false"><extension>ttf</extension></MimeTypeDefinition>#s' /pentaho/*server*/pentaho-solutions/system/ImportHandlerMimeTypeDefinitions.xml && \
		perl -ibak -p0e 's/("org.pentaho.platform.plugin.services.importer.LocaleImportHandler".*?<value>xcdf<\/value>)/$1<value>eot<\/value><value>ttf<\/value><value>woff<\/value><value>otf<\/value>/s' /pentaho/*server*/pentaho-solutions/system/importExport.xml && \
		perl -ibak -p0e 's/("org.pentaho.platform.plugin.services.importexport.DefaultExportHandler".*?<value>.xcdf<\/value>)/$1<value>.eot<\/value><value>.ttf<\/value><value>.woff<\/value><value>.otf<\/value>/s' /pentaho/*server*/pentaho-solutions/system/importExport.xml && \
		perl -ibak -p0e 's/("convertersMap".*?"streamConverter"\/>)/$1<entry key="eot" value-ref="streamConverter"\/><entry key="ttf" value-ref="streamConverter"\/><entry key="woff" value-ref="streamConverter"\/><entry key="otf" value-ref="streamConverter"\/>/s' /pentaho/*server*/pentaho-solutions/system/importExport.xml


# It's pretty much this for now, actually...
