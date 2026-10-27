{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  # keep /boot (1G) from filling up with old kernels
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "octane";
  networking.networkmanager.enable = true;
  # trust traffic on the LAN
  networking.firewall.trustedInterfaces = [ "eno2" ];

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
      marksman
      pyright
      cargo-msrv
      uv
      ruff
      ty
      zoom-us
      gh
      # nixpkgs sets dontPatchELF, so node-pty's prebuilt pty.node (new in
      # 0.0.45) can't find libstdc++ and the backend server crashes on start.
      (t3code.override {
        t3code-unwrapped = t3code.unwrapped.overrideAttrs (old: {
          postFixup = (old.postFixup or "") + ''
            find "$out"/libexec/t3code -path '*/node-pty/prebuilds/linux-x64/pty.node' \
              -exec ${lib.getExe patchelf} --add-rpath ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]} {} +
          '';
        });
      })
      herdr
    ];
    shell = pkgs.zsh;
  };

  programs.firefox.enable = true;

  # creates the wireshark group and a dumpcap wrapper so captures work without root
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };

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
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  system.stateVersion = "25.05";

}
