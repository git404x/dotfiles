{ config, pkgs, ... }:

let
  c = config.lib.stylix.colors.withHashtag;
in
{
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    baseIndex = 1;
    mouse = true;
    keyMode = "vi";
    escapeTime = 10;
    historyLimit = 10000;
    terminal = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      vim-tmux-navigator
      tmux-which-key
      {
        plugin = minimal-tmux-status;
        extraConfig = ''
          bind-key b set-option status # toggle statusbar
          set -g @plugin 'niksingh710/minimal-tmux-status'
          set -g @minimal-tmux-status-left "#(whoami)@#H"
          set -g @minimal-tmux-status-right "%R #S"
          set -g @minimal-tmux-indicator false
          set -g @minimal-tmux-fg "${c.base00}"
          set -g @minimal-tmux-bg "${c.base08}"
        '';
      }
    ];

    extraConfig = ''
      set-window-option -g automatic-rename on
      set-option -g renumber-windows on
      setw -g pane-base-index 1

      # keybinds
      unbind r
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config Reloaded"

      # session/window mgmt
      bind R command-prompt -I "#S" "rename-session '%%'"
      bind N command-prompt -I "#W" "rename-window '%%'"
      bind x kill-pane
      bind w kill-window

      # split
      unbind '%'
      bind '\' split-window -h
      unbind '"'
      bind '-' split-window -v

      # navigation
      bind -r h select-pane -L
      bind -r j select-pane -D
      bind -r k select-pane -U
      bind -r l select-pane -R

      # resize
      bind -r j resize-pane -D 4
      bind -r k resize-pane -U 4
      bind -r l resize-pane -R 4
      bind -r h resize-pane -L 4
      bind -r m resize-pane -Z

      # window navigate
      bind -n M-1 select-window -t 1
      bind -n M-2 select-window -t 2
      bind -n M-3 select-window -t 3
      bind -n M-4 select-window -t 4
      bind -n M-5 select-window -t 5
      bind -n M-6 select-window -t 6
      bind -n M-7 select-window -t 7
      bind -n M-8 select-window -t 8
      bind -n M-9 select-window -t 9

      # copy mode
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection
      unbind -T copy-mode-vi MouseDragEnd1Pane
    '';
  };
}
