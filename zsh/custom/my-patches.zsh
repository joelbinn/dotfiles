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

if [ "$JOEBIN_SH_PATH_SETUP" = ""  ]; then
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
fi
export JOEBIN_SH_PATH_SETUP="true"

export MAVEN_OPTS="$MAVEN_OPTS -Djava.awt.headless=true"
DIR="$( cd "$( dirname "$0" )" && pwd )"

echo "Initialize Joel's patches..."
. $DIR/computer-specific

echo "Initialize Joel's common environment variables..."
# ip_address may have been set in computer-specific
if [ "$ip_address" = "" ]
then
  # OK try to do it the old way...
  export ip_address=`ifconfig ${NIC} | awk '/inet/ {print $2}' |  grep -e "\." `
fi  
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

# Wrapper function for Maven's mvn command.
# mvn-color based on https://gist.github.com/1027800
export BOLD=`tput bold`
export UNDERLINE_ON=`tput smul`
export UNDERLINE_OFF=`tput rmul`
export TEXT_BLACK=`tput setaf 0`
export TEXT_RED=`tput setaf 1`
export TEXT_GREEN=`tput setaf 2`
export TEXT_YELLOW=`tput setaf 3`
export TEXT_BLUE=`tput setaf 4`
export TEXT_MAGENTA=`tput setaf 5`
export TEXT_CYAN=`tput setaf 6`
export TEXT_WHITE=`tput setaf 7`
export BACKGROUND_BLACK=`tput setab 0`
export BACKGROUND_RED=`tput setab 1`
export BACKGROUND_GREEN=`tput setab 2`
export BACKGROUND_YELLOW=`tput setab 3`
export BACKGROUND_BLUE=`tput setab 4`
export BACKGROUND_MAGENTA=`tput setab 5`
export BACKGROUND_CYAN=`tput setab 6`
export BACKGROUND_WHITE=`tput setab 7`
export RESET_FORMATTING=`tput sgr0`
mvn-color() {
  (
  # Filter mvn output using sed. Before filtering set the locale to C, so invalid characters won't break some sed implementations
  unset LANG
  LC_CTYPE=C mvn $@ | sed -e "s/\(\[INFO\]\)\(.*\)/${TEXT_BLUE}${BOLD}\1${RESET_FORMATTING}\2/g" \
               -e "s/\(\[INFO\]\ BUILD SUCCESSFUL\)/${BOLD}${TEXT_GREEN}\1${RESET_FORMATTING}/g" \
               -e "s/\(\[WARNING\]\)\(.*\)/${BOLD}${TEXT_YELLOW}\1${RESET_FORMATTING}\2/g" \
               -e "s/\(\[ERROR\]\)\(.*\)/${BOLD}${TEXT_RED}\1${RESET_FORMATTING}\2/g" \
               -e "s/Tests run: \([^,]*\), Failures: \([^,]*\), Errors: \([^,]*\), Skipped: \([^,]*\)/${BOLD}${TEXT_GREEN}Tests run: \1${RESET_FORMATTING}, Failures: ${BOLD}${TEXT_RED}\2${RESET_FORMATTING}, Errors: ${BOLD}${TEXT_RED}\3${RESET_FORMATTING}, Skipped: ${BOLD}${TEXT_YELLOW}\4${RESET_FORMATTING}/g"

  # Make sure formatting is reset
  echo -ne ${RESET_FORMATTING}
  )
}

changed-mvn-projects() {
  echo $(git status -s | awk '{print $2}'| grep "src/" | sed 's/src.*//' | uniq | tr '\n' ',')
}

eval "$(thefuck --alias)"
alias httpserver='server'
alias killjboss="ps auxww | grep -e 'jboss'|awk '{print $2}'|xargs kill -9"
alias mvn="mvn -T 1C"
alias mloc='mvn -Dmaven.repo.local=./m2repo'
alias sqlplus64='sqlplus'
alias tree="find . -type d -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"
alias missioncontrol='export JAVA_TOOL_OPTIONS="-Djava.awt.headless=false";jmc&'
alias visualvm='export JAVA_TOOL_OPTIONS="-Djava.awt.headless=false";jvisualvm&'
alias jrepl='java -jar /Users/joebin/verktyg/javarepl.jar'

# From NYPS2020
# Shell stuff
alias ll="ls -l"
alias la="ls -la"

# Git
alias git="LC_ALL=en_US.UTF-8 git"
alias ga="git add -A ."
alias gb="git branch"
alias gc="git commit -m"
alias gl="git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%C(bold blue)<%an>%Creset' --abbrev-commit"
alias gr="git pull --rebase"
alias gs="git status"

alias brew-refresh='brew update && brew upgrade --all && npm update -g'
alias reload-shell=". ~/.dotfiles/zsh/custom/my-patches.zsh"

clear

if [ "$NYPS2020_SHELL" = "" ]; then
  echo "\e[96m       __      __    _    _____ __         ____"
  echo "\e[96m      / /___  / /_  (_)  / ___// /_  ___  / / /"
  echo "\e[96m __  / / __ \/ __ \/ /   \__ \/ __ \/ _ \/ / / "
  echo "\e[96m/ /_/ / /_/ / /_/ / /   ___/ / / / /  __/ / /  "
  echo "\e[96m\____/\____/_.___/_/   /____/_/ /_/\___/_/_/   \e[0m"
fi
