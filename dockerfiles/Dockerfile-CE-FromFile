FROM cbf2-core
MAINTAINER  Pedro Alves <palves@pentaho.com>

ADD scripts/run.sh /pentaho/
ADD tmp/pentaho/ /pentaho/
ADD pg_hba.conf /etc/postgresql/9.5/main/pg_hba.conf

RUN cd /pentaho && \
  /etc/init.d/postgresql start && \
  cd /pentaho/*server*/data/postgresql; \
  psql -U postgres -f create_jcr_postgresql.sql; \
  psql -U postgres -f create_quartz_postgresql.sql; \
  psql -U postgres -f create_repository_postgresql.sql; \
  rm /pentaho/*server*/promptuser.sh; \
  touch /pentaho/*server*/tomcat/logs/catalina.out ; \
  touch /pentaho/*server*/tomcat/logs/pentaho.log ; \
  sed -i -e 's/\(exec ".*"\) start/\1 run/' /pentaho/*server*/tomcat/bin/startup.sh; \
  mkdir /home/pentaho && groupadd -r pentaho && useradd -r -g pentaho -p $(perl -e'print crypt("pentaho", "aa")' ) -G sudo pentaho && \ 
  chown -R pentaho.pentaho /pentaho && \ 
  chown -R pentaho.pentaho /home/pentaho && \
	if [ $( ls -1 /pentaho/*server*/tomcat/webapps/pentaho/WEB-INF/lib/pentaho-platform-api-*.jar | head -n 1 | sed -E -e 's/.*pentaho-platform-api-(.).+/\1/' )  -lt "6"  ]; then update-java-alternatives -s java-7-oracle && echo Java 7 enabled ; else echo Java 8 enabled; fi && \
	/etc/init.d/postgresql stop

WORKDIR /pentaho
USER pentaho


EXPOSE 8080 8044 9001

# 1. Run 

ENTRYPOINT ["bash", "/pentaho/run.sh"]

