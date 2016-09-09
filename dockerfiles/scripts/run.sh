#screen -S pentaho -d -m -t shell bash
#screen -S pentaho -X screen -t logs bash

sudo /etc/init.d/postgresql start

if [ -z "$DEBUG" ]; then
  echo Starting Pentaho in normal mode
  cd /pentaho/*server*
  ./start-pentaho.sh;
else
  echo Starting Pentaho in debug mode
  cd /pentaho/*server*
  ./start-pentaho-debug.sh;
fi

