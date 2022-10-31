{
	hostName = "perzik";
	hostId = "1e13ec65";

	# has = {
	# 	backup = true;
	# 	wireguard = true;
	# 	metrics = true;
	# };

	ip = {
		v4 = "95.216.212.21/32";
		v6 = "2a01:4f9:c010:1b7a::1/64";
	};

	ports = {
		synapse-nginx = 8008;
		synapse-metrics = 9000;
		synapse-main = 15001;
		synapse-replication = 15002;
		synapse-sync = 15003;
		synapse-fed = 15004;
		synapse-events = 15005;
		synapse-typing = 15006;
		synapse-appservice = 15007;
		synapse-fed_out1 = 15101;
		synapse-fed_out2 = 15102;
		synapse-fed_out3 = 15103;
		synapse-fed_out4 = 15104;

		mastodon-web = 5500;
		mastodon-streaming = 5501;
		mastodon-redis = 5502;

		dex = 4500;
	};

	# sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKZ4RskorIZzBBhOZdNkQQuss7KPbF9eyejFuQfBywyt root@aura";
}