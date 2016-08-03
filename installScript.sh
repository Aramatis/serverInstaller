#! /bin/bash

install_packages=true
postgresql_configuration=true
project_configuration=true
apache_configuration=true
import_data=true

# Install all necesary things
# use eog to view image through ssh by enabling the -X flag
# Ejample: ssh -X .....
# then run eog <image>
# and wait 

if [ -z "$1" ]
  then
    echo "No se especifico la clave para el key store"
    exit 
fi

if [ -z "$2" ]
  then
    echo "No se especifico la ip del servidor"
    exit 
fi

keyStorePass=$1
ip_server=$2

# stores the current path
initialPATH=$(pwd)

if $install_packages; then
	# PPA: Personal Package Archive. PPA's are repositories provided by the community
	sudo add-apt-repository ppa:webupd8team/java
    # replace debian distribution name for ubuntu distribution name. It is necessary for debian distributions
    sed -i 's/wheezy/trusty/g' /etc/apt/sources.list.d/webupd8team-java-wheezy.list 
	sudo apt-get update 
	sudo apt-get --yes --force-yes install apache2 git python-setuptools libapache2-mod-wsgi python-dev libpq-dev postgresql postgresql-contrib eog oracle-java8-installer 
	# easy_install is a python module bundled with setuptools that lets you automatically download, build, install, and manage Python packages.
	sudo easy_install pip

  # install apache 2.4.18. it's necessary in debian 7 because debian 7 use apache 2.2
  #sudo wget -nc http://www-us.apache.org/dist//httpd/httpd-2.4.18.tar.gz
  #sudo wget -nc http://www-eu.apache.org/dist//apr/apr-util-1.5.4.tar.gz
  #sudo wget -nc http://www-eu.apache.org/dist//apr/apr-1.5.2.tar.gz
  #tar -xzvf apr-util-1.5.4.tar.gz
  #tar -xzvf apr-1.5.2.tar.gz
  #tar -xzvf httpd-2.4.18.tar.gz
  #./apr-1.5.2/configure --prefix=./srclib/apr
  #./apr-1.5.2/make
  #./apr-1.5.2/make install
  #./apr-util-1.5.4/configure --prefix=./srclib/apr-util --wit-apr=../srclib/apr-lib
  #./apr-util-1.5.4/make  
  #./apr-util-1.5.4/make install 
  #./httpd-2.4.18/configure --prefix=/usr/local/apache2 --with-apr= --with-apr-util=
  #./httpd-2.4.18/make
  #./httpd-2.4.18/make install
  #/usr/local/apache2/bin/apachectl start 
fi

#configure postgresql

if $postgresql_configuration; then
  echo ----
  echo ----
  echo "Postgresql"
  echo ----
  echo ----

  # get the version of psql
  psqlVersion=$(psql -V | egrep -o '[0-9]{1,}\.[0-9]{1,}')
  # change config of psql
  sudo python replaceConfigPSQL.py $psqlVersion
  sudo service postgresql restart
  # postgres user has to be owner of the file and folder that contain the file
  current_owner=$(stat -c '%U' .)
  sudo chown postgres $initialPATH/postgresqlConfig.sql
  sudo chown postgres $initialPATH
  # create user and database
  sudo -u postgres -i psql -f $initialPATH/postgresqlConfig.sql
  sudo chown ${current_owner} $initialPATH/postgresqlConfig.sql
  sudo chown ${current_owner} $initialPATH

  echo ----
  echo ----
  echo "Postgresql ready"
  echo ----
  echo ----
fi

if $project_configuration; then
  echo ----
  echo ----
  echo "Project configuration"
  echo ----
  echo ----

  echo ""
  echo --
  echo "Directorio del servidor: "
  echo --
  echo ""

  #go to home path
  cd

  # to Documents folder
  if cd Documentos; then
     pwd
  else
    mkdir Documentos
    cd Documentos
  fi

  # clone project from git
  echo ""
  echo ----
  echo "Clone project from gitHub"
  echo ----
  echo ""
  git clone https://github.com/InspectorIncognito/server.git

  #destination of the project
  projecDest=$(pwd)

  # configure wsgi
  cd $initialPATH
  python wsgiConfig.py $projecDest

  # create folder used by loggers if not exist
  LOG_DIR=$projecDest/server/server/logs
  if [ -d "$LOG_DIR" ]; then
    mkdir $LOG_DIR
    touch $LOG_DIR/file.log
    chmod 777 $LOG_DIR/file.log
  fi

  # install all dependencies of python to the project
  cd $projecDest/server
  sudo pip install -r requirements.txt

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
  cd $projecDest/server

  #running test
  coverage run --source='.' manage.py test
  coverage report --omit=DataDictionary/*,server/* -m

  echo ----
  echo ----
  echo "Project configuration ready"
  echo ----
  echo ----
fi

if $apache_configuration; then
  echo ----
  echo ----
  echo "Apache configuration"
  echo ----
  echo ----
  # configure apache 2.4

  cd $initialPATH
  configApache="transapp_server.conf"

  sudo python configApache.py $projecDest $ip_server $configApache
  sudo a2dissite 000-default.conf
  sudo a2ensite $configApache
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
  sudo wget -nc http://bouncycastle.org/download/bcprov-jdk16-146.jar
  sudo keytool -importcert -file apache.crt -keystore transapp.store -provider org.bouncycastle.jce.provider.BouncyCastleProvider -providerpath bcprov-jdk16-146.jar -storetype BKS -storepass $keyStorePass

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
  cd $initialPATH
  sudo python apacheSetup.py 1 10 50 30 25 75

  sudo service apache2 restart

  # this lets apache add new things to the media folder
  # to store the pictures of the free report
  sudo adduser www-data ubuntu

  echo ----
  echo ----
  echo "Apache configuration ready"
  echo ----
  echo ----
fi

if $import_data; then
  echo ----
  echo ----
  echo "Population of data in the database"
  echo "this will take a while... half a day or so"
  echo ----
  echo ----

  cd $projecDest/server
  python loadData.py busstop InitialData/busstops.csv service InitialData/services.csv servicesbybusstop InitialData/servicesbybusstop.csv servicestopdistance InitialData/servicestopdistance.csv ServiceLocation InitialData/servicelocation.csv event InitialData/events.csv route InitialData/routes.csv

  echo ----
  echo ----
  echo "Population of data ready"
  echo ----
  echo ----
fi

cd $initialPATH

echo "Ready, if everything went well you stop here."
echo "Otherwise run in the project folder python manage.py runserver 0.0.0.0:8080 and try it,"
echo "See what went wrong."
echo "Also check if you can acces the database, with "
echo "$ psql ghostinspector --user=inspector (the password is inside the settings.py of the project)."

