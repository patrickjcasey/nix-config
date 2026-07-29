{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "octane";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Phoenix";

  nixpkgs.config.allowUnfree = true;

  hardware.graphics = {
    enable = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  nixpkgs.config.nvidia.acceptLicense = true;

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    desktopManager = {
      xterm.enable = false;
    };
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        rofi
        i3status
        (polybar.override { i3Support = true; })
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
    extraGroups = [
      "wheel"
      "docker"
      "wireshark"
    ];
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
      spotify
      signal-desktop
      btop
      tshark
      wireshark
      marksman
      pyright
      cargo-msrv
      uv
      ruff
      ty
      zoom-us
      gh
    ];
    shell = pkgs.zsh;
  };

  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    neovim
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

  # enable dynamically linked executables
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add any missing dynamic libraries for unpackaged programs
    # here, NOT in environment.systemPackages
  ];

  fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  system.stateVersion = "25.05";

}
