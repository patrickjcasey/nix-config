{ config, pkgs, ... }:

{
  home.username = "trick";
  home.homeDirectory = "/home/trick";
  home.stateVersion = "25.05";
  programs.bash = { enable = true; };
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      reload-nix = "sudo nixos-rebuild --flake ~/nix-config#octane switch";
    };
    initContent = ''
      # Load Cargo environment if present
      [[ -f ~/.cargo/env ]] && source $HOME/.cargo/env

      # --- History options ---
      setopt HIST_EXPIRE_DUPS_FIRST
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_IGNORE_SPACE
      setopt HIST_FIND_NO_DUPS
      setopt HIST_SAVE_NO_DUPS
      setopt SHARE_HISTORY
      setopt HIST_REDUCE_BLANKS
      setopt INC_APPEND_HISTORY
      setopt EXTENDED_HISTORY
      setopt HIST_VERIFY
      setopt appendhistory
      HISTFILE=~/.zsh_history
      HISTSIZE=100000
      SAVEHIST=100000

      # --- Environment variables ---
      export XDG_CONFIG_HOME=$HOME/.config
      export DOTFILES=$HOME/.dotfiles
      export PATH="$HOME/.cargo/bin:$HOME/.rustup/bin:$PATH"

      # --- fzf integration (Nix version) ---
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh

      # --- Aliases ---
      alias vim=nvim

      # --- Starship prompt ---
      eval "$(starship init zsh)"
      export STARSHIP_CONFIG=$HOME/.config/starship/config.toml

      # --- zoxide ---
      eval "$(zoxide init zsh --cmd cd)"
    '';
  };

  programs.git = {
    enable = true;
    settings.user.name = "Patrick Casey";
    settings.user.email = "patrick.casey1@outlook.com";
    settings.init.defaultBranch = "main";
    extraConfig = { core.editor = "nvim"; };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.vscode.enable = true;
  programs.fastfetch.enable = true;
  #  programs.opencode.enable=true;
  programs.tmux.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };
}
