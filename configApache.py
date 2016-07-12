
def getConfigFileHTTP(pathToProyect):
    return '''<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com

        #ServerAdmin webmaster@localhost
        #DocumentRoot /var/www/html

        Alias /static ''' + pathToProyect + '''/server/static
        <Directory ''' + pathToProyect + '''/server/static>
                Require all granted
        </Directory>

        <Directory ''' + pathToProyect + '''/server/server>
                <Files wsgi.py>
                      Require all granted
                </Files>
        </Directory>

        LoadModule wsgi_module /usr/lib/apache2/modules/mod_wsgi.so

        #WSGIDaemonProcess myproject python-path=/home/user/myproject:/home/user/myproject/myprojectenv/lib/python2.7/$
        #WSGIProcessGroup myproject
        WSGIScriptAlias / ''' + pathToProyect + '''/server/server/wsgi.py

        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        #Include conf-available/serve-cgi-bin.conf
    </VirtualHost>'''

def getConfigFileHTTPS(pathToProyect, ip):
    return '''<VirtualHost *:443>

            ServerName ''' + ip + '''
            Alias /static ''' + pathToProyect + '''/server/static
            <Directory ''' + pathToProyect + '''/server/static>
                    Require all granted
            </Directory>
            <Directory ''' + pathToProyect + '''/server/server>
                    <Files wsgi.py>
                          Require all granted
                    </Files>
            </Directory>

            LoadModule wsgi_module /usr/lib/apache2/modules/mod_wsgi.so

            WSGIScriptAlias / ''' + pathToProyect + '''/server/server/wsgi.py

            ErrorLog ${APACHE_LOG_DIR}/error.log
            CustomLog ${APACHE_LOG_DIR}/access.log combined

            SSLEngine on
            SSLCertificateFile /etc/apache2/ssl/apache.crt
            SSLCertificateKeyFile /etc/apache2/ssl/apache.key

            # HSTS (mod_headers is required) (15768000 seconds = 6 months)
            Header always set Strict-Transport-Security "max-age=15768000"

            <FilesMatch "\.(cgi|shtml|phtml|php)$">
                            SSLOptions +StdEnvVars
            </FilesMatch>
            <Directory /usr/lib/cgi-bin>
                            SSLOptions +StdEnvVars
            </Directory>
            BrowserMatch "MSIE [2-6]" \
                            nokeepalive ssl-unclean-shutdown \
                            downgrade-1.0 force-response-1.0
            BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown
    </VirtualHost>'''

import sys
import os

if len(sys.argv) < 4:
    pass
else:
    #configFile = getConfigFileHTTP(sys.argv[1])
    configFile = getConfigFileHTTPS(sys.argv[1], sys.argv[2])

    #Writte the file to destine
    path = '/etc/apache2/sites-available/'

    FILE = open(path + sys.argv[3],'w')
    for line in configFile:
        FILE.write(line)
    FILE.close()
