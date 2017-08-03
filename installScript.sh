#!/bin/bash

#####################################################################
# COMMAND LINE INPUT
#####################################################################
if [ -z "$1" ]; then
    echo "No se especifico la clave para el key store"
    exit 
fi

if [ -z "$2" ]; then
    echo "No se especifico la ip del servidor"
    exit 
fi
KEY_STORE_PASS=$1
IP_SERVER=$2


#####################################################################
# CONFIGURATION
#####################################################################

install_packages=false
postgresql_configuration=false
project_configuration=false
apache_configuration=true
import_data=false

USER_NAME="server"
PROJECT_DEST=/home/"$USER_NAME"/Documents


initialPATH=$(pwd)

#####################################################################
# USER CONFIGURATION
#####################################################################

# stores the current path
if id "$USER_NAME" >/dev/null 2>&1; then
    echo "User $USER_NAME already exists.. skipping"
else
    echo "User $USER_NAME does not exists.. CREATING!"
    adduser $USER_NAME
fi


#####################################################################
# REQUIREMENTS
#####################################################################

if $install_packages; then
    # Install all necesary things
    # use eog to view image through ssh by enabling the -X flag
    # Ejample: ssh -X .....
    # then run eog <image>
    # and wait 
    apt-get update 
    apt-get upgrade

    # PPA for JAVA
    add-apt-repository ppa:webupd8team/java

    apt-get --yes --force-yes install build-essential apache2 git python-setuptools libapache2-mod-wsgi python-dev libpq-dev postgresql postgresql-contrib 
    apt-get --yes --force-yes install eog oracle-java8-installer
    sudo apt-get install openssh-server
    
    # easy_install is a python module bundled with setuptools that lets you automatically download, build, install, and manage Python packages.
    easy_install pip
fi


#####################################################################
# POSTGRESQL
#####################################################################
if $postgresql_configuration; then
  echo ----
  echo ----
  echo "Postgresql"
  echo ----
  echo ----

  # get the version of psql
  psqlVersion=$(psql -V | egrep -o '[0-9]{1,}\.[0-9]{1,}')
  # change config of psql
  python replaceConfigPSQL.py "$psqlVersion"
  service postgresql restart
  # postgres user has to be owner of the file and folder that contain the file
  current_owner=$(stat -c '%U' .)
  chown postgres "$initialPATH"/postgresqlConfig.sql
  chown postgres "$initialPATH"
  # create user and database
  sudo -u postgres psql -f "$initialPATH"/postgresqlConfig.sql
  chown "${current_owner}" "$initialPATH"/postgresqlConfig.sql
  chown "${current_owner}" "$initialPATH"

  echo ----
  echo ----
  echo "Postgresql ready"
  echo ----
  echo ----
fi


