====================================================
Overview
====================================================

This repository mantains the code for deploying the TranSapp server on a linux machine, which means:
- Step 1: linux user creation (defaults to `"server"`) and prompts for his password.
- Step 2: Installs server prerequisites: java8, apache, postgresql, ...
- Step 3: It configures postgresql
- Step 4: Clone and setup of the django app
- Step 5: It configures apache
- Step 6: Data import from CSV files

The last step REALLY takes "half a day or so", so please be patient.


====================================================
PREREQUISITES
====================================================

## Linux Machine with Ubuntu 14.04

This has only been tested on Ubuntu 14.04 machines. However, it should run on any debian distribution.

OBS: Wheezy has a problem with the apache version: TranSapp requires Apache >=2.4, but the official apache distribution in wheezy is 2.2. So you need to download apache from the official website.


## Superuser privileges

The installation script requires sudo privileges.



====================================================
DEPLOYMENT
====================================================

## Get the installer

```bash
# move to directory with permissions to read and write
cd /tmp

# clone directly on the target machine
$ git clone https://github.com/InspectorIncognito/serverInstaller.git

# or download anywhere and then copy the files to the visualization server:
# e.g. if you want to bring up an AWS EC2 with ubuntu OS:
$ scp -i <private_key> -r install <server-user>@<server-host>:/home/<server-user>
```

## Run the installer

You need the following information:
- `<ANDROID_KEY_STORE_PASS>`: used in store file for android app. This pass has to write in res/values/strings.xml "key_store" 
- `<SERVER_PUBLIC_IP>`: used in apache configuration file

It is highly recommended to read the script before running it and ALSO EXECUTTE IT BY ONE PIECE AT A TIME!. Modify the configuration section on `installScript.sh` to select which steps do you want to run. The recommended way is to deactivate all steps and run then separately. 

### KNOWN ISSUE

The `project_configuration` step WILL FAIL!.. so, prefer setting the remaining steps variables to `false` and then fix it this way:
- get a google key file from somewhere
- place this key under `<django-git-cloned-folder>/server/keys`, under the name of `google_key.json`. 


### RUN

```bash
# run with sudo
$ sudo su
$ bash installScript.sh <ANDROID_KEY_STORE_PASS> <SERVER_PUBLIC_IP>
```

## Finally, sit down, wait 5-10 hours, and enjoy! :).
