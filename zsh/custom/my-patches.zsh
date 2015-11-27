. `/usr/local/bin/brew --prefix`/etc/profile.d/z.sh

# User configuration
#export ORACLE_HOME=$NYPS2020_ROOT/etc/sqlplus/instantclient/macosx_64
#export TNS_ADMIN=$ORACLE_HOME
#export DYLD_LIBRARY_PATH=$ORACLE_HOME:$DYLD_LIBRARY_PATH
export NLS_LANG=SWEDISH_SWEDEN.UTF8
#PATH=$PATH:$ORACLE_HOME

export PROJ_DISK=/Volumes/projects-40g
export NYPS2020_ROOT=$PROJ_DISK/tvv/nyps2020/
export PROJSTUFF=$PROJ_DISK/projectstuff
export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=./node:./node_modules/.bin:$PATH:$HOME/bin:/opt/local/bin:/opt/local/sbin:$JAVA_HOME/bin:.:/bin:/usr/bin:/usr/sbin:/sbin:/opt/X11/bin:/usr/local/git/bin
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
    ssh oracle@oraexp 'bash db_import_test_dump.sh -f dev_db.dmp';
    mvn clean install flyway:migrate -f $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/pom.xml;
}

db-reload-manga() {
    ssh oracle@oraexp 'bash db_import_test_dump_manga.sh -f NYPS2020_MIN_LOCAL_EMPTY.dmp';
    mvn clean install flyway:migrate -f $NYPS2020_ROOT/appl/tool.appl/myapp-db-migration.tool.appl/pom.xml;
}

db-migrate() {
    mvn clean install flyway:migrate -f $NYPS2020_ROOT/appl/tool.appl/db-migration.tool.appl/pom.xml;
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

eval "$(thefuck --alias)"
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

alias nyps-neoclient-run="bash -c 'cd $NYPSCLIENT_HOME && grunt serve --proxy-be'"
alias nyps-adminclient-run="cd $NYPS2020_ROOT/appl/fe.appl/adminclient.fe.appl/adminclient && grunt serve --proxy-be"
alias nyps-build-deploy="mvn -f $NYPS2020_ROOT/appl/be.appl/pom.xml install -Pdeploy"
alias manga-build-deploy="mvn -f $NYPS2020_ROOT/appl/myapp-be.appl/pom.xml install -Pdeploy"
alias nyps-wildfly-deploy="mvn -f $NYPS2020_ROOT/appl/be.appl/ear.be.appl/pom.xml install -Pdeploy"
alias nyps-wildfly-deploy-adsync="mvn -f $NYPS2020_ROOT/appl/adsync.appl/pom.xml install -Pdeploy"
alias nyps-wildfly-deploy-eco="mvn -f $NYPS2020_ROOT/appl/ecoint-be.appl/ear.ecoint-be.appl/pom.xml install -Pdeploy"
alias nyps-wildfly-client-deploy="mvn -f $NYPS2020_ROOT/appl/fe.appl/neoclient.fe.appl/pom.xml wildfly:deploy"
alias nyps-wildfly-standalone="$NYPS2020_ROOT/tool/as.tool/wildfly.as.tool/target/server/wildfly-8.2.0.Final/bin/standalone.sh"
alias nyps-wildfly-rebuild="mvn -f $NYPS2020_ROOT/tool/as.tool/pom.xml clean install -P setup-wildfly"
alias nyps-wildfly-adminclient-deploy="mvn -f $NYPS2020_ROOT/appl/be.appl/rest.be.appl/admin-api.rest.be.appl/pom.xml wildfly:deploy"

alias nyps-smartdocuments-test-configuration="echo exit | sqlplus64 nyps2020_local/utv888@oraexp/XE @$NYPS2020_ROOT/etc/sqlplus/set-nyps-smartdocuments-configuration.sql 'https://sdtest.tillvaxtverket.se/' 'userid' 'password'"
