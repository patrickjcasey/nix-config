{ ... }:

{
  imports = [ ../home/linux.nix ];

  home.username = "trick";
  home.homeDirectory = "/home/trick";

  programs.git.settings.user.email = "patrick.casey1@outlook.com";

  programs.zsh.shellAliases = {
    reload-nix = "sudo nixos-rebuild switch --flake ~/nix-config#octane";
    upgrade-nix = "sudo nixos-rebuild switch --flake ~/nix-config#octane --upgrade";
    rollback-nix = "sudo nixos-rebuild switch --flake ~/nix-config#octane --rollback";
  };
}
