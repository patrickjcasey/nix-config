{ lib, pkgs, ... }:

{
  imports = [ ./common.nix ];

  # Order 600: after common.nix (550), before machine-specific config (1000).
  programs.zsh.initContent = lib.mkOrder 600 ''
    [[ -d /opt/homebrew/bin ]] && export PATH=/opt/homebrew/bin:$PATH
  '';

  # Standalone home-manager, so there is no system layer to supply these the
  # way environment.systemPackages does on NixOS.
  home.packages = with pkgs; [
    curl
    jq
    neovim
    nerd-fonts.jetbrains-mono
    python3
    ripgrep
    stow
    unzip
    wget
  ];

  # Provides the `home-manager` CLI used by the rebuild aliases.
  programs.home-manager.enable = true;
}
