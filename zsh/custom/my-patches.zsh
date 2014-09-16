. `/usr/local/bin/brew --prefix`/etc/profile.d/z.sh

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

function server() {
        python -m SimpleHTTPServer "8989"
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
alias mvnlocrep='mvn -Dmaven.repo.local=./slask/m2repo'

