. `/usr/local/bin/brew --prefix`/etc/profile.d/z.sh

# Make sure locale is correct
export LANG=sv_SE.UTF-8
export LC_ALL=$LANG

# User configuration
#export ORACLE_HOME=$NYPS2020_ROOT/etc/sqlplus/instantclient/macosx_64
#export TNS_ADMIN=$ORACLE_HOME
#export DYLD_LIBRARY_PATH=$ORACLE_HOME:$DYLD_LIBRARY_PATH
export NLS_LANG=SWEDISH_SWEDEN.UTF8
#PATH=$PATH:$ORACLE_HOME

export PROJ_DISK=/Volumes/projects-40g
export PROJSTUFF=$PROJ_DISK/projectstuff
#export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
export JAVA_HOME=/usr/local/jdk
export PATH=$PATH:$HOME/.cabal/bin
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$PATH:/opt/local/bin:/opt/local/sbin:$JAVA_HOME/bin:.:/bin:/usr/bin:/usr/sbin:/sbin:/opt/X11/bin:/usr/local/git/bin
export PATH=./node:./node_modules/.bin:$PATH
export JAVA_TOOL_OPTIONS='-Djava.awt.headless=true'
export REBEL_HOME=$HOME/verktyg/jrebel
export NYPS_WILDFLY_OPTS="-XXaltjvm=dcevm"

export MAVEN_OPTS="$MAVEN_OPTS -Djava.awt.headless=true"
DIR="$( cd "$( dirname "$0" )" && pwd )"

echo "Initialize Joel's patches..."
. $DIR/computer-specific

echo "Initialize Joel's common environment variables..."
export ip_address=`ifconfig ${NIC} | awk '/inet/ {print $2}' |  grep -e "\." `
echo " -> ip_address=$ip_address"
export EXTERNAL_IP_ADDRESS=$ip_address
echo " -> EXTERNAL_IP_ADDRESS=$EXTERNAL_IP_ADDRESS"
# export DOCKER_HOST=tcp://localhost:4243
# echo " -> DOCKER_HOST=$DOCKER_HOST"
export TNS_ADMIN=~/.tnsadmin

# Docker init
eval "$(docker-machine env default)"

function server() {
        python -m SimpleHTTPServer "8989"
}

if [ -z "\${which tree}" ]; then
  tree () {
      find $@ -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'
  }
fi

mcd () {
    mkdir "$@" && cd "$@"
}

db-dump-fetch() {
  dumpfile=$1
  src="jenkins@capulet:db-dump"
  if [ "" != "$3" ]; then
    src=$3;
  fi
  dest="dev_db.dmp";
  if [ "" != "$2" ]; then
    dest=$2;
  fi

  echo "copy $src/$dumpfile -> oracle@oraexp:/rman/dpdir/XE/$dest";
  # echo "copy $src/$dumpfile -> oraexp:/u01/app/oracle/admin/XE/dpdump/$dest";
  if [ "" != "$dumpfile" ]; then
      scp $src/$dumpfile .;
      if [[ $? -eq 0 ]]; then
          scp ./$1 oracle@oraexp:/rman/dpdir/XE/$dest;
          # chmod 744 ./$1;
          # docker cp ./$1 oraexp:/u01/app/oracle/admin/XE/dpdump/$dest;
          rm ./$1
          return 0;
      else
          return 2;
      fi
  else
      return 1;
  fi
}

db-dump-copy-all() {
  usage="usage: db-dump-copy-all <date> <ver> <only-nyps>, e.g db-dump-copy-all 160411 7.0.2"
  date=$1
  ver=$2
  onlynyps=$3

  if [ "" = "$date" ] || [ "" = "$ver" ]; then
    echo $usage;
    return;
  fi

  src_nyps_dump="NYPS2020_LOCAL_${date}_prod_v${ver}_dummy_documents.dmp"
  # src_nyps_dump="NYPS2020_LOCAL_${date}_prod_v${ver}_dummy_documents_nn_cases.dmp"
  src_manga_dump="NYPS2020_MIN_LOCAL_${date}_prod_v${ver}_dummy_documents.dmp"
  echo "copying ${src_nyps_dump} and ${src_manga_dump}"
  db-dump-fetch $src_nyps_dump "dev_db_nyps.dmp"
  if [ "" = "$onlynyps" ]; then
    db-dump-fetch $src_manga_dump "dev_db_manga.dmp"
  fi
}

