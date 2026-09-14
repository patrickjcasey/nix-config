{ pkgs, ... }:

{
  imports = [ ./common.nix ];

  home.packages = with pkgs; [
    clang
    gcc
    ghostty
    killall
    signal-desktop
    spotify
    tshark
    wireshark
    zoom-us
  ];

  programs.vscode.enable = true;
}
