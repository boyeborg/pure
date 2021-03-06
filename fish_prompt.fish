# Pure
# by Rafael Rinaldi
# https://github.com/rafaelrinaldi/pure
# MIT License

# Whether or not is a fresh session
set -g __pure_fresh_session 1

# Deactivate the default virtualenv prompt so that we can add our own
set -gx VIRTUAL_ENV_DISABLE_PROMPT 1

# Symbols

__pure_set_default pure_symbol_prompt "❯"
__pure_set_default pure_symbol_git_down_arrow "⇣"
__pure_set_default pure_symbol_git_up_arrow "⇡"
__pure_set_default pure_symbol_git_dirty "*"
__pure_set_default pure_symbol_horizontal_bar "—"

# Colors

__pure_set_default pure_color_blue (set_color blue)
__pure_set_default pure_color_cyan (set_color cyan)
__pure_set_default pure_color_gray (set_color 93A1A1)
__pure_set_default pure_color_magenta (set_color magenta)
__pure_set_default pure_color_normal (set_color normal)
__pure_set_default pure_color_red (set_color red)
__pure_set_default pure_color_white (set_color white)
__pure_set_default pure_color_yellow (set_color yellow)

__pure_set_default pure_color_success $pure_color_magenta
__pure_set_default pure_color_error $pure_color_red
__pure_set_default pure_color_folder $pure_color_blue
__pure_set_default pure_color_duration $pure_color_yellow
__pure_set_default pure_color_git_dirty $pure_color_gray
__pure_set_default pure_color_git_branch $pure_color_gray
__pure_set_default pure_color_git_arrow $pure_color_cyan
__pure_set_default pure_color_virtualenv $pure_color_gray
__pure_set_default pure_color_ssh_username $pure_color_gray
__pure_set_default pure_color_ssh_host $pure_color_gray
__pure_set_default pure_color_ssh_root $pure_color_white
__pure_set_default pure_color_ssh_host_user_seperator $pure_color_gray

# Determines whether the username and host are shown at the begining or end
# 0 - end of prompt, default
# 1 - start of prompt
# Any other value defaults to the default behaviour
__pure_set_default pure_user_host_location 0

# Show exit code of last command as a separate prompt character. As described here: https://github.com/sindresorhus/pure/wiki#show-exit-code-of-last-command-as-a-separate-prompt-character
# 0 - single prompt character, default
# 1 - separate prompt character
# Any other value defaults to the default behaviour
__pure_set_default pure_separate_prompt_on_error 0

# Max execution time of a process before its run time is shown when it exits
__pure_set_default pure_command_max_exec_time 5

function pre_prompt --on-event fish_prompt
  # Template
  set -l user_and_host ""
  set -l current_folder (__parse_current_folder)
  set -l git_branch_name ""
  set -l git_dirty ""
  set -l git_arrows ""
  set -l command_duration ""
  set -l pre_prompt ""

  # Do not add a line break to a brand new session
  if test $__pure_fresh_session -eq 0
    set pre_prompt $pre_prompt "\n"
  end

  # Check if user is in an SSH session
  if [ "$SSH_CONNECTION" != "" ]
    set -l host (hostname -s)
    set -l user (whoami)

    if [ "$user" = "root" ]
      set user "$pure_color_ssh_root$user"
    else
      set user "$pure_color_ssh_username$user"
    end

    # Format user and host part of prompt
    set user_and_host "$user$pure_color_ssh_host_user_seperator@$pure_color_ssh_host$host$pure_color_normal "
  end

  if test $pure_user_host_location -eq 1
    set pre_prompt $pre_prompt $user_and_host
  end

  # Format current folder on prompt output
  set pre_prompt $pre_prompt "$pure_color_folder$current_folder$pure_color_normal "

  # Exit with code 1 if git is not available
  if not type -fq git
    return 1
  end

  # Check if is on a Git repository
  set -l is_git_repository (command git rev-parse --is-inside-work-tree ^/dev/null)

  if test -n "$is_git_repository"
    set git_branch_name (__parse_git_branch)

    # Check if there are files to commit
    set -l is_git_dirty (command git status --porcelain --ignore-submodules ^/dev/null)

    if test -n "$is_git_dirty"
      set git_dirty $pure_symbol_git_dirty
    end

    # Check if there is an upstream configured
    command git rev-parse --abbrev-ref '@{upstream}' >/dev/null ^&1; and set -l has_upstream
    if set -q has_upstream
      command git rev-list --left-right --count 'HEAD...@{upstream}' | read -la git_status

      set -l git_arrow_left $git_status[1]
      set -l git_arrow_right $git_status[2]

      # If arrow is not "0", it means it's dirty
      if test $git_arrow_left != 0
        set git_arrows " $pure_symbol_git_up_arrow"
      end

      if test $git_arrow_right != 0
        set git_arrows " $git_arrows$pure_symbol_git_down_arrow"
      end
    end

    # Add color to the branch name
    set git_branch_name "$pure_color_git_branch$git_branch_name"

    # Add color to the dirty symbol
    set git_dirty "$pure_color_git_dirty$git_dirty"

    # Add color to the git arrow
    set git_arrows "$pure_color_git_arrow$git_arrows"

    # Format Git prompt output
    set pre_prompt $pre_prompt "$git_branch_name$git_dirty$git_arrows$pure_color_normal "
  end

  if test $pure_user_host_location -ne 1
    set pre_prompt $pre_prompt $user_and_host
  end

  # Prompt command execution duration
  if test -n "$CMD_DURATION"
    set command_duration (__format_time $CMD_DURATION $pure_command_max_exec_time)
  end

  set pre_prompt $pre_prompt "$pure_color_duration$command_duration$pure_color_normal"

  echo -e -s $pre_prompt
end

function fish_prompt
  set -l prompt ""

  # Save previous exit code
  set -l exit_code $status

  # Set default symbol color to the success color, meaning it's all good!
  set -l color_symbol $pure_color_success

  # Handle previous failed command
  if test $exit_code -ne 0
    # Set the symbol color to the error color when the previous command fails
    set color_symbol $pure_color_error
    if test $pure_separate_prompt_on_error -eq 1
      set color_symbol $pure_color_error$pure_symbol_prompt$pure_color_success
    end
  end

  # Show python virtualenv name (if activated)
  if test -n "$VIRTUAL_ENV"
    set prompt $prompt $pure_color_virtualenv(basename "$VIRTUAL_ENV")"$pure_color_normal "
  end

  # vi-mode indicator
  set mode_indicator (fish_default_mode_prompt)

  set prompt $prompt "$mode_indicator$color_symbol$pure_symbol_prompt$pure_color_normal "

  echo -e -s $prompt

  set __pure_fresh_session 0
end
