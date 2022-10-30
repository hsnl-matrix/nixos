{
	self,
	ports,
	semiSecrets,
	...
}:
{config, pkgs, lib, ...}:

rec {
	imports = [
    ../../../../synapse-workers/module.nix
	];

	disabledModules = [
		"services/matrix/matrix-synapse.nix"
	];

	services = {
		redis.servers.default = {
			enable = true;
			port = 6379;
			appendOnly = true;
		};
		matrix-synapse = {
			enable = true;
			package = import ../../../../synapse-workers/package.nix {inherit pkgs;};
      withJemalloc = true;
      dataDir = "/persist/synapse";

			workers = {
				enable = true;
				cache_factor = "1";

				appserviceWorker = "appservice";

				nginxVhostConfig = {
					listen = [{
						addr = "localhost";
						port = ports.synapse-nginx;
					}];
				};

				mainListener = {
					bind_address = "localhost";
					port = ports.synapse-main;
				};

				replication = {
					shared_secret = semiSecrets.synapse.workerSharedSecret;
					port = ports.synapse-replication;
				};

				redis = {
					createLocally = false;
				};

				workers = {
					sync = {
						app = "generic_worker";
						listener = {
							bind_address = "localhost";
							port = ports.synapse-sync;
							resources = ["client" "metrics"];
						};
						routes = [ # all Sync routes
							"~ ^/_matrix/client/(v2_alpha|r0|v3)/sync$"
							"~ ^/_matrix/client/(api/v1|v2_alpha|r0|v3)/events$"
							"~ ^/_matrix/client/(api/v1|r0|v3)/initialSync$"
							"~ ^/_matrix/client/(api/v1|r0|v3)/rooms/[^/]+/initialSync$"
						];
					};

					fed = {
						app = "generic_worker";
						listener = {
							bind_address = "localhost";
							port = ports.synapse-fed;
							resources = ["client" "federation" "metrics"];
						};
						routes = [ # all fed routes
							"~ ^/_matrix/federation/v1/event/"
							"~ ^/_matrix/federation/v1/state/"
							"~ ^/_matrix/federation/v1/state_ids/"
							"~ ^/_matrix/federation/v1/backfill/"
							"~ ^/_matrix/federation/v1/get_missing_events/"
							"~ ^/_matrix/federation/v1/publicRooms"
							"~ ^/_matrix/federation/v1/query/"
							"~ ^/_matrix/federation/v1/make_join/"
							"~ ^/_matrix/federation/v1/make_leave/"
							"~ ^/_matrix/federation/v1/send_join/"
							"~ ^/_matrix/federation/v2/send_join/"
							"~ ^/_matrix/federation/v1/send_leave/"
							"~ ^/_matrix/federation/v2/send_leave/"
							"~ ^/_matrix/federation/v1/invite/"
							"~ ^/_matrix/federation/v2/invite/"
							"~ ^/_matrix/federation/v1/query_auth/"
							"~ ^/_matrix/federation/v1/event_auth/"
							"~ ^/_matrix/federation/v1/exchange_third_party_invite/"
							"~ ^/_matrix/federation/v1/user/devices/"
							"~ ^/_matrix/federation/v1/get_groups_publicised$"
							"~ ^/_matrix/key/v2/query"
							"~ ^/_matrix/federation/unstable/org.matrix.msc2946/spaces/"
							"~ ^/_matrix/federation/(v1|unstable/org.matrix.msc2946)/hierarchy/"
						];
					};

					fed_out1 = {
						app = "federation_sender";
						listener = {
							bind_address = "localhost";
							port = ports.synapse-fed_out1;
						};
						routes = ["replication" "metrics"];
					};
					fed_out2 = {
						app = "federation_sender";
						listener = {
							bind_address = "localhost";
							port = ports.synapse-fed_out2;
						};
						routes = ["replication" "metrics"];
					};
					fed_out3 = {
						app = "federation_sender";
						listener = {
							bind_address = "localhost";
							port = ports.synapse-fed_out3;
						};
						routes = ["replication" "metrics"];
					};
					fed_out4 = {
						app = "federation_sender";
						listener = {
							bind_address = "localhost";
							port = ports.synapse-fed_out4;
						};
						routes = ["replication" "metrics"];
					};

					events = {
						app = "generic_worker";
						streamWriter = "events";
						listener = {
							bind_address = "localhost";
							port = ports.synapse-events;
							resources = ["replication" "metrics"];
						};
						routes = [ ]; # don't get any traffic directly
					};

					typing = {
						app = "generic_worker";
						streamWriter = "typing";
						listener = {
							bind_address = "localhost";
							port = ports.synapse-typing;
							resources = ["client" "metrics"];
						};
						routes = [
							"~ ^/_matrix/client/(api/v1|r0|v3|unstable)/rooms/.*/typing/"
						];
					};

					appservice = {
						app = "generic_worker";
						listener = {
							bind_address = "localhost";
							port = ports.synapse-appservice;
							resources = ["client" "metrics"];
						};
						routes = [];
					};
				};
			};

      settings = {
			  server_name = "matrix-test.hsnl.im";
			  enable_registration = false;
			  registration_shared_secret = semiSecrets.synapse.registrationSharedSecret;
			  enable_metrics = true;
        report_state = false;
        presence.enabled = true;
        auto_join_rooms = [
					"#hsnl:matrix-test.hsnl.im"
				];

			  listeners = [
				  {
					  port = ports.synapse-main;
					  bind_addresses = ["localhost"];
					  type = "http";
					  tls = false;
					  x_forwarded = true;
					  resources = [
						  {
							  names = [ "client" "federation" ];
							  compress = false;
						  }
					  ];
				  }
				  {
					  port = ports.synapse-metrics;
					  bind_addresses = ["localhost"];
					  type = "metrics";
					  tls = false;
					  x_forwarded = true;
					  resources = [
				 		  {
				 			  names = [ ];
				 			  compress = false;
				 		  }
					  ];
				  }
			  ];
			  max_upload_size = "50M";
      };
		};
	};

	systemd.services = {
		matrix-synapse.serviceConfig.ExecStartPre = lib.mkOverride 10 "";
	};
}