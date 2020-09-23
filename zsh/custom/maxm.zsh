setjdk() {
   echo "Set JDK to $1"
   export JAVA_HOME=$(/usr/libexec/java_home -v $1)
   echo "JAVA_HOME=$JAVA_HOME"
}

export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

alias maxm-start-jboss="cd /Users/Shared/export/wildfly_installations/local/bin && setjdk 1.8 && ./maxm-standalone.sh;"
alias maxm-deploy-intApp="/Users/joel.binnquist/projects/devops/development/scripts/deploydev.sh intApp"
alias maxm-deploy-pmlBackend="/Users/joel.binnquist/projects/devops/development/scripts/deploydev.sh pmlBackend"
alias maxm-deploy-ps="/Users/joel.binnquist/projects/devops/development/scripts/deploydev.sh PSApp"

setjdk 11
n stable
