#Author Prince Abraham

#!/bin/bash +x

# redirect stderr

exec 2>&1

# Variables 

export PROJECT_DIR="/{{cfg.proj_dir}}/{{cfg.user}}"
export CALTEC_BINARY="dfffr-{{pkg.version}}.tar.gz"

# Create group, user and user home 

if grep {{cfg.user}} /etc/group
 then :
 else groupadd  -g {{cfg.userid}} {{cfg.user}}
fi

if grep {{cfg.user}} /etc/passwd
 then :
 else useradd -s /bin/bash -p {{cfg.password}} -g {{cfg.userid}} -u {{cfg.userid}} -c "F xx" -d  /{{cfg.homemount}}/{{cfg.user}} {{cfg.user}}
     [ -d /{{cfg.homemount}}/{{cfg.user}} ] || mkdir -p /{{cfg.homemount}}/{{cfg.user}} && chown {{cfg.user}}:{{cfg.user}} /{{cfg.homemount}}/{{cfg.user}}
fi

# Exit the init hook if the id isn't setup on the server
if [ ! id {{cfg.user}} > /dev/null 2>&1 ]; then
  echo "Create user {{cfg.user}} before trying to load the service again"
  sleep 5
  exit 1
fi

# Create a log file

[ -e ${PROJECT_DIR}/caltec.log ] || su {{cfg.user}} -c "cat /dev/null > ${PROJECT_DIR}/caltec.log"


# set HOMEMOUNT Some of the servers have different homedirs some have /proj/.. and other have /home..

export HOMEMOUNT=`grep {{cfg.user}} /etc/passwd|cut -f 6 -d ':'|cut -f 2 -d '/'`

# Create .profile

[ -e /$HOMEMOUNT/{{cfg.user}}/.profile ] || su {{cfg.user}} -c "touch /$HOMEMOUNT/{{cfg.user}}/.profile"
[ -e ${PROJECT_DIR}/.profile ] || su {{cfg.user}} -c "touch /{{cfg.proj_dir}}/{{cfg.user}}/.profile"

# Create project directory if it does not exist, and set correct permissions

[ -d "${PROJECT_DIR}" ] || mkdir -p "${PROJECT_DIR}" && chown {{cfg.user}}:{{cfg.group}} "${PROJECT_DIR}"

#  Download Oracle client to {{pkg.path}} if it doesn't exist. 
#  Create oracle client directory, and a file to store application installation logs. Extract Oracle client 