#####################################################################
# CLONE SETUP DJANGO APP
#####################################################################
if $project_configuration; then
  echo ----
  echo ----
  echo "Project configuration"
  echo ----
  echo ----

  echo ""
  echo --
  echo "Server directory: "
  echo --
  echo ""

  # to Documents folder
  if cd $PROJECT_DEST; then
     pwd
  else
    mkdir -p $PROJECT_DEST
  fi

  # go to project destination path
  cd $PROJECT_DEST

  # clone project from git
  echo ""
  echo ----
  echo "Clone project from gitHub"
  echo ----
  echo ""
  git clone https://github.com/InspectorIncognito/server.git
  cd server
  git submodule init
  git submodule update
  cd ..

  # configure wsgi
  cd "$initialPATH"
  python wsgiConfig.py "$PROJECT_DEST"

  # create secret_key.txt file
  SECRET_KEY_FILE=$PROJECT_DEST/server/server/keys/secret_key.txt
  touch $SECRET_KEY_FILE
  echo "putYourSecretKeyHere" > "$SECRET_KEY_FILE"

  # create folder used by loggers if not exist
  LOG_DIR="$PROJECT_DEST"/server/server/logs
  mkdir -p "$LOG_DIR"
  touch $LOG_DIR/file.log
  chmod 777 "$LOG_DIR"/file.log
  touch $LOG_DIR/dbfile.log
  chmod 777 "$LOG_DIR"/dbfile.log

  # install all dependencies of python to the project
  cd "$PROJECT_DEST"/server
  pip install -r requirements.txt

  # initialize the database
  python manage.py makemigrations
  python manage.py migrate
  # add the cron task data
  python manage.py crontab add

  # creates markdown document for the data model
  python manage.py listing_models --format md > DataDictionary/templates/dataDic.md

  # create the html
  cd DataDictionary/templates/
  python parseMKtoHTML.py
  cd "$PROJECT_DEST"/server

  #running test
  coverage run --source='.' manage.py test
  coverage report --omit=DataDictionary/*,server/* -m

  echo ----
  echo ----
  echo "Project configuration ready"
  echo ----
  echo ----
fi


#####################################################################
# APACHE CONFIGURATION
#####################################################################
if "$apache_configuration"; then
  echo ----
  echo ----
  echo "Apache configuration"
  echo ----
  echo ----
  # configure apache 2.4

  cd "$initialPATH"
  configApache="transapp_server.conf"

  sudo python configApache.py "$PROJECT_DEST" "$IP_SERVER" "$configApache"
  sudo a2dissite 000-default.conf
  sudo a2ensite "$configApache"
  # ssl configuration
  sudo cp ssl.conf /etc/apache2/mods-available
  sudo a2enmod ssl
  sudo a2enmod headers 

  # create the certificfate
  # this part must be by hand
  sudo mkdir /etc/apache2/ssl
  cd /etc/apache2/ssl

  sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt

  # create android key store
  # -nc refuse to download newer copies of the file
  sudo wget -nc https://bouncycastle.org/download/bcprov-jdk15on-155.jar
  sudo keytool -importcert -file apache.crt -keystore transapp.store -provider org.bouncycastle.jce.provider.BouncyCastleProvider -providerpath bcprov-jdk15on-155.jar -storetype BKS -storepass "$KEY_STORE_PASS"

  sudo service apache2 reload

  # change the MPM of apache.
  # MPM is the way apache handles the request
  # using proceses, threads or a bit of both.

  # this is the default 
  # is though to work whith php
  # becuase php isn't thread safe.
  # django works better whith
  # MPM worker, but set up
  # the number of precess and
  # threads whith care.

  sudo a2dismod mpm_event 
  sudo a2enmod mpm_worker 

  # configuration for the worker
  # mpm.
  # apacheSetup arg1 arg2 arg3 ... arg7
  # arg1 StartServers: initial number of server processes to start
  # arg2 MinSpareThreads: minimum number of 
  #      worker threads which are kept spare
  # arg3 MaxSpareThreads: maximum number of
  #      worker threads which are kept spare
  # arg4 ThreadLimit: ThreadsPerChild can be 
  #      changed to this maximum value during a
  #      graceful restart. ThreadLimit can only 
  #      be changed by stopping and starting Apache.
  # arg5 ThreadsPerChild: constant number of worker 
  #      threads in each server process
  # arg6 MaxRequestWorkers: maximum number of threads
  # arg7 MaxConnectionsPerChild: maximum number of 
  #      requests a server process serves
  cd "$initialPATH"
  sudo python apacheSetup.py 1 10 50 30 25 75

  sudo service apache2 restart

  # this lets apache add new things to the media folder
  # to store the pictures of the free report
  sudo adduser www-data "$USER_NAME"

  echo ----
  echo ----
  echo "Apache configuration ready"
  echo ----
  echo ----
fi


#####################################################################
# IMPORT DATA
#####################################################################
if $import_data; then
  echo ----
  echo ----
  echo "Population of data in the database"
  echo "this will take a while... half a day or so"
  echo ----
  echo ----

  cd $PROJECT_DEST/server
  DATA_VERSION="v1.1"
  python loadData.py "$DATA_VERSION" busstop InitialData/"$DATA_VERSION"/busstop.csv service InitialData/"$DATA_VERSION"/services.csv servicesbybusstop InitialData/"$DATA_VERSION"/servicesbybusstop.csv servicestopdistance InitialData/"$DATA_VERSION"/servicestopdistance.csv ServiceLocation InitialData/"$DATA_VERSION"/servicelocation.csv event InitialData/events.csv

  echo ----
  echo ----
  echo "Population of data ready"
  echo ----
  echo ----
fi

cd "$initialPATH"

echo "Ready, if everything went well you stop here."
echo "Otherwise run in the project folder python manage.py runserver 0.0.0.0:8080 and try it,"
echo "See what went wrong."
echo "Also check if you can acces the database, with "
echo "$ psql ghostinspector --user=inspector (the password is inside the settings.py of the project)."

