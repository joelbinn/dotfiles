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
  export MAMOCK_HOME=$NYPS2020_ROOT/appl/fe.appl/mammut.fe.appl

  alias mvn="mvn-color -T 1C -Dmaven.repo.local=$root/m2repo";
  alias nymvn="mvn-color -T 1C -Dmaven.repo.local=$root/m2repo";
  alias mvnq="nymvn -Dmaven.repo.local=$root/m2repo -DskipTests"
  alias mvn-nofe="mvnq -P-include-fe"
  alias bld="nymvn -pl $(changed-mvn-projects)"
  alias bldq="nymvn -o -DskipTests -pl $(changed-mvn-projects)"

  # NYPS2020
  alias cdnyps="oscd $NYPS2020_ROOT"
  alias nyps-client="bash -c 'oscd $NEO_HOME && npm run start-neo'"
  alias nyps-build-ear="oscd $NYPS2020_ROOT ; mvnq install -am -pl :ear.be.appl; oscd -"
  alias nyps-be-deploy="oscd $NYPS2020_ROOT ; mvnq -pl :ear.be.appl wildfly:deploy ; oscd -"
  alias nyps-build-ear-deploy="nyps-build-ear && nyps-be-deploy"
  alias nyps-fe-deploy="oscd $NYPS2020_ROOT ; mvnq -pl :neoclient-war.fe.appl wildfly:deploy ; oscd -"

  # MANGA
  alias manga-client="bash -c 'oscd $NEO_HOME && npm run start-manga'"
  alias manga-build-ear="oscd $NYPS2020_ROOT ; mvnq install -pl :ear.myapp-be.appl -am ; oscd -"
  alias manga-be-deploy="oscd $NYPS2020_ROOT ; mvnq -pl :ear.myapp-be.appl wildfly:deploy ; oscd -"
  alias manga-build-ear-deploy="manga-build-ear && manga-be-deploy"
  alias manga-fe-deploy="oscd $NYPS2020_ROOT ; mvnq -pl :manga-war.fe.appl wildfly:deploy ; oscd -"

  # MA2020
  alias ma2020-client="bash -c 'oscd $NEO_HOME && npm run start-ma2020'"
  alias ma2020-build-ear="oscd $NYPS2020_ROOT ; mvnq install -pl :ear.ma2020-be.appl -am ; oscd -"
  alias ma2020-be-deploy="oscd $NYPS2020_ROOT ; mvnq -pl :ear.ma2020-be.appl wildfly:deploy ; oscd -"
  alias ma2020-build-ear-deploy="ma2020-build-ear && ma2020-be-deploy"
  alias ma2020-fe-deploy="oscd $NYPS2020_ROOT ; mvnq -pl :ma2020client-war.fe.appl wildfly:deploy ; oscd -"

  # INTEGRATION
  alias integration-deploy="oscd $NYPS2020_ROOT ; mvnq install -pl :ear.integration.appl -am; mvnq wildfly:deploy -pl :ear.integration.appl && oscd -"

  # TEST TOOLS + MAMMUT
  alias mamock-be-deploy="oscd $NYPS2020_ROOT ; mvnq -pl :myapp-ma-mock.appl wildfly:deploy ; oscd -"
  alias mammut-client="bash -c 'oscd $MAMOCK_HOME && npm run start'"
  alias mammut-deploy="oscd $NYPS2020_ROOT ; mvnq -pl :mammut.fe.appl wildfly:deploy ; oscd -"
  alias nyps-test-tool-deploy="oscd $NYPS2020_ROOT ; mvnq install wildfly:deploy -pl :dbtools.testsupport.test,:be-service-test-app-war.fe.appl ; oscd -"

  # MISC
  alias nyps-clean-build-all="mvnq clean install -f $NYPS2020_ROOT/pom.xml"
  alias nyps-build-all="mvnq install -f $NYPS2020_ROOT/pom.xml"
  alias nyps-deploy-all="nyps-build-all && nyps-be-deploy && manga-be-deploy && mammut-deploy && ma2020-be-deploy"

  alias nyps-migrate="oscd $NYPS2020_ROOT ; mvnq -pl :db-migration.tool.appl clean compile flyway:repair flyway:migrate ; oscd -"
  alias nyps-build-migrate="oscd $NYPS2020_ROOT ; mvnq -pl :db-migration.tool.appl -am clean compile ; nyps-migrate ; oscd -"
  alias get2020root="echo $NYPS2020_ROOT"

  alias nyps-alias-reload="source ~/.zshrc ; oscd / ; oscd -;"

  alias nyps-dkr-attach="oscd  $NYPS2020_ROOT ; source devEnvAttach.sh ; oscd -"
  alias nyps-dkr-detach="oscd  $NYPS2020_ROOT ; source devEnvDetach.sh ; oscd -"
  alias nyps-dkr-start="oscd  $NYPS2020_ROOT ; source devEnvStart.sh ; oscd -"
  alias nyps-dkr-remove="oscd  $NYPS2020_ROOT ; source devEnvRemove.sh ; oscd -"
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

  nypsRoot=$(basename $(findClosestNypsRoot));
  closestNypsRootName=$(echo $nypsRoot:l | sed 's/[@_-]//g');
  db_name="${closestNypsRootName}_oraexp_1";
  codeContainerName="${closestNypsRootName}_code_1";

  echo "Starting Nyps shell in ${closestNypsRoot}"
  setup-nyps2020-aliases $closestNypsRoot;

  oscd $root;
  clear

  ZSH_THEME="nysh"
  #ZSH_THEME="agnoster"
  NYPS2020_SHELL="ACTIVE"
  showBanner
}

################
##    main    ##
################

local closestNypsRoot=$(findClosestNypsRoot)
if [ "$closestNypsRoot" != "NYPS_ROOT_NOT_FOUND" ] ; then
  nysh $closestNypsRoot
else
  echo "Hittade ingen nypsrot"
fi
