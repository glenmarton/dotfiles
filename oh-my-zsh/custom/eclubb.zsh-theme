# Taken from https://github.com/gabebw/dotfiles/blob/master/zsh/prompt.zsh

##########
# Colors #
##########

# Generate colors for all 256 colors
typeset -AHg fg bg

for color in {000..255}; do
  fg[$color]="%{[38;5;${color}m%}"
  bg[$color]="%{[48;5;${color}m%}"
done

ZSH_SPECTRUM_TEXT="What a neat color this is"
# Show all 256 colors with color number
spectrum_ls() {
  for code in {000..255}; do
    print -P -- "$code: %{$fg[$code]%}$ZSH_SPECTRUM_TEXT%{$reset_color%}"
  done
}

# Show all 256 colors, but set the background color, not the foreground
spectrum_bls() {
  for code in {000..255}; do
    print -P -- "$code: %{$bg[$code]%}$ZSH_SPECTRUM_TEXT%{$reset_color%}"
  done
}

prompt_color() {
  [[ -n "$1" ]] && print "%{$fg[$2]%}$1%{$reset_color%}"
}

prompt_green()  { print "$(prompt_color "$1" 002)" }
prompt_magenta(){ print "$(prompt_color "$1" 218)" }
prompt_purple() { print "$(prompt_color "$1" 146)" }
prompt_red()    { print "$(prompt_color "$1" 197)" }
prompt_cyan()   { print "$(prompt_color "$1" 159)" }
prompt_blue()   { print "$(prompt_color "$1" 031)" }
prompt_yellow() { print "$(prompt_color "$1" 222)" }
prompt_spaced() { [[ -n "$1" ]] && print " $@" }

###############################################
# Helper functions: ssh, path and exit status #
###############################################

prompt_ssh() {
  if [[ -n $SSH_CONNECTION ]]; then
    prompt_purple %n@%m:
  fi
}

prompt_path() { print "$(prompt_cyan "%~")" }

prompt_exit_status() {
  END_PROMPT=%(?.%{$(prompt_green "$")%}.%{$(prompt_red "$")%})
  print -n $END_PROMPT
}

#####################
# GIT (branch, vcs) #
#####################
#
# vcs_info docs: http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#Version-Control-Information

autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git*' formats $(prompt_blue "%b")
zstyle ':vcs_info:git*' actionformats $(prompt_red "%b|%a")

prompt_git_status_symbol(){
  local letter
  # http://www.fileformat.info/info/unicode/char/2714/index.htm
  local checkmark="\u2714"
  # http://www.fileformat.info/info/unicode/char/2718/index.htm
  local x_mark="\u2718"

  case $(prompt_git_status) in
    changed) letter=$(prompt_red $x_mark);;
    staged) letter=$(prompt_yellow "S");;
    untracked) letter=$(prompt_red "?");;
    unchanged) letter=$(prompt_green $checkmark);;
  esac

  prompt_spaced "$letter"
}

# Is this branch ahead/behind its remote tracking branch?
prompt_git_relative_branch_status_symbol(){
  local arrow;

  # http://www.fileformat.info/info/unicode/char/21e3/index.htm
  local downwards_arrow="\u21e3"
  # http://www.fileformat.info/info/unicode/char/21e1/index.htm
  local upwards_arrow="\u21e1"
  case $(prompt_git_relative_branch_status) in
    behind) arrow=$(prompt_cyan $downwards_arrow);;
    ahead) arrow=$(prompt_cyan $upwards_arrow);;
  esac

  print -n "$arrow"
}

prompt_git_status() {
  local git_status="$(cat "/tmp/git-status-$$")"
  if print "$git_status" | command grep -qF "Changes not staged" ; then
    print "changed"
  elif print "$git_status" | command grep -qF "Changes to be committed"; then
    print "staged"
  elif print "$git_status" | command grep -qF "Untracked files"; then
    print "untracked"
  elif print "$git_status" | command grep -qF "working tree clean"; then
    print "unchanged"
  fi
}

prompt_git_relative_branch_status(){
  local git_status="$(cat "/tmp/git-status-$$")"
  if print "$git_status" | command grep -qF "Your branch is behind"; then
    print "behind"
  elif print "$git_status" | command grep -qF "Your branch is ahead"; then
    print "ahead"
  fi
}

prompt_git_branch() {
  # vcs_info_msg_0_ is set by the `zstyle vcs_info` directives
  local colored_branch_name="$vcs_info_msg_0_"
  prompt_spaced "$colored_branch_name"
}

# This shows everything about the current git branch:
# * branch name
# * check mark/x mark/letter etc depending on whether branch is dirty, clean,
#   has staged changes, etc
# * Up arrow if local branch is ahead of remote branch, or down arrow if local
#   branch is behind remote branch
prompt_full_git_status(){
  if [[ -n "$vcs_info_msg_0_" ]]; then
    prompt_spaced [$(prompt_git_branch) $(prompt_git_status_symbol) $(prompt_git_relative_branch_status_symbol)]
  fi
}

# `precmd` is a magic function that's run right before the prompt is evaluated
# on each line.
# Here, it's used to capture the git status to show in the prompt.
function precmd {
  vcs_info
  git status 2> /dev/null >! "/tmp/git-status-$$"
}

# Do I have a custom git email set for this git repo? Announce it so I remember
# to unset it.
prompt_git_email(){
  git_email=$(git config user.email)
  global_git_email=$(git config --global user.email)
  if [[ "$git_email" != "$global_git_email" ]]; then
    prompt_red "[git email: $git_email]"
  fi
}

###########################
# Actually set the PROMPT #
###########################

# prompt_subst allows `$(function)` inside the PROMPT
# Escape the `$()` like `\$()` so it's not immediately evaluated when this file
# is sourced but is evaluated every time we need the prompt.
setopt prompt_subst

PROMPT='$(prompt_ssh)$(prompt_path)$(prompt_git_email)$(prompt_full_git_status) $(prompt_exit_status) '
