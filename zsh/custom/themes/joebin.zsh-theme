
# echo "Initialize joebin.zsh-theme..."

# oh-my-zsh Bureau Theme

# För färger se http://misc.flogisoft.com/bash/tip_colors_and_formatting

### Git [±master ▾●]
light_blue=117
dark_gray=237
salmon=174
ZSH_THEME_GIT_PROMPT_PREFIX="[%{$fg_bold[green]%}±%{$reset_color%}%{$FG[$light_blue]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}]"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}✓%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[cyan]%}▴%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[magenta]%}▾%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_STAGED="%{$fg_bold[green]%}●%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNSTAGED="%{$fg_bold[yellow]%}●%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg_bold[red]%}●%{$reset_color%}"

bureau_git_branch () {
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
  echo "${ref#refs/heads/}"
}

bureau_git_status () {
  _INDEX=$(command git status --porcelain -b 2> /dev/null)
  _STATUS=""
  if $(echo "$_INDEX" | grep '^[AMRD]. ' &> /dev/null); then
    _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_STAGED"
  fi
  if $(echo "$_INDEX" | grep '^.[MTD] ' &> /dev/null); then
    _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_UNSTAGED"
  fi
  if $(echo "$_INDEX" | grep -E '^\?\? ' &> /dev/null); then
    _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_UNTRACKED"
  fi
  if $(echo "$_INDEX" | grep '^UU ' &> /dev/null); then
    _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_UNMERGED"
  fi
  if $(command git rev-parse --verify refs/stash >/dev/null 2>&1); then
    _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_STASHED"
  fi
  if $(echo "$_INDEX" | grep '^## .*ahead' &> /dev/null); then
    _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_AHEAD"
  fi
  if $(echo "$_INDEX" | grep '^## .*behind' &> /dev/null); then
    _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_BEHIND"
  fi
  if $(echo "$_INDEX" | grep '^## .*diverged' &> /dev/null); then
    _STATUS="$_STATUS$ZSH_THEME_GIT_PROMPT_DIVERGED"
  fi

  echo $_STATUS
}

bureau_git_prompt () {
  local _branch=$(bureau_git_branch)
  local _status=$(bureau_git_status)
  local _result=""
  if [[ "${_branch}x" != "x" ]]; then
    _result="$ZSH_THEME_GIT_PROMPT_PREFIX$_branch"
    if [[ "${_status}x" != "x" ]]; then
      _result="$_result $_status"
    fi
    _result="$_result$ZSH_THEME_GIT_PROMPT_SUFFIX"
  else
    _result="%{$FG[$dark_gray]%}No GIT repo%{$reset_color%}"
  fi
  echo $_result
}

local oscd() {
  builtin cd $@
}

normalizeDir() {
  echo $(oscd $1; echo $(pwd))
}

findClosestGitRoot() {
  local dir=$1
  if [ "$dir" = "" ]; then
    dir=$(pwd)
  fi
  dir=$(normalizeDir $dir)

  if [ "$dir" = "/" ]; then
    echo "GIT_ROOT_NOT_FOUND";
  elif [ -e "$dir/.git" ]; then
    echo $dir
  else
    echo $(findClosestGitRoot $(normalizeDir "$dir/.."))
  fi
}

if [[ "%#" == "#" ]]; then
  _USERNAME="%{$fg_bold[red]%}%n"
  _LIBERTY="%{$fg[red]%}#"
else
  _USERNAME="%{$fg_bold[white]%}%n"
  # _LIBERTY="%{$fg[green]%}λ"
  _LIBERTY="%{$fg[cyan]%}jobi>"
fi
_USERNAME="$_USERNAME%{$reset_color%}@%m"
_LIBERTY="$_LIBERTY%{$reset_color%}"


get_space () {
  local STR=$1$2
  local zero='%([BSUbfksu]|([FB]|){*})'
  local LENGTH=${#${(S%%)STR//$~zero/}}
  local SPACES=""
  (( LENGTH = ${COLUMNS} - $LENGTH - 1))

  for i in {0..$LENGTH}
    do
      SPACES="$SPACES "
    done

  echo $SPACES
}

bureau_precmd () {
  local truncwidth
  ((truncwidth=${COLUMNS}-50))
  _PATH="%{$FG[$salmon]%}%$truncwidth<...<%~%<<%{$reset_color%}"
#  _1LEFT="%{$fg_bold[yellow]%}[%*]%{$reset_color%} $_USERNAME($EXTERNAL_IP_ADDRESS) $_PATH"
  _1LEFT="%{$fg_bold[yellow]%}[%*]%{$reset_color%} $_USERNAME $_PATH"
  _1RIGHT=""
  _2LEFT="$(bureau_git_prompt)"
  _1SPACES=`get_space $_1LEFT $_1RIGHT`
  echo
}

findClosestGitRepo() {
  local dir=$1
  if [ "$dir" = "" ]; then
    dir=$(pwd)
  fi
  dir=$(oscd $dir; echo $(pwd))

  if [ "$dir" = "/" ]; then
    echo "GIT_REPO_NOT_FOUND";
  elif [ -e "$dir/.git" ]; then
    echo $dir
  else
    echo $(findClosestGitRepo $(oscd "$dir/.."; echo $(pwd)))
  fi
}


gitRepo() {
  local truncwidth
  ((truncwidth=${COLUMNS}-25))
  local closestGitRepo=$(findClosestGitRepo)
  if [ "GIT_REPO_NOT_FOUND" = "$closestGitRepo" ]; then
    echo "";
  else
    echo "%{$fg[red]%}@%{$reset_color%} %{$fg[green]%}%$truncwidth<...<$closestGitRepo%<<%{$reset_color%}";
  fi
}

setopt prompt_subst
PROMPT='$_1LEFT$_1SPACES$_1RIGHT
$(bureau_git_prompt) $(gitRepo)
$_LIBERTY '

autoload -U add-zsh-hook
add-zsh-hook precmd bureau_precmd
