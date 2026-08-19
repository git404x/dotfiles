{ ... }:

{
  home.stateVersion = "24.05";

  programs = {
    eza.enable = true;
    bat.enable = true;
    yazi.enable = true;
    helix.enable = true;
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      l = "eza --icons --group-directories-first";
      ls = "eza --icons --group-directories-first";
      ll = "eza -l --icons --group-directories-first";
      la = "eza -la --icons --group-directories-first";
      lt = "eza -aT --icons --group-directories-first";
      "l." = "eza -lad --icons --group-directories-first .*";
    };
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = false;
    withRuby = false;
    withPython3 = false;
    extraConfig = ''
      set number
      set relativenumber
      set tabstop=2
      set shiftwidth=2
      set expandtab
      set clipboard=unnamedplus
    '';
  };

  programs.tmux = {
    enable = true;
    prefix = "C-a";
    baseIndex = 1;
    mouse = true;
    keyMode = "vi";
    escapeTime = 10;
    historyLimit = 10000;
    terminal = "tmux-256color";
    extraConfig = ''
      set-window-option -g automatic-rename on
      set-option -g renumber-windows on
      setw -g pane-base-index 1

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
