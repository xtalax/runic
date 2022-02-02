set segment_separator \uE0B0
set -g right_segment_separator \uE0B2


set -q color_vi_mode_indicator; or set color_vi_mode_indicator black
set -q color_vi_mode_normal; or set color_vi_mode_normal green
set -q color_vi_mode_insert; or set color_vi_mode_insert blue 
set -q color_vi_mode_visual; or set color_vi_mode_visual red


# ===========================
# Cursor setting

# You can set these variables in config.fish like:
# set -g cursor_vi_mode_insert bar_blinking
# ===========================
set -q cursor_vi_mode_normal; or set cursor_vi_mode_normal box_steady
set -q cursor_vi_mode_insert; or set cursor_vi_mode_insert bar_steady
set -q cursor_vi_mode_visual; or set cursor_vi_mode_visual box_steady

# Color Variables
function posix-source
	for i in (cat $argv)
    if string match -r -q "color[0-9]{1,2}=\'#(?:[0-9,a-f,A-F]{6})\'" $i
      echo $i
      set arr (echo $i |tr = \n)
      set -gx $arr[1] (string sub --start=-7 --length 6 $arr[2])
    end
  end
end

posix-source $HOME/.cache/wal/colors.sh

set -g normal normal
set -g white $color15
set -g black $color0
set -g red $color1
set -g green $color2
set -g orange $color3
set -g blue $color4
set -g purple $color5
set -g cyan $color6
set -g gray $color7
set -g darkgray $color8
set -g brightred $color9
set -g brightgreen $color10
set -g yellow $color11
set -g brightblue $color12
set -g magenta $color13

# ===========================
# Segments functions
# ===========================

function prompt_right_segment -d "Function to draw a segment"
  set -l bg
  set -l fg
  if [ -n "$argv[3]" ]
    if [ -n "$argv[1]" ]
      set bg $argv[1]
    else
      set bg normal
    end
    if [ -n "$argv[2]" ]
      set fg $argv[2]
    else
      set fg normal
    end
    if [ "$argv[1]" != "$current_bg" -a ]
      set_color -b $normal
      set_color $bg
      echo -n "$right_segment_separator"
      set_color -b $bg
      set_color $fg
    else
      set_color -b $bg
      set_color $fg
    end
    set current_bg $argv[1]
    echo -n -s -e $argv[3]
    set_color normal
    set_color $current_bg
    echo -n "$segment_separator"
    set_color normal
    if [ (id -u) -eq 0 ]
      echo -n (set_color $red)'─'
    else
      echo -n (set_color $purple)'─'
    end
  end
end

function prompt_vi_mode -d 'vi mode status indicator'
  switch $fish_bind_mode
      case default
        prompt_right_segment $color_vi_mode_normal $black "N"
      case insert
        prompt_right_segment $color_vi_mode_insert $black "I"
      case visual
        prompt_right_segment $color_vi_mode_visual $black "V"
    end
end

function __tmux_prompt
  set multiplexer (_is_multiplexed)

  switch $multiplexer
    case screen
      set pane (_get_screen_window)
    case tmux
      set pane (_get_tmux_window)
   end

  if test -z $pane
  else
    prompt_right_segment $white $black $pane
  end
end

function _get_tmux_window
  # tmux lsw | grep active | sed 's/\*.*$//g;s/: / /1' | awk '{ print $2 "-" $1 }' -
end

function _get_screen_window
  set initial (screen -Q windows; screen -Q echo "")
  set middle (echo $initial | sed 's/  /\n/g' | grep '\*' | sed 's/\*\$ / /g')
  echo $middle | awk '{ print $2 "-" $1 }' -
end

function _is_multiplexed
  set multiplexer 
  if test -z $TMUX
  else
    set multiplexer "tmux"
  end
  if test -z $WINDOW
  else
    set multiplexer "screen"
  end
  echo $multiplexer
end

function __print_duration
  set -l duration $argv[1]
 
  set -l millis  (math $duration % 1000)
  set -l seconds (math -s0 $duration / 1000 % 60)
  set -l minutes (math -s0 $duration / 60000 % 60)
  set -l hours   (math -s0 $duration / 3600000 % 60)

  set -l time
 
  if test $duration -lt 60000;
    # Below a minute
    set time (printf "%d.%03ds" $seconds $millis)
  else if test $duration -lt 3600000;
    # Below a hour
    set time (printf "%02d:%02d.%03d" $minutes $seconds $millis)
  else
    # Everything else
    set time (printf "%02d:%02d:%02d.%03d" $hours $minutes $seconds $millis)
  end
  echo $time
end

function prompt_status -d "the symbols for a non zero exit status, root and background jobs"

    if [ "$fish_private_mode" ]
      prompt_right_segment $color_status_private_bg $color_status_private_str "🔒"
    end

    # Jobs display
    if [ (jobs -l | wc -l) -gt 0 ]
      prompt_right_segment $color_status_jobs_bg $color_status_jobs_str "⚙"
    end
end

function fish_right_prompt 
  set -l exit_code $status
  set -l cmd_duration $CMD_DURATION
  set -l code_color
  set -l time_color

  prompt_status

  if [ $exit_code -ne 0 ]
    prompt_right_segment $black $color_status_nonzero_str "✘"
  end

  if test $exit_code -ne 0
    set code_color $red
  else
    set code_color $lightgreen
  end
  prompt_right_segment $code_color $black $exit_code
  
  if test $cmd_duration -ge 5000
    set time_color $orange
  else
    set time_color $blue
  end
  prompt_right_segment $time_color $black (__print_duration $cmd_duration)
  # set_color 666666
  # NOTE: ipatch, date taking too much space
  # printf ' < %s' (date +%H:%M:%S)
  __tmux_prompt
  prompt_vi_mode
  set_color normal
end

