def getConfiguration(startServers=2, minSpareThreads=25, maxSpareThreads=75, threadLimit=64, threadsPerChild=25, maxRequestWorkers=150, maxConnectionsPerChild=0):
	return '''# worker MPM
# StartServers: initial number of server processes to start
# MinSpareThreads: minimum number of worker threads which are kept spare
# MaxSpareThreads: maximum number of worker threads which are kept spare
# ThreadLimit: ThreadsPerChild can be changed to this maximum value during a
#			  graceful restart. ThreadLimit can only be changed by stopping
#			  and starting Apache.
# ThreadsPerChild: constant number of worker threads in each server process
# MaxRequestWorkers: maximum number of threads
# MaxConnectionsPerChild: maximum number of requests a server process serves

<IfModule mpm_worker_module>
	StartServers			 ''' + startServers +'''
	MinSpareThreads		 ''' + minSpareThreads +'''
	MaxSpareThreads		 ''' + maxSpareThreads +'''
	ThreadLimit			 ''' + threadLimit +'''
	ThreadsPerChild		 ''' + threadsPerChild +'''
	MaxRequestWorkers	  ''' + maxRequestWorkers +'''
	MaxConnectionsPerChild   ''' + maxConnectionsPerChild +'''
</IfModule>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet'''

import sys
import os

if len(sys.argv) < 8:
 pass
else:
 configFile = getConfiguration(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6], sys.argv[7])

 #Writte the file to destine
 path = '/etc/apache2/mods-available/mpm_worker.conf'

 FILE = open(path,'w')
 for line in configFile:
  FILE.write(line)
 FILE.close()