[ -e {{pkg.path}}/ora*{{cfg.db.dbVersion}}tar.gz ] || wget --no-proxy --no-check-certificate -P {{pkg.path}} https://www.gsoutils.ford.com/files/credit/{{pkg.name}}/{{pkg.version}}/oracleclient{{cfg.db.dbVersion}}tar.gz
[ -d /{{cfg.proj_dir}}/{{cfg.db.client_dir}} ] || mkdir -p /{{cfg.proj_dir}}/{{cfg.db.client_dir}} 
[ -d /{{cfg.proj_dir}}/{{cfg.db.client_dir}} ]  && chown {{cfg.user}}:{{cfg.group}} /{{cfg.proj_dir}}/{{cfg.db.client_dir}}
[ -e /hab/pkgs/{{pkg.origin}} ] && chmod  755 /hab/pkgs/{{pkg.origin}}
[ -e /hab/pkgs/{{pkg.origin}}/{{pkg.name}} ] && chmod 755 /hab/pkgs/{{pkg.origin}}/{{pkg.name}}
[ -e /hab/pkgs/{{pkg.origin}}/{{pkg.name}} ] && chmod -R o+r /hab/pkgs/{{pkg.origin}}/{{pkg.name}}/*
[ -d /{{cfg.proj_dir}}/{{cfg.db.client_dir}}/product/{{cfg.db.dbVersion}} ] || timeout 150s su {{cfg.user}} -c "tar xkf {{pkg.path}}/ora*{{cfg.db.dbVersion}}tar.gz -C /{{cfg.proj_dir}}/{{cfg.db.client_dir}}" >> ${PROJECT_DIR}/caltec.log


# Change the oracle dir ownership to {{cfg.user}} 

[ `ls -ld /{{cfg.proj_dir}}/{{cfg.db.client_dir}}|cut -f3 -d ' '` == {{cfg.user}} ] || chown -R {{cfg.user}}:{{cfg.user}} /{{cfg.proj_dir}}/{{cfg.db.client_dir}} 

# Download binary if it does not exist.Set permissions on installer and package directories. Copy the application tar file to install slice

[ -d ${PROJECT_DIR}/tmp{{pkg.version}} ] || mkdir -p ${PROJECT_DIR}/tmp{{pkg.version}} && chown {{cfg.user}}:{{cfg.group}} ${PROJECT_DIR}/tmp{{pkg.version}}
[ -e {{pkg.path}}/{{cfg.inst_file}}*{{pkg.version}}.tar.gz ] || wget --no-proxy --no-check-certificate -P {{pkg.path}} https://www.gsoutils.ford.com/files/credit/{{pkg.name}}/{{pkg.version}}/"${CALTEC_BINARY}"
for d in  {4..7};do chmod 755 `echo {{pkg.path}}|cut -f1-$d -d '/'`;done
for d in `cat {{pkg.path}}/TDEPS`;do chmod 755 `echo /hab/pkgs/$d|cut -f1-5 -d '/'`;done
for d in `cat {{pkg.path}}/TDEPS`;do chmod 755 `echo /hab/pkgs/$d|cut -f1-6 -d '/'`;done
for d in `cat {{pkg.path}}/TDEPS`;do chmod 755 `echo /hab/pkgs/$d|cut -f1-7 -d '/'`;done
[ -d ${PROJECT_DIR}/tmp{{pkg.version}}/*{{pkg.version}}* ] || timeout 150s su {{cfg.user}} -c "tar xkf {{pkg.path}}/{{cfg.inst_file}}*{{pkg.version}}.tar.gz -C ${PROJECT_DIR}/tmp{{pkg.version}}" >> ${PROJECT_DIR}/caltec.log 
[ -d ${PROJECT_DIR}/tmp{{pkg.version}}/*{{pkg.version}}* ] || timeout 150s tar xkf {{pkg.path}}/{{cfg.inst_file}}*{{pkg.version}}.tar.gz -C ${PROJECT_DIR}/tmp{{pkg.version}} >> ${PROJECT_DIR}/caltec.log
[ -d ${PROJECT_DIR}/tmp{{pkg.version}}/*{{pkg.version}}* ] && chown -R {{cfg.user}}:{{cfg.user}} ${PROJECT_DIR}/tmp{{pkg.version}} >> ${PROJECT_DIR}/caltec.log


# Change ownership of toml files so that {{cfg.user}} user can update the files as needed

#[ -e {{pkg.path}}/default.toml ] && chown {{cfg.user}} {{pkg.path}}/*.toml

# Setup Install environment 

export INSTALL_DIR=`ls -d ${PROJECT_DIR}/tmp{{pkg.version}}/*{{pkg.version}}*|cut -d '/' -f5`
export CALLTECH_BASE=${PROJECT_DIR}

# Install dependencies

[ -e /usr/bin/bc ] || zypper install -y bc
[ -e /usr/bin/expect ] || zypper install -y expect

# Copy  tnsnames.ora 

[ -e {{pkg.svc_config_path}}/tnsnames.ora ] && [ ! -e /{{cfg.proj_dir}}/{{cfg.db.client_dir}}/product/{{cfg.db.dbVersion}}/{{cfg.db.client_number}}/network/admin/tnsnames.ora ] \
 && cp {{pkg.svc_config_path}}/tnsnames.ora /{{cfg.proj_dir}}/{{cfg.db.client_dir}}/product/{{cfg.db.dbVersion}}/{{cfg.db.client_number}}/network/admin/
[ -e /{{cfg.proj_dir}}/{{cfg.db.client_dir}}/product/{{cfg.db.dbVersion}}/{{cfg.db.client_number}}/network/admin/tnsnames.ora ] && \
               chown {{cfg.user}}:{{cfg.user}} /{{cfg.proj_dir}}/{{cfg.db.client_dir}}/product/{{cfg.db.dbVersion}}/{{cfg.db.client_number}}/network/admin/tnsnames.ora
[ -e ${PROJECT_DIR}/.viminfo ] ||  su {{cfg.user}} -c "touch ${PROJECT_DIR}/.viminfo"

if [ -e ${PROJECT_DIR}/`echo $INSTALL_DIR`/{{pkg.version}}/www/jre ]
 then grep JAVA_HOME /{{cfg.homemount}}/{{cfg.user}}/.profile ||\
  echo "export JAVA_HOME=${PROJECT_DIR}/{{pkg.version}}/www/jre" >> /{{cfg.homemount}}/{{cfg.user}}/.profile
fi

chown {{cfg.user}}:{{cfg.user}} /{{cfg.homemount}}/{{cfg.user}}/.profile

# Make {{cfg.user}} the owner of the config dir that conatins expect files ,tnsnames.ora set_dir.PL 

[ -d {{pkg.svc_config_path}} ] && chown -R {{cfg.user}} {{pkg.svc_config_path}}

# Check profiles in  /{{cfg.proj_dir}} and $HOMEMOUNT for existing caltech version

if grep ^CALLTECH_VERSION= /$HOMEMOUNT/{{cfg.user}}/.profile
   then export `grep ^CALLTECH_VERSION= /$HOMEMOUNT/{{cfg.user}}/.profile`
   else export CALLTECH_VERSION=0;
fi

if [ $CALLTECH_VERSION == 0 ] && [ -e ${PROJECT_DIR}/.profile ]
  then grep ^CALLTECH_VERSION= ${PROJECT_DIR}/.profile && export `grep ^CALLTECH_VERSION= ${PROJECT_DIR}/.profile`
fi

if [ $CALLTECH_VERSION == 0 ] && [ -e /$HOMEMOUNT/{{cfg.user}}/.profile ]
   then grep '^export CALLTECH_VERSION=' /$HOMEMOUNT/{{cfg.user}}/.profile && export `grep '^export CALLTECH_VERSION=' /$HOMEMOUNT/{{cfg.user}}/.profile|cut -f2-3 -d ' '`
fi

if [ $CALLTECH_VERSION == 0 ] && [ -e ${PROJECT_DIR}/.profile ]
   then grep '^export CALLTECH_VERSION=' ${PROJECT_DIR}/.profile && export `grep '^export CALLTECH_VERSION=' ${PROJECT_DIR}/.profile|cut -f2-3 -d ' '`
fi

# End of existing caltec version check

# Copy perl scripts to ${PROJECT_DIR}/tmp{{pkg.version}}/$INSTALL_DIR/{{pkg.version}}/common

[ -e {{pkg.svc_config_path}}/set_dirs.PL ] && su {{cfg.user}} -c "cp {{pkg.svc_config_path}}/set_dirs.PL ${PROJECT_DIR}/tmp{{pkg.version}}/$INSTALL_DIR/{{pkg.version}}/common"

### START VAULT CONFIG
# Run vault-config.sh if vault is enabled

#[ "{{cfg.vault.enabled}}" = true ] && /bin/bash "{{pkg.svc_config_path}}"/vault-config


if [ "{{cfg.vault.enabled}}" = true ]
  then
   echo "Vault enabled"
   export ROLE_NAME=fff
   export POLICY_NAME=ffff
   export SECRET_PATH=secret/fxxx

   if [ -z "{{cfg.vault.role-id}}" ] || [ -z "{{cfg.vault.secret-id}}" ]
    then
    echo "No vault secret ID or Role ID found in default toml.. Setting up vault"
    # Create a link for jq under /bin
    if [ ! -e /bin/jq ] 
    then  ls /hab/pkgs/`grep jq {{pkg.path}}/TDEPS`/bin|grep ^jq$ && ln -s /hab/pkgs/`grep jq {{pkg.path}}/TDEPS`/bin/jq /bin/jq
    fi
    export VAULT_ADDR="http://{{sys.ip}}:8200"
    export VAULT_TOKEN="$(curl --silent localhost:9631/services/vault/default/config | jq -r .token)"

    # Setup vault credentials and token
    /bin/bash "{{pkg.svc_config_path}}"/vault-setup
    export VAULT_TOKEN="$(curl --silent localhost:9631/services/vault/default/config | jq -r .token)"
    [ "$(vault status --format json | jq .sealed)" == true ] && exit 1
      
    else
    echo "Found Vault Role ID and Secret ID"
    export VAULT_ADDR="{{cfg.vault.address}}"
   fi
   
   # Copy toml file from {{pkg.svc_config_path}} to project space only if the file does not exist in proj space. Apply config from the toml file if the role/secret ids are found
   [ -e {{pkg.svc_config_path}}/user.toml ] && chown {{cfg.user}}  {{pkg.svc_config_path}}/user.toml
   [ -d {{pkg.svc_config_path}} ] && chmod 755 {{pkg.svc_config_path}}
   if [ ! -e ${PROJECT_DIR}/{{cfg.user}}.toml ] && [  -e {{pkg.svc_config_path}}/user.toml ]
    then su {{cfg.user}} -c "cp {{pkg.svc_config_path}}/user.toml ${PROJECT_DIR}/{{cfg.user}}.toml"
   fi
   if [ ! $(grep role-id ${PROJECT_DIR}/{{cfg.user}}.toml|cut -f2 -d '='|cut -f2 -d '"'|awk '{print length}') == 0 ] 
    then
     hab config apply caltec.default "$(date +%s)" ${PROJECT_DIR}/{{cfg.user}}.toml
     export VAULT_ADDR="{{cfg.vault.address}}"
    else
       hab config apply caltec.default "$(date +%s)" /hab/user/{{pkg.name}}/config/user.toml && echo "Applied /hab/user/{{pkg.name}}/config/user.toml"
       export VAULT_ADDR="http://$(curl --silent localhost:9631/services/vault/default | jq -r .sys.ip):$(curl --silent localhost:9631/services/vault/default/config | jq .listener.port)"
       export VAULT_TOKEN="$(curl --silent localhost:9631/services/vault/default/config | jq -r .token)"
   fi

   
   # Run vault-setup script to setup credentials on local vault if prod vault server is not configured

   if echo $VAULT_ADDR|grep ford
    then :
    else /bin/bash "{{pkg.svc_config_path}}"/vault-setup
   fi

   # Authenticate to vault

   export VAULT_APP_LOGIN=$(vault write auth/approle/login --format=json \
      role_id="{{cfg.vault.role-id}}" \
      secret_id="{{cfg.vault.secret-id}}") 

   vault write auth/approle/login --format=json \
      role_id="{{cfg.vault.role-id}}" \
      secret_id="{{cfg.vault.secret-id}}"

   if [ $? -ne 0 ]
    then
     export VAULT_APP_LOGIN=$(vault write auth/approle/login --format=json  \
     role_id=$(vault read --format "json" auth/approle/role/${ROLE_NAME}/role-id | \
     jq -r .data.role_id) secret_id=$(vault write -f --format "json" auth/approle/role/${ROLE_NAME}/secret-id |\
     jq -r .data.secret_id))
     
     vault write auth/approle/login --format=json  \
     role_id=$(vault read --format "json" auth/approle/role/${ROLE_NAME}/role-id | \
     jq -r .data.role_id) secret_id=$(vault write -f --format "json" auth/approle/role/${ROLE_NAME}/secret-id |\
     jq -r .data.secret_id)

     if [ $? -ne 0 ] 
      then export LOGINSTAT=false
      else export LOGINSTAT=true
     fi
   fi
   

   if [ "$(echo $LOGINSTAT)" == false ]; 
    then
     echo "Failed to authenticate with Vault"
     sleep 5
     echo "Failed to authenticate with vault. Configuring vault on local machine"
     [ "$(vault status --format json | jq .sealed)" == false ] && /bin/bash "{{pkg.svc_config_path}}"/vault-setup
     [ "$(vault status --format json | jq .sealed)" == true ] && exit 1

    else
     echo "Succesfully logged in to Vault"
     export VAULT_TOKEN=$(echo "${VAULT_APP_LOGIN}" | jq -r .auth.client_token)
   fi
   secrets=$(vault read -format json "{{cfg.vault.secret-path}}") 
   export DB_USERNAME=$(echo "${secrets}" | jq -r '.data["database-username"]')
   export DB_PASSWORD=$(echo "${secrets}" | jq -r '.data["database-password"]')
  
  else
   export DB_USERNAME="{{cfg.db.dbUser}}"
   export DB_PASSWORD="{{cfg.db.dbPassword}}"
fi


###END VAULT CONFIG

###CALTECH SOFTWARE INSTALL PART BEGINS


# Run Caltech installer only if it is a later version than the currently installed s/w, passing responses to its prompts (cannot run as root)


if [ $(echo {{pkg.version}}|cut -f 1-2 -d '.'|bc -l)  '>' $(echo $CALLTECH_VERSION|cut -f 1-2 -d '.'|bc -l) ] && [ $(echo {{pkg.version}}|cut -f 2-3 -d '.'|bc -l)  '>' $(echo $CALLTECH_VERSION|cut -f 2-3 -d '.'|bc -l) ]
 
 then
    
    export CALLTECH_VERSION={{pkg.version}}

    # Calltech Install scripts fails to create many directories. So, Creating them before running the Install script.
   
    export calltech_base=$CALLTECH_BASE
    for dir in `grep 'mkdir -p' ${PROJECT_DIR}/tmp{{pkg.version}}/$INSTALL_DIR/install.sh|grep '$calltech_base'|sed -e 's/^[ \t]*//'|cut -f3 -d ' '`
      do  su {{cfg.user}} -c "mkdir -p $dir"
      done
   
    # Run Prepare Upgarde script

    cd ${PROJECT_DIR}/tmp{{pkg.version}}/$INSTALL_DIR;
    [ -e /${PROJECT_DIR}/tmp{{pkg.version}}/$INSTALL_DIR/prepare_upgrade.sh ] && su {{cfg.user}} -c "/${PROJECT_DIR}/tmp{{pkg.version}}/$INSTALL_DIR/prepare_upgrade.sh"

    # Remove any  existing links between /home/{{cfg.user}}/*.profile  to {{cfg.proj_dir}}//{{cfg.user}}/*.profile 

    [ -L /$HOMEMOUNT/{{cfg.user}}/.profile ] && unlink /$HOMEMOUNT/{{cfg.user}}/.profile
    [ -L /$HOMEMOUNT/{{cfg.user}}/.bash_profile ] && unlink /$HOMEMOUNT/{{cfg.user}}/.bash_profile

    # Setup environment 
    
    export HOME=${PROJECT_DIR}
    export CALLTECH_HOME=$CALLTECH_BASE/$CALLTECH_VERSION
    export ORACLE_BASE=/{{cfg.proj_dir}}/{{cfg.db.client_dir}}/product/{{cfg.db.dbVersion}}
    export ORACLE_HOME=$ORACLE_BASE/{{cfg.db.client_number}}
    export LD_LIBRARY_PATH=`echo '${LD_LIBRARY_PATH}'`:`echo '${CALLTECH_HOME}'`/lib:`echo '${HOME}'`/lib:`echo '${HOME}'`/lib/lib:/usr/local/lib:`echo '${ORACLE_HOME}'`/lib:`echo '${ORACLE_HOME}'`/jdbc/lib
    export PATH=`echo '${CALLTECH_BASE}'`/bin:`echo '${CALLTECH_HOME}'`/bin:`echo '${ORACLE_HOME}'`:`echo '${ORACLE_HOME}'`/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/ccs/bin:/usr/ucb:`echo '${HOME}'`/bin:`echo '${HOME}'`/lib/bin:/{{cfg.proj_dir}}/{{cfg.user}}:/{{cfg.proj_dir}}/{{cfg.user}}/bin:`echo '${CALLTECH_HOME}'`/www/jre/bin
    #export PATH=${PATH}:`echo '${CALLTECH_BASE}'`/bin:`echo '${CALLTECH_HOME}'`/bin:`echo '${ORACLE_HOME}'`:`echo '${ORACLE_HOME}'`/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/ccs/bin:/usr/ucb:`echo '${HOME}'`/bin:`echo '${HOME}'`/lib/bin:/{{cfg.proj_dir}}/{{cfg.user}}:/{{cfg.proj_dir}}/{{cfg.user}}/bin:`echo '${CALLTECH_HOME}'`/www/jre/bin

   # Launch Installer. 

   # Install perl only  if the install date of the executable is older than 30 days

    if [ -e ${PROJECT_DIR}/perl/bin/perl ] 
    
    then
    
    [ $(expr `date +%s` - `stat -c %Y ${PROJECT_DIR}/perl/bin/perl`) -gt 2657290 ] && \

    su {{cfg.user}} -s /bin/sh -c "export PATH INSTALL_DIR LD_LIBRARY_PATH HOME ORACLE_HOME CALLTECH_BASE CALLTECH_HOME CALLTECH_VERSION;\
       cd /{{cfg.proj_dir}}/{{cfg.user}}/tmp{{pkg.version}}/$INSTALL_DIR;\
       expect {{pkg.svc_config_path}}/expect_{{pkg.version}}_install_launch_command_file" 
   
    fi
    
    #export PATH=${PATH}:`echo '${CALLTECH_BASE}'`/bin:`echo '${CALLTECH_HOME}'`/bin:`echo '${ORACLE_HOME}'`:`echo '${ORACLE_HOME}'`/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/ccs/bin:/usr/ucb:`echo '${HOME}'`/bin:`echo '${HOME}'`/lib/bin:/{{cfg.proj_dir}}/{{cfg.user}}:/{{cfg.proj_dir}}/{{cfg.user}}/bin:`echo '${CALLTECH_HOME}'`/www/jre/bin

    [ ! -e ${PROJECT_DIR}/perl/bin/perl ] && \

    su {{cfg.user}} -s /bin/sh -c "export PATH INSTALL_DIR LD_LIBRARY_PATH HOME ORACLE_HOME CALLTECH_BASE CALLTECH_HOME CALLTECH_VERSION;\
       cd /{{cfg.proj_dir}}/{{cfg.user}}/tmp{{pkg.version}}/$INSTALL_DIR;\
       expect {{pkg.svc_config_path}}/expect_{{pkg.version}}_install_launch_command_file" 



    # Exit if the above command fails and a perl execuatable is not found in ${PROJECT_DIR}/perl/bin
    
    if [ ! $? -eq 14 ] && [ ! -e "${PROJECT_DIR}"/perl/bin/perl ] 
     then echo -e "Perl Install failed. Aborting"
     exit
     else echo -e "\nPerl Installation complete" >> ${PROJECT_DIR}/caltec.log
     
    fi
  
  
    # Create bin directory in "${PROJECT_DIR}" and "${HOMEMOUNT}". Create link to perl executable

    [ -d "${PROJECT_DIR}"/bin ] || su {{cfg.user}} -c "mkdir ${PROJECT_DIR}/bin"
    [ -d /"${HOMEMOUNT}"/{{cfg.user}}/bin ] || su {{cfg.user}} -c "mkdir /${HOMEMOUNT}/{{cfg.user}}/bin"

    if [ -e "${PROJECT_DIR}"/perl/bin/perl ] 
     then  
     [ -e "${PROJECT_DIR}"/bin/perl ]  || su {{cfg.user}} -c "ln -s ${PROJECT_DIR}/perl/bin/perl ${PROJECT_DIR}/bin/perl"
     [ -e /"${HOMEMOUNT}"/{{cfg.user}}/bin/perl ]  || su {{cfg.user}} -c "ln -s ${PROJECT_DIR}/perl/bin/perl /${HOMEMOUNT}/{{cfg.user}}/bin/perl"
    fi


    # Install all Modules. Menu item #1

    su {{cfg.user}} -p -s /bin/sh -c "export PATH INSTALL_DIR LD_LIBRARY_PATH HOME ORACLE_HOME CALLTECH_BASE CALLTECH_HOME CALLTECH_VERSION;\
       cd /{{cfg.proj_dir}}/{{cfg.user}}/tmp{{pkg.version}}/$INSTALL_DIR;\
       expect {{pkg.svc_config_path}}/expect_{{pkg.version}}_install_modules_command_file" 
  
    # Menu Item #1 (Module Installation) may fail at times. The follwing code will attempt to re-run the  install once more  
    
    if [ $? -eq 15 ] 
 
      then echo -e "\nSome of the modules have generated errors during install. Attempting to install them again" >> ${PROJECT_DIR}/caltec.log
      echo "Restarting Module Install"
      su {{cfg.user}} -p -s /bin/sh -c "export PATH INSTALL_DIR LD_LIBRARY_PATH HOME ORACLE_HOME CALLTECH_BASE CALLTECH_HOME CALLTECH_VERSION;\
        cd /{{cfg.proj_dir}}/{{cfg.user}}/tmp{{pkg.version}}/$INSTALL_DIR;\
        expect {{pkg.svc_config_path}}/expect_{{pkg.version}}_install_modules_command_file" 
      
       # Exit the Install program if the second attept to install modules also fails
    
      if [ $? -eq 15 ]
        then echo -e "\nModule Installation failed.. Not trying again.." >> ${PROJECT_DIR}/caltec.log
        echo "Exiting Install"
        export INST_STATUS=Fail
        exit

        else echo -e "\nModule Installation complete" >> ${PROJECT_DIR}/caltec.log
      fi
     
    elif [ $? -eq 17 ]
      then echo -e "\nModule Installation complete" >> /{{cfg.proj_dir}}/{{cfg.user}}/caltec.log
      
    fi


    # Arguements for use inside expect. Start with empty string, delimit arguments with spaces
    #ARGUMENTS=""
    # Argument 0: Database Superusuer
    #ARGUMENTS+=" ${DB_USERNAME}"
    # Argument 1: Database Superuser Password
    #ARGUMENTS+=" ${DB_PASSWORD}"

    #echo $ARGUMENTS


   # Installl Database. Menu item #3
  
    su {{cfg.user}} -p -s /bin/sh -c "export PATH INSTALL_DIR LD_LIBRARY_PATH HOME ORACLE_HOME CALLTECH_BASE CALLTECH_HOME \
        CALLTECH_VERSION DB_USERNAME DB_PASSWORD;\
        cd /{{cfg.proj_dir}}/{{cfg.user}}/tmp{{pkg.version}}/$INSTALL_DIR;\
        expect {{pkg.svc_config_path}}/expect_{{pkg.version}}_Simple_Ora_command_file" 
    echo -e "\nOracle setup using expect scipt is complete."


    # CallTech Server Installation (Menu item #5)

    su  {{cfg.user}} -p -s /bin/sh -c "export PATH INSTALL_DIR LD_LIBRARY_PATH HOME ORACLE_HOME CALLTECH_BASE CALLTECH_HOME CALLTECH_VERSION;\
        cd /{{cfg.proj_dir}}/{{cfg.user}}/tmp{{pkg.version}}/$INSTALL_DIR;\
        expect {{pkg.svc_config_path}}/expect_{{pkg.version}}_installCT_command_file" 
    echo -e "\nCallTech Server install using expect script is complete."

    # Create .ctrc.enc
    
    if [ ! -e /{{cfg.proj_dir}}/{{cfg.user}}/.ctrc.enc ]
    then
      su  {{cfg.user}} -p -c "export PATH INSTALL_DIR LD_LIBRARY_PATH HOME ORACLE_HOME CALLTECH_BASE CALLTECH_HOME CALLTECH_VERSION;\
      cd $CALLTECH_HOME/bin;$CALLTECH_HOME/bin/set_db_login -t {{cfg.caltec.dbtype}} -s {{cfg.devdb.fqdn}} -u {{cfg.devdb.dbUser}} -p {{cfg.devdb.dbPort}} -S {{cfg.devdb.sid}} -P {{cfg.devdb.dbPassword}}" 
    fi
    
    # Run finish Upgarde script

    su {{cfg.user}} -p -c "source /{{cfg.proj_dir}}/{{cfg.user}}/.profile;export INSTALL_DIR;cd ${PROJECT_DIR}/tmp{{pkg.version}}/$INSTALL_DIR;${PROJECT_DIR}/tmp{{pkg.version}}/$INSTALL_DIR/finish_upgrade.sh"
   
    # Install crontab and allow the user write access to crontab

    [ -e /var/spool/cron/tabs/{{cfg.user}} ] || cp {{pkg.svc_config_path}}/crontab /var/spool/cron/tabs/{{cfg.user}}
    [ -e /var/spool/cron/tabs/{{cfg.user}} ] && chown {{cfg.user}} /var/spool/cron/tabs/{{cfg.user}}
    if grep {{cfg.user}} /etc/cron.allow; then :;else echo {{cfg.user}} >> /etc/cron.allow;fi

    # Add environment variables to /home/{{cfg.user}}/.profile, /home/{{cfg.user}}/.bash_profile and /proj/{{cfg.user}}/.profile


    for f in /$HOMEMOUNT/{{cfg.user}}/.profile /$HOMEMOUNT/{{cfg.user}}/.bash_profile ${PROJECT_DIR}/.profile
     do
      if [ -e $f ]
       then
        grep '^export HOME=' $f || echo "export HOME=/{{cfg.proj_dir}}/{{cfg.user}}" >> $f
        grep '^CALLTECH_BASE=' $f && sed -i  '/^CALLTECH_BASE=/d' $f
        grep '^export CALLTECH_BASE=' $f && sed -i  '/^export CALLTECH_BASE=/d' $f
        grep '^export CALLTECH_BASE=' $f || echo "export CALLTECH_BASE=/{{cfg.proj_dir}}/{{cfg.user}}" >> $f
        grep '^export CALLTECH_VERSION' $f && sed -i  '/^export CALLTECH_VERSION=/d' $f
        grep '^CALLTECH_VERSION=' $f && sed -i  '/^CALLTECH_VERSION=/d' $f
        grep '^export CALLTECH_VERSION=' $f || echo "export CALLTECH_VERSION={{pkg.version}}" >> $f
        grep '^CALLTECH_HOME=' $f && sed -i  '/^CALLTECH_HOME=/d' $f
        grep '^export CALLTECH_HOMEE=' $f && sed -i  '/^export CALLTECH_HOME=/d' $f
        echo "export CALLTECH_HOME=`echo '${CALLTECH_BASE}'`/`echo '${CALLTECH_VERSION}'`" >> $f
        grep '^export ORACLE_BASE=' $f && sed -i  '/^export ORACLE_BASE=/d' $f
        grep '^export ORACLE_BASE=' $f || echo "export ORACLE_BASE=/{{cfg.proj_dir}}/{{cfg.db.client_dir}}/product/{{cfg.db.dbVersion}}" >> $f
        grep '^export ORACLE_HOME=' $f && sed -i  '/^export ORACLE_HOME=/d' $f
        grep '^export ORACLE_HOME=' $f || echo "export ORACLE_HOME=/{{cfg.proj_dir}}/{{cfg.db.client_dir}}/product/{{cfg.db.dbVersion}}/{{cfg.db.client_number}}" >> $f
        grep '^export LD_LIBRARY_PATH=' $f && sed -i  '/^export LD_LIBRARY_PATH=/d' $f
        grep '^LD_LIBRARY_PATH=' $f && sed -i  '/^LD_LIBRARY_PATH=/d' $f
        grep '^export LD_LIBRARY_PATH=' $f || echo "export LD_LIBRARY_PATH=`echo '${CALLTECH_HOME}'`/lib:`echo '${HOME}'`/lib:`echo '${HOME}'`/lib/lib:/usr/local/lib:`echo '${ORACLE_HOME}'`/lib:`echo '${ORACLE_HOME}'`/jdbc/lib" >> $f
        grep '^export PATH=' $f && sed -i  '/^export PATH=/d' $f
        grep '^PATH=' $f && sed -i  '/^PATH=/d' $f
        echo "export PATH=`echo '${CALLTECH_BASE}'`/bin:`echo '${CALLTECH_HOME}'`/bin:`echo '${ORACLE_HOME}'`:`echo '${ORACLE_HOME}'`/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/ccs/bin:/usr/ucb:`echo '${HOME}'`/bin:/usr/lib:`echo '${HOME}'`/lib/bin:/{{cfg.proj_dir}}/{{cfg.user}}:/{{cfg.proj_dir}}/{{cfg.user}}/bin:`echo '${CALLTECH_HOME}'`/www/jre/bin" >> $f
        grep '^source /' $f && sed -i  '/^source /d' $f
        grep '^cd $HOME' $f || echo 'cd $HOME' >> $f
        grep '^export PS1='  $f || echo 'export PS1=[\\u@\\h:\\w]\> ' >> $f
        grep '^ORACLE_SID=' $f && sed -i  '/^ORACLE_SID=/d' $f
        grep '^export ORACLE_SID=' $f && sed -i  '/^export ORACLE_SID=/d' $f
        grep '^export ORACLE_SID=' $f || echo "export ORACLE_SID={{cfg.devdb.sid}}" >> $f
     fi
    done
    

 else echo -e "The Caltech installer is either the same or an earlier version than the one found on the server. Skipping installation..."

fi

## Install section END here

# Change permissions on log file

[ `stat -c "%U" /{{cfg.proj_dir}}/{{cfg.user}}/caltec.log` == {{cfg.user}} ] || chown {{cfg.user}} ${PROJECT_DIR}/caltec.log

# Setup environment and start WebServices

export HOME=${PROJECT_DIR}
export CALLTECH_BASE=${PROJECT_DIR}
export CALLTECH_VERSION={{pkg.version}}
export CALLTECH_HOME=$CALLTECH_BASE/$CALLTECH_VERSION
su - {{cfg.user}} -c "cd $CALLTECH_HOME/bin;$CALLTECH_HOME/bin/ctWebServices status|grep 'is running'||$CALLTECH_HOME/bin/ctWebServices start >> ${PROJECT_DIR}/caltec.log"
