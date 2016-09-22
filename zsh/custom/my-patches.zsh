. `/usr/local/bin/brew --prefix`/etc/profile.d/z.sh

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

  src_nyps_dump="NYPS2020_LOCAL_${date}_prod_v${ver}_dummy_documents_nn_cases.dmp"
  src_manga_dump="NYPS2020_MIN_LOCAL_${date}_prod_v${ver}_dummy_documents.dmp"
  echo "copying ${src_nyps_dump} and ${src_manga_dump}"
  db-dump-fetch $src_nyps_dump "dev_db_nyps.dmp"
  if [ "" = "$onlynyps" ]; then
    db-dump-fetch $src_manga_dump "dev_db_manga.dmp"
  fi
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

  echo "copy $src/$dumpfile -> oraexp:/u01/app/oracle/admin/XE/dpdump/$schema.dmp";
  if [ "" != "$dumpfile" ] && [ "" != "$schema" ]; then
      echo "scp $src/$dumpfile /tmp/$schema.dmp"
      scp $src/$dumpfile /tmp/$schema.dmp;
      echo "docker cp /tmp/$schema.dmp oraexp:/u01/app/oracle/admin/XE/dpdump/$schema.dmp"
      docker cp /tmp/$schema.dmp oraexp:/u01/app/oracle/admin/XE/dpdump/$schema.dmp;
      docker exec -it oraexp /bin/bash -c 'touch /u01/app/oracle/admin/XE/dpdump/last-imported-$schems-$dumpfile';
      echo "docker exec -it oraexp chmod 777 /u01/app/oracle/admin/XE/dpdump/$schema.dmp"
      docker exec -it oraexp chmod 777 /u01/app/oracle/admin/XE/dpdump/$schema.dmp;
      echo "Clean up ./"
      rm -f ./${dumpfile};
  else
      echo "usage: db-dump-to-docker-oraexp <dumpfile> <'NYPS2020_LOCAL'|'NYPS2020_MIN_LOCAL'>"
      return 1;
  fi
}

load-dump() {
  schema=$1
  echo "Loading dump $schema";
  echo "docker exec -it oraexp /u01/app/oracle/product/11.2.0/xe/bin/impdp oraload/utv888 dumpfile=$schema.dmp remap_schema=ORALOAD:$schema"
  docker exec -it oraexp /u01/app/oracle/product/11.2.0/xe/bin/impdp oraload/utv888 dumpfile=$schema.dmp remap_schema=ORALOAD:$schema;
}

reset-oraexp() {
  echo "Removing oraexp...";
  docker rm -f oraexp;
  echo "Starting oraexp...";
  docker run -d --shm-size=2G --name oraexp -p 1521:1521 oraexp:1.0;
}

wait-until-oraexp-started() {
  echo "Wait for Oracle to start..."
  while true; do
    pmon=`docker exec -it oraexp /bin/bash -c 'ps -ef | grep pmon_$ORACLE_SID | grep -v grep'`;
    up=`docker exec -it oraexp /bin/bash -c 'echo "SELECT COUNT(*) FROM HR.EMPLOYEES;" | /u01/app/oracle/product/11.2.0/xe/bin/sqlplus sys/utv888 as sysdba'`
    if [[ "$up" =~ '.*ERROR.*' ]]; then
      echo "Oraexp not up yet..."
    else
      echo "Oraexp has started!"
      sleep 10;
      return;
    fi
    sleep 10
  done;
}

copy-nyps2020-dump() {
  db-dump-to-docker-oraexp NYPS2020_LOCAL_${1}_prod_v${2}_dummy_documents_nn_cases.dmp NYPS2020_LOCAL;
}

copy-manga-dump() {
  db-dump-to-docker-oraexp NYPS2020_MIN_LOCAL_${1}_prod_v${2}_dummy_documents.dmp NYPS2020_MIN_LOCAL;
}

