{ pkgs, lib, _info, _nodes, ... }: {
  imports = [
    ./system/erase-your-darlings.nix
    ./services/postgres.nix
    ./system/zsh.nix
  ];

  documentation.nixos.enable = false;
  time.timeZone = "Europe/Amsterdam";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  nixpkgs.overlays = [
    (self: super: {
      f0x-utility = (pkgs.callPackage ../packages/utility.nix { });
    })
  ];

  nix = {
    nixPath = [ "nixpkgs=${pkgs.path}" ];
    settings.auto-optimise-store = true;
  };

  systemd.network.wait-online.anyInterface = true;

  networking = {
    hostName = _info.hostName;
    hostId = _info.hostId;
    useDHCP = false;
    usePredictableInterfaceNames = false;
  };

  services = {
    openssh = {
      enable = true;
      hostKeys = [
        {
          path = "/persist/ssh/ed25519_key";
          type = "ed25519";
        }
        {
          path = "/persist/ssh/rsa_key";
          type = "rsa";
          bits = 4096;
        }
      ];
    };
  };

  users.extraUsers.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFILVyhJ/5AqUCXmw3KLWt0npzxTtMu7s3bzPaPSxq1U f0x@titan"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP5ut6TySQ5gfZppuvYlLGlTtIWH3cSBlEGMY97mnq2F f0x@ouroboros"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJehNxG/l2agu6B4j2W+jVPuBHQqpEfakA3wupQkdP+ peter@raamwerk"
  ];

  users.extraUsers.root.home = lib.mkOverride 10 "/persist/root";

  security = {
    acme = {
      defaults.email = "acme@cthu.lu";
      acceptTerms = true;
    };
  };

  fileSystems."/var/lib/acme" = {
    device = "/persist/ssl";
    options = [ "bind" ];
  };

  environment = {
    pathsToLink = [ "/share/zsh" ];
    systemPackages = with pkgs; [
      wget
      neovim
      htop
      dfc
      eza
      curl
      ripgrep
      git-crypt
      git-lfs
      nodejs
      yarn
      gdu
      git
      nethogs
      iotop
      screen
      f0x-utility
    ];
  };
}
