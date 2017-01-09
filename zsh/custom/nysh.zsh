#!/bin/bash

# För färger Se http://misc.flogisoft.com/bash/tip_colors_and_formatting

## Local functions

## builtin cd
oscd() {
  builtin cd $1
}

## Alternative cd
cdWithNypsCheck() {
  pushd "$1" > /dev/null;
  local dir=$(pwd)
  local closestNypsRoot=$(findClosestNypsRoot $dir)
  if [ "$NYPS2020_SHELL" != "" ] && ( ! isNypsRoot $closestNypsRoot || [ "$closestNypsRoot" != "$NYPS2020_ROOT" ] ); then
    unset NYPS2020_SHELL
    . ~/.zshrc
    return 0;
  elif isNypsRoot $closestNypsRoot && [ "$NYPS2020_SHELL" = "" ]; then
    . ~/.zshrc
    return 0;
  fi
}

function cd() {
  if [ "$#" = "0" ]; then
    pushd ${HOME} > /dev/null;
  elif [ -f "${1}" ]; then
    ${EDITOR} ${1};
  else
    cdWithNypsCheck $1;
  fi
}

function bd(){
  if [ "$#" = "0" ];  then
    popd > /dev/null
  else
    for i in $(seq ${1})
    do
      popd > /dev/null
    done
  fi
}

## Check if the current directory is a nyps root
isNypsRoot() {
  local root;
  if [ "" = "$1" ]; then
    root=$(pwd);
  else
    root=$1;
  fi

  if [ "" = "${root}" ] || [ ! -f "${root}/pom.xml" ] || ! grep -q "<name>Nyps 2020</name>" ${root}/pom.xml; then
    return 1;
  else
    return 0;
  fi

}

## Find the closest Nyps root (current dir or parents)
findClosestNypsRoot() {
  local dir=$1
  if [ "$dir" = "" ]; then
    dir=$(pwd)
  fi
  dir=$(oscd $dir; echo $(pwd))

  if [ "$dir" = "/" ]; then
    echo "NYPS_ROOT_NOT_FOUND";
  elif isNypsRoot $dir ; then
    echo $dir
  else
    echo $(findClosestNypsRoot $(oscd "$dir/.."; echo $(pwd)))
  fi
}

## Show shell banner
showBanner() {
  echo -e "\e[32m    _   __                    _____ __         ____"
  echo -e "\e[32m   / | / /_  ______  _____   / ___// /_  ___  / / /"
  echo -e "\e[32m  /  |/ / / / / __ \/ ___/   \__ \/ __ \/ _ \/ / / "
  echo -e "\e[32m / /|  / /_/ / /_/ (__  )   ___/ / / / /  __/ / /  "
  echo -e "\e[32m/_/ |_/\__, / .___/____/   /____/_/ /_/\___/_/_/   "
  echo -e "\e[32m      /____/_/                                     "
  echo ""
  echo -e "\e[32mIn GIT clone @ $closestNypsRoot\e[0m"
}

