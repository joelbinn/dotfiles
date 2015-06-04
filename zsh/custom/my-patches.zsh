. `/usr/local/bin/brew --prefix`/etc/profile.d/z.sh

# User configuration
#export ORACLE_HOME=$NYPS2020_ROOT/etc/sqlplus/instantclient/macosx_64
#export TNS_ADMIN=$ORACLE_HOME
#export DYLD_LIBRARY_PATH=$ORACLE_HOME:$DYLD_LIBRARY_PATH
export NLS_LANG=SWEDISH_SWEDEN.UTF8
#PATH=$PATH:$ORACLE_HOME

export PROJ_DISK=/Volumes/projects-40g
export NYPS2020_ROOT=$PROJ_DISK/tvv/nyps2020/
export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$PATH:$HOME/bin:/opt/local/bin:/opt/local/sbin:$JAVA_HOME/bin:.:/bin:/usr/bin:/usr/sbin:/sbin:/opt/X11/bin:/usr/local/git/bin
export JAVA_TOOL_OPTIONS='-Djava.awt.headless=true'

DIR="$( cd "$( dirname "$0" )" && pwd )"

echo "Initialize Joel's patches..."
. $DIR/computer-specific

echo "Initialize Joel's common environment variables..."
export ip_address=`ifconfig ${NIC} | awk '/inet/ {print $2}' |  grep -e "\." `
echo " -> ip_address=$ip_address"
export EXTERNAL_IP_ADDRESS=$ip_address
echo " -> EXTERNAL_IP_ADDRESS=$EXTERNAL_IP_ADDRESS"
export DOCKER_HOST=tcp://localhost:4243
echo " -> DOCKER_HOST=$DOCKER_HOST"
export TNS_ADMIN=~/.tnsadmin

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

local-copy-dev-dump() {
    if [ "" != "$1" ]; then
        scp jenkins@capulet:db-dump/$1 .;
        if [[ $? -eq 0 ]]; then
            scp ./$1 oracle@oraexp:/rman/dpdir/XE/dev_db.dmp;
            rm ./$1
            return 0;
        else
            return 2;
        fi    
    else
        return 1;
    fi  
}

db-reload() {
    #cd $NYPS2020_ROOT/; 
    ssh oracle@oraexp 'bash db_import_test_dump.sh -f dev_db.dmp'; 
    mvn clean install flyway:migrate -f $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/pom.xml;
    #cd -;
}

db-migrate() {
    #cd $NYPS2020_ROOT/; 
    mvn clean install flyway:migrate -f $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/pom.xml;
    #cd -;
}

db-ls-dumps() {
    ssh jenkins@capulet 'ls -1 ~/db-dump/';
}

db-copy-dev-dump() {
    local-copy-dev-dump $1
    if [[ $? -eq 1 ]]; then
        echo "No dump file specified!";
    fi
}

db-reload-with-dump() {
    local-copy-dev-dump $1
    if [[ $? -eq 0 ]]; then
        db-reload;
    elif [[ $? -eq 1 ]]; then
        echo "No dump file specified!";
    fi
}

pwcrt-start() {
    pushd $PROJ_DISK/projectstuff/myown/pwcrt/dist; 
    node server.js &; 
    popd;
}

alias httpserver='server'
alias mou="open -a Mou "
alias killjboss="ps auxww | grep -e 'jboss'|awk '{print $2}'|xargs kill -9"
alias mq8='mvn -T8 -q'
alias mq8ci='mvn -T8 -q clean install'
alias mcis='mvn clean install -Pslow-test'
alias mit='mvn clean verify -Pint-test'
alias mitd='mvn clean process-test-resources cargo:run -Pint-test -Pdebug'
alias mito='mvn clean verify -Pint-test -Dsystem.type=old-demo-env -Ddatabase.connectionurl="jdbc:oracle:thin:@phoebe.tillvaxtverket.se:1521:nypsutv" -Ddatabase.user=nyps2020_demo -Ddatabase.password=utv888'
alias mitod='mvn clean process-test-resources cargo:run -Pdebug -Pint-test -Dsystem.type=old-demo-env -Ddatabase.connectionurl="jdbc:oracle:thin:@phoebe.tillvaxtverket.se:1521:nypsutv" -Ddatabase.user=nyps2020_demo -Ddatabase.password=utv888'
alias mdbt='mvn install -Pslow-test'
alias mswfly='mvn clean initialize -P setup-wildfly'
alias mloc='mvn -Dmaven.repo.local=./slask/m2repo'
alias sqlplus64='sqlplus'
alias nyps-oracle-baseline-local='$NYPS2020_ROOT/etc/sqlplus/drop_db.sh nyps2020_local utv888 XE; $NYPS2020_ROOT/etc/sqlplus/run_sqlplus.sh -u nyps2020_local -p utv888 -c XE $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/src/main/resources/db/baseline/nyps2020_baseline_dev_v3.0.0.sql'
#alias reload-db='pushd $NYPS2020_ROOT; $NYPS2020_ROOT/etc/sqlplus/drop_db.sh nyps2020_local utv888 XE; $NYPS2020_ROOT/etc/sqlplus/run_sqlplus.sh -u nyps2020_local -p utv888 -c XE $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/src/main/resources/db/baseline/nyps2020_baseline_dev_v3.0.0.sql; mvn clean install flyway:migrate -f $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/pom.xml;popd'
#alias reload-db="pushd $NYPS2020_ROOT; ssh oracle@oraexp 'bash db_import_test_dump.sh -f dev_db.dmp'; mvn clean install flyway:migrate -f $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/pom.xml;popd"'"
alias tree="find . -type d -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"
alias missioncontrol='export JAVA_TOOL_OPTIONS="-Djava.awt.headless=false";jmc&'
alias visualvm='export JAVA_TOOL_OPTIONS="-Djava.awt.headless=false";jvisualvm&'
alias brewupdate='brew update; brew upgrade --all'
alias jrepl='java -jar /Users/joebin/verktyg/javarepl.jar'

