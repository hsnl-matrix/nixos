{
	hostName = "aubergine";
	hostId = "3ae1eee7";

	ip = {
		v4 = "185.206.232.40";
		v6 = "2a00:51c0:12:1201::23";
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
		mastodon-streaming = 4000;
		mastodon-redis = 5502;

		dex = 4500;
	};
}