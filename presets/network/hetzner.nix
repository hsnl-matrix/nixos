{ _info, ... }: {
  networking = {
    defaultGateway = {
      address = "172.31.1.1";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };

    nameservers = [ "8.8.8.8" "8.8.4.4" ];

    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = _info.ip.v4;
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = _info.ip.v6;
        prefixLength = 64;
      }];
    };
  };
}
