import sys
import os

if len(sys.argv) < 2:
 pass
else:
 path = '/etc/postgresql/' + sys.argv[1] + '/main/pg_hba.conf'
 FILE = open(path)

 linesNew = []
 passOne = False

 for line in FILE:
  
  if passOne:
   passOne = False
   continue

  if line == '''# "local" is for Unix domain socket connections only\n''':
   os.system("echo done")
   linesNew.append(line)
   linesNew.append("local   all             all                                     md5\n")
   passOne = True

  else:
   linesNew.append(line)


 FILE.close()
 
 CONFIGFILE = open(path,'w')

 for line in linesNew:
  CONFIGFILE.write(line)
 CONFIGFILE.close()
