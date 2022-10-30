{
	common,
	self,
	...
}:
{config, pkgs, lib, ...}:
{
	networking = {
		useNetworkd = true;
    hostName = self.hostName;
    hostId = self.hostId;
	};

	systemd.network = {
		networks = {
			"10-eth0" = {
				matchConfig.Type = "ether";
				address = builtins.attrValues self.ip;
				routes = [
					{ routeConfig.Gateway = "fe80::1"; }
					{ routeConfig = { Destination = "172.31.1.1"; }; }
					{ routeConfig = { Gateway = "172.31.1.1"; GatewayOnLink = true; }; }
					# prevent some local traffic Hetzner doesn't like
					{ routeConfig = { Destination = "172.16.0.0/12"; Type = "unreachable"; }; }
					{ routeConfig = { Destination = "192.168.0.0/16"; Type = "unreachable"; }; }
					# { routeConfig = { Destination = "10.0.0.0/8"; Type = "unreachable"; }; }
					{ routeConfig = { Destination = "fc00::/7"; Type = "unreachable"; }; }
				];
			};
		};
	};
}