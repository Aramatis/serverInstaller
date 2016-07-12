====================================================
To install the server in a machine.
====================================================

Copy the folder install to the desired machine. It's tested on Ubuntu 14.04. 
It should run on any debian distribution.
OBS: in wheezy has a problem with apache version because de app needs 2.4 or grater but official apache distribution in wheezy is 2.2. So you need to download apache from official website.

We will install apache, postgresql and the server that runs on Django.
The scrips handles all the configurations issues and the loading of initial data 
(this task takes some time).

The only thing that matters is that you have sudo provileges.

If you want to bring up an AWS EC2 with ubuntu OS use:

	scp -i key -r install ubuntu@<ip>:/home/ubuntu

all the files to the machine, and then access to it through ssh (also use -i key).

To install go to the install folder and run 

	bash installScript.sh <androidKeyStorePass> <ServerPublicIP>

OBS*:
    - <androidKeyStorePass> : used in store file for android app. This pass has to write in res/values/strings.xml "key_store" 
    - <ServerPublicIP> : used in apache configuration file 

give the sudo pass if needed.
The script is commented, read it if in doubt.

OPTIONS

In installScript.sh you can select what you want to execute changing the boolean variables in the begining of the file

Then wait, and enjoy! :-).