db-reload-docker-all() {
  date=$1;
  ver=$2;
  migrate=$3

  if [ "" = "$date" ] || [ "" = "$ver" ]; then
    echo "usage: db-reload-all <date> <version>; e.g db-reload-all 160919 8.0.0";
    return 1;
  fi

  reset-oraexp;
  copy-nyps2020-dump $date $ver;
  copy-manga-dump $date $ver;

  wait-until-oraexp-started

  load-dump NYPS2020_LOCAL;
  load-dump NYPS2020_MIN_LOCAL;

  if [ "" != "$migrate"]; then
    mvn clean compile flyway:migrate -f $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/pom.xml;
    mvn clean compile flyway:migrate -f $NYPS2020_ROOT/appl/tool.appl/myapp-db-migration.tool.appl/pom.xml;
  fi
}

eval "$(thefuck --alias)"
alias httpserver='server'
alias mou="open -a Mou "
alias killjboss="ps auxww | grep -e 'jboss'|awk '{print $2}'|xargs kill -9"
alias mq8='mvn -T8 -q'
alias mvnqk='mvn -T8 clean install -DskipTests'
alias mq8ci='mvn -T8 -q clean install'
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


setup-nyps2020-aliases() {
  root=$1
  if [ "" = "$root" ]; then
    root=nyps2020
  fi

  export NYPS2020_ROOT=$PROJ_DISK/tvv/$root
  export NEO_HOME=$NYPS2020_ROOT/appl/fe.appl/neoclient.fe.appl
  export MANGA_HOME=$NYPS2020_ROOT/appl/fe.appl/manga.fe.appl
  export MAMOCK_HOME=$NYPS2020_ROOT/appl/fe.appl/ma-mock.fe.appl

  #NYPS2020
  alias cdnyps="cd $NYPS2020_ROOT"
  alias nyps-mysql-authenticate_on="$NYPS2020_ROOT/etc/mysql/update-nyps-dev-authenticate.sh on"
  alias nyps-mysql-authenticate_off="$NYPS2020_ROOT/etc/mysql/update-nyps-dev-authenticate.sh off"
  alias nyps-mysql-reload="mvn clean compile exec:java -f $NYPS2020_ROOT/appl/tool.appl/dbloader.tool.appl/pom.xml"
  alias nyps-mysql-recreate="mysql -uroot -p < $NYPS2020_ROOT/etc/mysql/recreate-nyps-dev.sql"
  alias nyps-mysql-legacy="$NYPS2020_ROOT/etc/mysql/update-nyps-dev-jnp-host.sh $LEGACY_SERVER_IP_ADDRESS"

  alias nyps-oracle-drop="$NYPS2020_ROOT/etc/sqlplus/drop_db.sh nyps2020_local utv888 XE"
  alias nyps-oracle-reload="nyps-oracle-baseline-local; mvn -f $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/pom.xml clean install flyway:migrate"
  alias nyps-oracle-authenticate_on="echo exit | sqlplus64 nyps2020_local/utv888@oraexp/XE @$NYPS2020_ROOT/etc/sqlplus/update-nyps-oracle-authenticate.sql 'false' 'true'"
  alias nyps-oracle-authenticate_off="echo exit | sqlplus64 nyps2020_local/utv888@oraexp/XE @$NYPS2020_ROOT/etc/sqlplus/update-nyps-oracle-authenticate.sql 'true' 'false'"
  alias nyps-oracle-migrate="mvn -f /Volumes/nyps2020-CaseSensitive/nyps2020/appl/tool.appl/db-migration.tool.appl/pom.xml clean install flyway:migrate"
  #alias nyps-oracle-baseline-local="nyps-oracle-drop; $NYPS2020_ROOT/etc/sqlplus/run_sqlplus.sh -u nyps2020_local -p utv888 -c XE $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/src/main/resources/db/baseline/nyps2020_baseline_dev_v3.0.0.sql"
  alias nyps-oracle-baseline-local="ssh oracle@oraexp 'bash db_import_test_dump.sh -f NYPS2020_LOCAL_150409_prod_13_cases_v4.dmp'"

  alias nyps-build="mvn clean install -DskipTests -P-include-fe -f $NYPS2020_ROOT/pom.xml"
  alias nyps-build-slow-test="mvn clean install -Pslow-test,-include-fe -f $NYPS2020_ROOT/pom.xml"
  alias nyps-neoclient="bash -c 'cd $NEO_HOME && npm start '"
  alias nyps-manga="bash -c 'cd $MANGA_HOME && npm start '"
  alias nyps-mamock="bash -c 'cd $MAMOCK_HOME && grunt serve --open-page=false  --proxy-be=true '"
  alias nyps-adminclient-run="cd $NYPS2020_ROOT/appl/fe.appl/adminclient.fe.appl/adminclient && grunt serve --proxy-be"
  alias nyps-be-build-deploy="mvn install -DskipTests -f common && mvn -DskipTests -f $NYPS2020_ROOT/appl/be.appl/pom.xml install -Pdeploy"
  alias manga-nyps-be-build-deploy="mvn install -DskipTests -f common &&
  mvn -DskipTests -f $NYPS2020_ROOT/appl/be.appl/pom.xml install && mvn -DskipTests -f $NYPS2020_ROOT/appl/myapp-be.appl/pom.xml install -Pdeploy"
  alias manga-be-build-deploy="mvn install -DskipTests -f common && mvn -DskipTests -f $NYPS2020_ROOT/appl/myapp-be.appl/pom.xml install -Pdeploy"
  alias nyps-deploy="mvn clean package wildfly:deploy -f $NYPS2020_ROOT/appl/be.appl/ear.be.appl"
  alias nyps-deploy-adsync="mvn -f $NYPS2020_ROOT/appl/adsync.appl/pom.xml install -Pdeploy"
  alias nyps-deploy-eco="mvn -f $NYPS2020_ROOT/appl/ecoint-be.appl/ear.ecoint-be.appl/pom.xml install -Pdeploy"
  alias nyps-deploy-neoclient="mvn -f $NYPS2020_ROOT/appl/fe.appl/neoclient.fe.appl/pom.xml wildfly:deploy"
  alias nyps-wildfly-start="$NYPS2020_ROOT/tool/as.tool/wildfly.as.tool/target/server/wildfly-10.0.0.Final/bin/standalone.sh"
  alias nyps-wildfly-rebuild="mvn -f $NYPS2020_ROOT/tool/as.tool/pom.xml clean install -P setup-wildfly"
  alias nyps-wildfly-adminclient-deploy="mvn -f $NYPS2020_ROOT/appl/be.appl/rest.be.appl/admin-api.rest.be.appl/pom.xml wildfly:deploy"

  alias nyps-smartdocuments-test-configuration="echo exit | sqlplus64 nyps2020_local/utv888@oraexp/XE @$NYPS2020_ROOT/etc/sqlplus/set-nyps-smartdocuments-configuration.sql 'https://sdtest.tillvaxtverket.se/' 'userid' 'password'"
  alias nyps-inttest="mvn -f $NYPS2020_ROOT/test/service-int.test/ clean verify -Pint-test"

}

alias nyps-maintenance="setup-nyps2020-aliases nyps2020-maintenance"
alias dock-compiler='docker exec -it -u nyps compiler /bin/bash  -c "export TERM=xterm; exec bash;"'
alias dock-compiler-maintenance='docker exec -it -u nyps compiler-maintenance /bin/bash  -c "export TERM=xterm; exec bash;"'
alias dock-oraexp='docker exec -it -u oracle oraexp /bin/bash  -c "export TERM=xterm; exec bash;"'
alias dock-jenkins='docker exec -it -u jenkins jenkins /bin/bash  -c "export TERM=xterm; exec bash;"'

setup-nyps2020-aliases
