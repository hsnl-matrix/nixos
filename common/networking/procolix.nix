{
	common,
	self,
	...
}:
{config, pkgs, lib, ...}:
{
	networking = {
		hostName = self.hostName;
		hostId = self.hostId;

		usePredictableInterfaceNames = false;
		useDHCP = false;

		nameservers = [
			"2a00:51c0::5fd7:b906"
			"2a00:51c0::5fd7:b907"
			"95.215.185.6"
			"95.215.185.7"
		];

		defaultGateway = {
			address = "185.206.232.1";
			interface = "eth0";
		};

		defaultGateway6 = {
			address = "2a00:51c0:12:1201::1";
			interface = "eth0";
		};

		interfaces.eth0 = {
			ipv4.addresses = [{
				address = self.ip.v4;
				prefixLength = 24;
			}];

			ipv6.addresses = [{
				address = self.ip.v6;
				prefixLength = 64;
			}];
		};

		firewall = {
			enable = true;
		};
	};
}