db-reload-no-migrate() {
    ssh oracle@oraexp 'bash db_import_test_dump.sh -s XE  -u NYPS2020_LOCAL -p utv888 -f dev_db_nyps.dmp';
    ssh oracle@oraexp 'bash db_import_test_dump_manga.sh -s XE -u NYPS2020_MIN_LOCAL -p utv888  -w -f dev_db_manga.dmp';
}

db-reload() {
    ssh oracle@oraexp 'bash db_import_test_dump.sh -s XE  -u NYPS2020_LOCAL -p utv888 -f dev_db_nyps.dmp';
    # docker exec -it -u oracle oraexp /bin/bash -c 'bash db_import_test_dump.sh -s XE  -u NYPS2020_LOCAL -p utv888 -f dev_db_nyps.dmp';
    #docker exec -it oraexp /u01/app/oracle/product/11.2.0/xe/bin/impdp oraload/utv888 dumpfile=dev_db_nyps.dmp remap_schema=ORALOAD:NYPS2020_LOCAL
    mvn clean install flyway:migrate -f $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/pom.xml;
    ssh oracle@oraexp 'bash db_import_test_dump_manga.sh -s XE -u NYPS2020_MIN_LOCAL -p utv888  -w -f dev_db_manga.dmp';
    #docker exec -it -u oracle oraexp /bin/bash -c 'bash db_import_test_dump_manga.sh -s XE -u NYPS2020_MIN_LOCAL -p utv888  -w -f dev_db_manga.dmp';
    mvn clean install flyway:migrate -f $NYPS2020_ROOT/appl/tool.appl/myapp-db-migration.tool.appl/pom.xml;
}

db-ls-dumps() {
    ssh jenkins@capulet 'ls -altr -1 ~/db-dump/NYPS2020*';
}

pwcrt-start() {
    pushd $PROJ_DISK/projectstuff/myown/pwcrt/dist;
    node server.js &;
    popd;
}



# NYA DOCKER DB KOMMANDON
db-dump-to-docker-oraexp() {
  dumpfile=$1
  schema=$2
  src="jenkins@capulet:db-dump"

  if [ "" != "$dumpfile" ] && [ "" != "$schema" ]; then
      oraexpDestination="/u01/app/oracle/admin/XE/dpdump/$dumpfile";
      dumpExists=$(eval "docker exec -it oraexp /bin/bash -c 'if [ -f ${oraexpDestination} ]; then echo yes; fi;'");
      if [ "$dumpExists" != "" ]; then
          echo "Dump $dumpfile already exists on oraexp";
      else
          echo "copy $src/$dumpfile -> oraexp:$oraexpDestination";
          echo "scp $src/$dumpfile /tmp/$dumpfile"
          scp $src/$dumpfile /tmp/$dumpfile;
          echo "docker cp /tmp/$dumpfile oraexp:$oraexpDestination"
          docker cp /tmp/$dumpfile oraexp:$oraexpDestination;
          echo "docker exec -it oraexp chmod 777 $oraexpDestination"
          docker exec -it oraexp chmod 777 $oraexpDestination;
       fi
  else
      echo "usage: db-dump-to-docker-oraexp <dumpfile> <'NYPS2020_LOCAL'|'NYPS2020_MIN_LOCAL'>"
      return 1;
  fi
}

load-dump() {
  schema=$1;
  dumpfile=$2;
  echo "Loading dump $dumpfile";
  echo "docker exec -it oraexp /u01/app/oracle/product/11.2.0/xe/bin/impdp oraload/utv888 dumpfile=$dumpfile remap_schema=ORALOAD:$schema"
  docker exec -it oraexp /u01/app/oracle/product/11.2.0/xe/bin/impdp oraload/utv888 table_exists_action=replace dumpfile=$dumpfile remap_schema=ORALOAD:$schema;
}

reset-oraexp() {
  echo "Removing oraexp...";
  docker rm -f oraexp;
  echo "Starting oraexp...";
  docker run -d --shm-size=2G --name oraexp -p 1521:1521 oraexp:1.0;
  wait-until-oraexp-started;
}

