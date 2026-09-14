{ lib, pkgs, ... }:

{
  home.stateVersion = "25.05";

  # Cross-platform user tooling. Platform-only packages live in
  # ./linux.nix and ./darwin.nix; per-machine additions live in ../machines.
  home.packages = with pkgs; [
    biome
    btop
    buf
    bun
    cargo-msrv
    claude-code
    cmake
    gh
    gnumake
    lazygit
    marksman
    nodejs_latest
    protobuf
    pyright
    ruff
    rustup
    starship
    tmux
    tree
    trunk
    ty
    uv
    zoxide
  ];

  programs.bash = {
    enable = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      vim = "nvim";
    };
    # mkOrder 550 keeps this ahead of machine-specific initContent (default
    # order 1000) and the ~/.zshrc.local hook (mkAfter) below.
    initContent = lib.mkMerge [
      (lib.mkOrder 550 ''
        bindkey -e

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
        HISTSIZE=1000000
        SAVEHIST=1000000

        # --- Environment variables ---
        export EDITOR="nvim"
        export GIT_EDITOR=$EDITOR
        export XDG_CONFIG_HOME=$HOME/.config
        export DOTFILES=$HOME/.dotfiles
        export PATH="$HOME/.cargo/bin:$HOME/.rustup/bin:$PATH"

        # --- Starship prompt ---
        eval "$(starship init zsh)"
        export STARSHIP_CONFIG=$HOME/.config/starship/config.toml

        # --- zoxide ---
        eval "$(zoxide init zsh --cmd cd)"
      '')

      # Escape hatch, kept last: anything not managed by Nix. Externally
      # rewritten blocks (e.g. `heat self workstation init`) belong here,
      # since Nix owns ~/.zshrc and the store is read-only.
      (lib.mkAfter ''
        [[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
      '')
    ];
  };

  # user.email is intentionally omitted; each machine sets its own identity.
  programs.git = {
    enable = true;
    settings.user.name = "Patrick Casey";
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

  programs.fastfetch.enable = true;
}
