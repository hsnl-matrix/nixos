{ ... }:

{
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "sr_mod" "xen_blkfront" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "pool/volatile/root";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    {
      device = "pool/volatile/nix";
      fsType = "zfs";
    };

  fileSystems."/persist" =
    {
      device = "pool/safe/persist";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/E531-73DF";
      fsType = "vfat";
    };

  time.timeZone = "Europe/Amsterdam";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  boot.loader.grub = {
    device = "/dev/sda";
    enable = true;
  };

  boot.zfs.devNodes = "/dev/disk/by-partuuid";

  networking = {
    hostName = "aubergine";
    hostId = "3ae1eee7";

    defaultGateway = {
      address = "185.206.232.1";
      interface = "eth0";
    };

    defaultGateway6 = {
      address = "2a00:51c0:12:1201::1";
      interface = "eth0";
    };

    nameservers = [
      "2a00:51c0::5fd7:b906"
      "2a00:51c0::5fd7:b907"
      "95.215.185.6"
      "95.215.185.7"
    ];

    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "185.206.232.40";
        prefixLength = 24;
      }];
    };

    firewall.enable = false;
  };

  services.openssh.enable = true;
  users.extraUsers.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFILVyhJ/5AqUCXmw3KLWt0npzxTtMu7s3bzPaPSxq1U f0x@titan"
  ];

  system.stateVersion = "22.05";
}