wait-until-oraexp-started() {
  dots="";
  echo -en "Wait for Oracle to start";
  while true; do
    up=`docker exec -it oraexp /bin/bash -c 'echo "SELECT COUNT(*) FROM HR.EMPLOYEES;" | /u01/app/oracle/product/11.2.0/xe/bin/sqlplus sys/utv888 as sysdba'`;
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

nyps-dump-name() {
    echo "NYPS2020_LOCAL_${1}_prod_v${2}_dummy_documents_nn_cases.dmp";
}

manga-dump-name() {
    echo "NYPS2020_MIN_LOCAL_${1}_prod_v${2}_dummy_documents.dmp";
}

copy-nyps2020-dump() {
  db-dump-to-docker-oraexp NYPS2020_LOCAL_${1}_prod_v${2}_dummy_documents_nn_cases.dmp NYPS2020_LOCAL;
}

copy-manga-dump() {
  db-dump-to-docker-oraexp NYPS2020_MIN_LOCAL_${1}_prod_v${2}_dummy_documents.dmp NYPS2020_MIN_LOCAL;
}

db-reset-and-reload() {
    reset-oraexp;
    db-load-dumps $1 $2 $3;
}

db-migrate-nyps() {
    mvn clean compile flyway:migrate -f $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/pom.xml;
}

db-migrate-manga() {
    mvn clean compile flyway:migrate -f $NYPS2020_ROOT/appl/tool.appl/myapp-db-migration.tool.appl/pom.xml;
}

db-migrate() {
    db-migrate-manga;
    db-migrate-nyps;
}

db-load-dumps() {
  date=$1;
  ver=$2;
  noMigrate=$3;

  if [ "" = "$date" ] || [ "" = "$ver" ]; then
    echo "usage: db-reload-all <date> <version> [no-migrate]; e.g db-reload-all 160919 8.0.0";
    return 1;
  fi

  db-dump-to-docker-oraexp $(nyps-dump-name $1 $2) NYPS2020_LOCAL;
  db-dump-to-docker-oraexp $(manga-dump-name $1 $2) NYPS2020_LOCAL;

  wait-until-oraexp-started

  load-dump NYPS2020_LOCAL $(nyps-dump-name $1 $2);
  load-dump NYPS2020_LOCAL $(manga-dump-name $1 $2);

#  docker commit -m "Oracle express with nyps and manga dumps from date: $date, ver: $ver" oraexp oraexp:$ver_$date;
#  echo "created image oraexp oraexp:$ver_$date";

  if [ "no-migrate" != "$noMigrate" ]; then
    db-migrate-nyps;
    db-migrate-manga;
  fi
}

docker-clean-up() {
    docker rm $(docker ps -q -f 'status=exited');
    docker rmi $(docker images -q -f "dangling=true");
    docker volume rm $(docker volume ls -qf dangling=true);
}

change-extension-recursively() {
    exit 1; #funkar inte än
    orgext = $1;
    newext = $2;
    git = $3;
    find . -name "*.${orgext}" -exec bash -c '${git} mv "$1" "${1%.${orgext}}".${newext}' - '{}' \;
}

dockerExecBash() {
    if [ "" = "$1" ]; then
      echo "Du måste ange namn på docker container";
      return 1;
    fi

    docker exec -it $1 bash
}

db-run() {
  container_name=$1;
  if [ "" = "$container_name" ]; then
    container_name="oraexp"
  fi

  echo "Run DB container: $container_name"

  docker run -d --shm-size=2G --name $container_name -p 1521:1521 capulet.tillvaxtverket.se:18078/nyps2020-db:v9.0.0-latest
}

eval "$(thefuck --alias)"
alias httpserver='server'
alias mou="open -a Mou "
alias killjboss="ps auxww | grep -e 'jboss'|awk '{print $2}'|xargs kill -9"
alias mvn="mvn -T 1C"
alias mq8='mvn -T8 -q'
alias mvnq='mvn -T 1C -o -DskipTests -P-include-fe'
alias mq8ci='mvn -T8 -q clean install -am'
alias mcis='mvn clean install -Pslow-test'
alias mit='mvn clean verify -Pint-test'
alias mitd='mvn clean process-test-resources cargo:run -Pint-test -Pdebug'
alias mito='mvn clean verify -Pint-test -Dsystem.type=old-demo-env -Ddatabase.connectionurl="jdbc:oracle:thin:@phoebe.tillvaxtverket.se:1521:nypsutv" -Ddatabase.user=nyps2020_demo -Ddatabase.password=utv888'
alias mitod='mvn clean process-test-resources cargo:run -Pdebug -Pint-test -Dsystem.type=old-demo-env -Ddatabase.connectionurl="jdbc:oracle:thin:@phoebe.tillvaxtverket.se:1521:nypsutv" -Ddatabase.user=nyps2020_demo -Ddatabase.password=utv888'
alias mdbt='mvn install -Pslow-test'
alias mswfly='mvn clean initialize -P setup-wildfly'
alias mloc='mvn -Dmaven.repo.local=./m2repo'
alias sqlplus64='sqlplus'
alias nyps-oracle-baseline-local='$NYPS2020_ROOT/etc/sqlplus/drop_db.sh nyps2020_local utv888 XE; $NYPS2020_ROOT/etc/sqlplus/run_sqlplus.sh -u nyps2020_local -p utv888 -c XE $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/src/main/resources/db/baseline/nyps2020_baseline_dev_v3.0.0.sql'
#alias reload-db='pushd $NYPS2020_ROOT; $NYPS2020_ROOT/etc/sqlplus/drop_db.sh nyps2020_local utv888 XE; $NYPS2020_ROOT/etc/sqlplus/run_sqlplus.sh -u nyps2020_local -p utv888 -c XE $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/src/main/resources/db/baseline/nyps2020_baseline_dev_v3.0.0.sql; mvn clean install flyway:migrate -f $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/pom.xml;popd'
#alias reload-db="pushd $NYPS2020_ROOT; ssh oracle@oraexp 'bash db_import_test_dump.sh -f dev_db.dmp'; mvn clean install flyway:migrate -f $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/pom.xml;popd"'"
alias tree="find . -type d -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"
alias missioncontrol='export JAVA_TOOL_OPTIONS="-Djava.awt.headless=false";jmc&'
alias visualvm='export JAVA_TOOL_OPTIONS="-Djava.awt.headless=false";jvisualvm&'
alias brewupdate='brew update; brew upgrade --all'
alias jrepl='java -jar /Users/joebin/verktyg/javarepl.jar'
alias db-clear="ssh oracle@oraexp 'bash db_import_test_dump.sh -f dev_db.dmp'"
alias db-clear-manga="ssh oracle@oraexp 'bash db_import_test_dump_manga.sh -f NYPS2020_MIN_LOCAL_EMPTY.dmp'"



# From NYPS2020
# Shell stuff
alias ll="ls -l"
alias la="ls -la"

# Git
alias ga="git add -A ."
alias gb="git branch"
alias gc="git commit -m"
alias gl="git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%C(bold blue)<%an>%Creset' --abbrev-commit"
alias gr="git pull --rebase"
alias gs="git status"
alias mvn="mvn -T 1C"

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

  #NYPS2020
  alias cdnyps="cd $NYPS2020_ROOT"
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
  alias nyps-migrate="mvnq -f $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl clean compile flyway:migrate"

# OBSOLETE
#  alias nyps-mysql-authenticate_on="$NYPS2020_ROOT/etc/mysql/update-nyps-dev-authenticate.sh on"
#  alias nyps-mysql-authenticate_off="$NYPS2020_ROOT/etc/mysql/update-nyps-dev-authenticate.sh off"
#  alias nyps-mysql-reload="mvn clean compile exec:java -f $NYPS2020_ROOT/appl/tool.appl/dbloader.tool.appl/pom.xml"
#  alias nyps-mysql-recreate="mysql -uroot -p < $NYPS2020_ROOT/etc/mysql/recreate-nyps-dev.sql"
#  alias nyps-mysql-legacy="$NYPS2020_ROOT/etc/mysql/update-nyps-dev-jnp-host.sh $LEGACY_SERVER_IP_ADDRESS"
#
#  alias nyps-oracle-drop="$NYPS2020_ROOT/etc/sqlplus/drop_db.sh nyps2020_local utv888 XE"
#  alias nyps-oracle-reload="nyps-oracle-baseline-local; mvn -f $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/pom.xml clean install flyway:migrate"
#  alias nyps-oracle-authenticate_on="echo exit | sqlplus64 nyps2020_local/utv888@oraexp/XE @$NYPS2020_ROOT/etc/sqlplus/update-nyps-oracle-authenticate.sql 'false' 'true'"
#  alias nyps-oracle-authenticate_off="echo exit | sqlplus64 nyps2020_local/utv888@oraexp/XE @$NYPS2020_ROOT/etc/sqlplus/update-nyps-oracle-authenticate.sql 'true' 'false'"
#  alias nyps-oracle-migrate="mvn -f /Volumes/nyps2020-CaseSensitive/nyps2020/appl/tool.appl/db-migration.tool.appl/pom.xml clean install flyway:migrate"
#  alias nyps-oracle-baseline-local="nyps-oracle-drop; $NYPS2020_ROOT/etc/sqlplus/run_sqlplus.sh -u nyps2020_local -p utv888 -c XE $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/src/main/resources/db/baseline/nyps2020_baseline_dev_v3.0.0.sql"
#  alias nyps-oracle-baseline-local="ssh oracle@oraexp 'bash db_import_test_dump.sh -f NYPS2020_LOCAL_150409_prod_13_cases_v4.dmp'"
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

nysh() {
  local root;
  if [ "" = "$1" ]; then
    root=$(pwd);
  else
    root=$1;
  fi
  root=$(cd $root;pwd); # expand path
  local closestNypsRoot=$(findClosestNypsRoot $root)

  if [ "" = "${closestNypsRoot}" ] || [ ! -f "${closestNypsRoot}/pom.xml" ] || ! grep -q "<name>Nyps 2020</name>" ${closestNypsRoot}/pom.xml; then
    echo "Usage: switch-clone <NYPS2020 git root directory>"
    return 1;
  fi

  db_name="oraexp-$(basename $closestNypsRoot)"

  echo "Starting Nyps shell in ${closestNypsRoot}"
  setup-nyps2020-aliases $closestNypsRoot;

  alias mvn="mvn -T 1C -Dmaven.repo.local=$closestNypsRoot/m2repo";
  alias db-start="db-run $db_name";
  alias db-clear="docker rm -f $db_name";
  alias db-reset="db-clear && db-start";
  alias db-up="db-wait-up $db_name";

  cd $root;
}

findClosestNypsRoot() {
  local dir=$1
  if [ "$dir" = "" ]; then
    dir=$(pwd)
  fi
  dir=$(cd $dir; echo $(pwd))

  if [ "$dir" = "/" ]; then
    echo "NYPS_ROOT_NOT_FOUND";
  elif isNypsRoot $dir ; then
    echo $dir
  else
    echo $(findClosestNypsRoot $(cd "$dir/.."; echo $(pwd)))
  fi
}

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

alias nyps-maintenance="setup-nyps2020-aliases nyps2020-maintenance"
alias dock-compiler='docker exec -it -u nyps compiler /bin/bash  -c "export TERM=xterm; exec bash;"'
alias dock-compiler-maintenance='docker exec -it -u nyps compiler-maintenance /bin/bash  -c "export TERM=xterm; exec bash;"'
alias dock-oraexp='docker exec -it -u oracle oraexp /bin/bash  -c "export TERM=xterm; exec bash;"'
alias dock-jenkins='docker exec -it -u jenkins jenkins /bin/bash  -c "export TERM=xterm; exec bash;"'
alias brew-refresh='brew update && brew upgrade && npm update -g'
alias git="LC_ALL=en_US.UTF-8 git"
alias reload-shell=". ~/.dotfiles/zsh/custom/my-patches.zsh"
alias dkrsh='dockerExecBash'
alias get2020root="echo $NYPS2020_ROOT"

local closestNypsRoot=$(findClosestNypsRoot)
if [ "$closestNypsRoot" != "NYPS_ROOT_NOT_FOUND" ] ; then
  nysh
fi