## Setup all aliases
setup-nyps2020-aliases() {
  local root=$1
  if [ "" = "$root" ]; then
    echo "1st argument must specify the git clone of nyps2020"
    return 1;
  fi
  export NYPS2020_ROOT=$1
  export NEO_HOME=$NYPS2020_ROOT/appl/fe.appl/neoclient.fe.appl
  export MANGA_HOME=$NYPS2020_ROOT/appl/fe.appl/manga.fe.appl
  export MAMOCK_HOME=$NYPS2020_ROOT/appl/fe.appl/ma-mock.fe.appl

  alias mvn="mvn -T 1C -Dmaven.repo.local=$root/m2repo";
  alias mvnq="mvn -o -DskipTests -P-include-fe"

  #NYPS2020
  alias cdnyps="oscd $NYPS2020_ROOT"
  alias nyps-build-slow-test="mvnq install -o -T 1C -Pslow-test,-include-fe -f $NYPS2020_ROOT/pom.xml"
  alias nyps-client="bash -c 'cd $NEO_HOME && npm start '"

  alias nyps-build-be-ear="mvnq -am -pl appl/be.appl/ear.be.appl -DskipTests"
  alias nyps-build-deploy="mvnq install -DskipTests -f common && mvn -DskipTests -f $NYPS2020_ROOT/appl/be.appl/pom.xml install -Pdeploy"
  alias nyps-deploy="mvnq wildfly:deploy -f $NYPS2020_ROOT/appl/be.appl/ear.be.appl"
  alias nyps-deploy-client="mvnq -f $NYPS2020_ROOT/appl/fe.appl/neoclient.fe.appl/pom.xml wildfly:deploy"

  # MANGA
  alias manga-client="bash -c 'cd $MANGA_HOME && npm start '"
  alias manga-build-deploy="mvnq install -DskipTests -f common && mvn -DskipTests -f $NYPS2020_ROOT/appl/myapp-be.appl/pom.xml install -Pdeploy"
  alias manga-deploy="mvnq wildfly:deploy -f $NYPS2020_ROOT/appl/myapp-be.appl/ear.myapp-be.appl"

  # MAMOCK
  alias mamock-client="bash -c 'cd $MAMOCK_HOME && grunt serve --open-page=false  --proxy-be=true '"
  alias mamock-deploy="mvnq clean wildfly:deploy -f $NYPS2020_ROOT/appl/myapp-ma-mock.appl"

  # AD-SYNC
  alias adsync-deploy="mvnq wildfly:deploy -f $NYPS2020_ROOT/appl/adsync.appl/ear.adsync.appl/"

  # MISC
  alias nyps-build-all="mvnq clean install -DskipTests -P-include-fe -f $NYPS2020_ROOT/pom.xml"
  alias nyps-deploy-all="nyps-be-build-deploy && manga-be-build-deploy && mamock-be-build-deploy"
  alias nyps-deploy-adsync="mvnq -f $NYPS2020_ROOT/appl/adsync.appl/pom.xml install -Pdeploy"
  alias nyps-deploy-eco="mvnq -f $NYPS2020_ROOT/appl/ecoint-be.appl/ear.ecoint-be.appl/pom.xml install -Pdeploy"

  alias nyps-wildfly-start-alt="export JAVA_HOME='/Library/Java/JavaVirtualMachines/jdk1.8.0_92.jdk/Contents/Home';export JAVA_OPTS='$JAVA_OPTS -XXaltjvm=dcevm'; $NYPS2020_ROOT/tool/as.tool/wildfly.as.tool/target/server/wildfly-10.0.0.Final/bin/standalone.sh"
  alias nyps-wildfly-start="$NYPS2020_ROOT/tool/as.tool/wildfly.as.tool/target/server/wildfly-10.0.0.Final/bin/standalone.sh"
  alias nyps-wildfly-rebuild="export JAVA_HOME='/Library/Java/JavaVirtualMachines/jdk1.8.0_92.jdk/Contents/Home';mvnq -f $NYPS2020_ROOT/tool/as.tool/pom.xml clean install -P setup-wildfly;$NYPS2020_ROOT/tool/as.tool/wildfly.as.tool/target/server/wildfly-10.0.0.Final/bin/add-user.sh --user admin --password admin123"

  alias nyps-smartdocuments-test-configuration="echo exit | sqlplus64 nyps2020_local/utv888@oraexp/XE @$NYPS2020_ROOT/etc/sqlplus/set-nyps-smartdocuments-configuration.sql 'https://sdtest.tillvaxtverket.se/' 'userid' 'password'"
  alias nyps-inttest="mvnq -f $NYPS2020_ROOT/test/service-int.test/ clean verify -Pint-test"
  alias nyps-migrate="mvnq -f $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl clean compile flyway:migrate"
  alias manga-migrate="mvnq -f $NYPS2020_ROOT/appl/tool.appl/myapp-db-migration.tool.appl clean compile flyway:migrate"

  alias db-start="db-run $db_name";
  alias db-clear="docker rm -f $db_name";
  alias db-reset="db-clear && db-start && db-up";
  alias db-up="db-wait-up $db_name";

  alias docker-refresh="docker pull capulet.tillvaxtverket.se:18078/nyps2020-db:v9.0.0-latest"
  alias get2020root="echo $NYPS2020_ROOT"
}

db-run() {
  container_name=$1;
  if [ "" = "$container_name" ]; then
    container_name="oraexp"
  fi

  echo "Run DB container: $container_name"

  docker run -d --shm-size=2G --name $container_name -p 1521:1521 capulet.tillvaxtverket.se:18078/nyps2020-db:v9.0.0-latest
}

db-wait-up() {
  local container_name=$1;
  if [ "" = "$container_name" ]; then
    echo "Usage: db-wait-up <container name>"
    return 1;
  fi

  dots="";
  echo -en "Wait for Oracle to start";
  while true; do
    up=`docker exec -it ${container_name} /bin/bash -c 'echo "SELECT COUNT(*) FROM HR.EMPLOYEES;" | /u01/app/oracle/product/11.2.0/xe/bin/sqlplus sys/utv888 as sysdba'`;
    if [[ "$up" =~ '.*ERROR.*' ]]; then
      echo -en "${dots}"
      dots="${dots}."
    else
      echo "\nOraexp has started!"
      return;
    fi
    sleep 5
  done;
}

## Start the Nyps Shell
nysh() {
  local root;
  if [ "" = "$1" ]; then
    root=$(pwd);
  else
    root=$1;
  fi
  root=$(oscd $root;pwd); # expand path
  local closestNypsRoot=$(findClosestNypsRoot $root)

  if [ "$closestNypsRoot" = "NYPS_ROOT_NOT_FOUND" ]; then
    echo "Could start Nyps Shell since ny valid Nyps root was found in this directory or in any of its parents. Bailing...";
    return 1;
  fi

  if ! isNypsRoot $closestNypsRoot ; then
    echo "Usage: nysh <NYPS2020 git root directory>"
    return 2;
  fi

  db_name="oraexp-$(basename $closestNypsRoot)"

  echo "Starting Nyps shell in ${closestNypsRoot}"
  setup-nyps2020-aliases $closestNypsRoot;

  oscd $root;
  clear

  ZSH_THEME="nysh"
  NYPS2020_SHELL="ACTIVE"
  showBanner
}

################
##    main    ##
################

local closestNypsRoot=$(findClosestNypsRoot)
if [ "$closestNypsRoot" != "NYPS_ROOT_NOT_FOUND" ] ; then
  nysh
fi
