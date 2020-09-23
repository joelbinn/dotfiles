. `/usr/local/bin/brew --prefix`

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
  export PATH=./node_modules/.bin:$HOME/.config/yarn/global/node_modules/.bin:$HOME/bin:/usr/local/bin:/opt/local/bin:/opt/local/sbin:$JAVA_HOME/bin:.:/bin:/usr/bin:/usr/sbin:/sbin:/opt/X11/bin:/usr/local/git/bin:$PATH
#  export JAVA_TOOL_OPTIONS='-Djava.awt.headless=true'
fi
export JOEBIN_SH_PATH_SETUP="true"

export MAVEN_OPTS="$MAVEN_OPTS -Xmx1500m"
# export MAVEN_OPTS="$MAVEN_OPTS -Djava.awt.headless=true -Xmx1g"
DIR="$( cd "$( dirname "$0" )" && pwd )"

echo "Initialize Joel's patches..."
. $DIR/computer-specific

echo "Initialize Joel's common environment variables..."
# ip_address may have been set in computer-specific
if [ "$ip_address" = "" ]
then
  # OK try to do it the old way...
  export ip_address=`ifconfig ${NIC} | awk '/inet/ {print $2}' |  grep -e "\."  | grep --invert "127" | head -n 1`
fi

echo " -> ip_address=$ip_address"
export EXTERNAL_IP_ADDRESS=$ip_address
echo " -> EXTERNAL_IP_ADDRESS=$EXTERNAL_IP_ADDRESS"

function server() {
        python -m SimpleHTTPServer "8989"
}

mcd () {
    mkdir "$@" && cd "$@"
}

change-extension-recursively() {
    exit 1; #funkar inte än
    orgext = $1;
    newext = $2;
    git = $3;
    find . -name "*.${orgext}" -exec bash -c '${git} mv "$1" "${1%.${orgext}}".${newext}' - '{}' \;
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

alias httpserver='server'
alias killjboss="ps auxww | grep -e 'jboss'|awk '{print $2}'|xargs kill -9"
alias mvn1C="mvn -T 1C"
alias mloc='mvn -Dmaven.repo.local=./m2repo'
alias tree="find . -type d -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"
alias missioncontrol='export JAVA_TOOL_OPTIONS="-Djava.awt.headless=false";jmc&'
alias visualvm='export JAVA_TOOL_OPTIONS="-Djava.awt.headless=false";jvisualvm&'

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
