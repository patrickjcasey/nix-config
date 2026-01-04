{ config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "octane";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";

  nixpkgs.config.allowUnfree = true;

  services.xserver = {
    enable = true;
    desktopManager = { xterm.enable = false; };
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        rofi
        i3status
        polybar
        xrandr
        feh
        picom
        peek
        flameshot
        i3lock
      ];
    };
  };

  programs.zsh.enable = true;
  users.users.trick = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    packages = with pkgs; [
      tree
      gcc
      clang
      lazygit
      zoxide
      starship
      rustup
      nodejs_latest
      bun
      protobuf
      buf
      gnumake
      ghostty
      cmake
      trunk
      tmux
      killall
      biome
      claude-code
    ];
    shell = pkgs.zsh;
  };

  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    stow
    jq
    fzf
    ripgrep
    python3
    unzip
    zsh
    docker
  ];

  virtualisation.docker.enable = true;

  fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.05";
}
