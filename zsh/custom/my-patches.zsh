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

. `brew --prefix`/etc/profile.d/z.sh

function server() {
        python -m SimpleHTTPServer "8989"
}

alias httpserver='server'
alias mou="open -a Mou "
alias killjboss="ps auxww | grep -e 'jboss'|awk '{print $2}'|xargs kill -9"
alias mq8='mvn -T8 -q'
alias mq8ci='mvn -T8 -q clean install'
