{ ... }:

let
  flake = "~/Horizon3/repos/nix-config#h3-mbp";
in
{
  imports = [ ../home/darwin.nix ];

  home.username = "patrickcasey";
  home.homeDirectory = "/Users/patrickcasey";

  programs.git.settings.user.email = "patrick.casey@horizon3.ai";

  # Work-specific functions live in ~/.zshrc.local, unmanaged and untracked;
  # home/common.nix sources it last.
  programs.zsh.shellAliases = {
    reload-nix = "home-manager switch -b backup --flake ${flake}";
    upgrade-nix = "nix flake update --flake ~/Horizon3/repos/nix-config && home-manager switch -b backup --flake ${flake}";
    rollback-nix = "home-manager generations";
  };
}
