if status is-interactive
  set -gx PATH $HOME/.local/bin $PATH
  set -gx PATH $HOME/.cargo/bin $PATH
    # Commands to run in interactive sessions can go here
end

source $__fish_config_dir/alias.fish
source $__fish_config_dir/env.fish
