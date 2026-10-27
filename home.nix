{ config, pkgs, ... }:

{
  home.username = "trick";
  home.homeDirectory = "/home/trick";
  home.stateVersion = "25.05";
  imports = [ ./dictation.nix ];
  programs.bash = {
    enable = true;
  };
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      reload-nix = "sudo nixos-rebuild switch --flake ~/nix-config#octane";
      upgrade-nix = "sudo nixos-rebuild switch --flake ~/nix-config#octane --upgrade";
      rollback-nix = "sudo nixos-rebuild switch --flake ~/nix-config#octane --rollback";
    };
    history = {
      path = "$HOME/.zsh_history";
      size = 100000;
      save = 100000;
      append = true;
      share = true;
      extended = true;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      findNoDups = true;
      saveNoDups = true;
    };
    setOptions = [
      "HIST_REDUCE_BLANKS"
      "HIST_VERIFY"
    ];
    initContent = ''
      # Load Cargo environment if present
      [[ -f ~/.cargo/env ]] && source $HOME/.cargo/env
    '';
  };

  home.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    DOTFILES = "$HOME/.dotfiles";
  };
  home.sessionPath = [
    "$HOME/.cargo/bin"
    "$HOME/.rustup/bin"
  ];

  programs.starship = {
    enable = true;
    # config lives in the dotfiles repo; no settings here, so nothing is generated
    configPath = "${config.xdg.configHome}/starship/config.toml";
  };
  programs.zoxide = {
    enable = true;
    options = [
      "--cmd"
      "cd"
    ];
  };

  programs.git = {
    enable = true;
    settings.user.name = "Patrick Casey";
    settings.user.email = "patrick.casey1@outlook.com";
    settings.init.defaultBranch = "main";
    settings.core.editor = "nvim";
    settings.push.autoSetupRemote = true;
    settings.push.default = "current";
    settings.alias.wt = "worktree";
    settings.alias.wtb = "!f() { git branch -f $1 origin/$1; git worktree add $1 $1; }; f";
    settings.alias.wtr = "!f() { git worktree remove -f $1; git branch -D $1; }; f";
    settings.alias.wtnew = ''!f() { dir=$(basename "$1" .git); mkdir -p "$dir" && git clone --bare "$1" "$dir/.bare" && echo "gitdir: ./.bare" > "$dir/.git" && git -C "$dir/.bare" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' && git -C "$dir/.bare" fetch origin; }; f'';
    settings.gpg.format = "ssh";
    settings.user.signingKey = "~/.ssh/id_ed25519.pub";
    settings.commit.gpgSign = true;
    settings.tag.gpgSign = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.vscode.enable = true;
  programs.fastfetch.enable = true;
}
