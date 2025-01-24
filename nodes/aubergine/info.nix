rec {
  hostId = "3ae1eee7";

  endpoint = "hsnl.social";

  ip = {
    v4 = "185.206.232.40";
    v6 = "2a00:51c0:12:1201::23";
  };

  ports = {
    mastodon-web = 5500;
    mastodon-streaming = 4000;
    mastodon-redis = 5502;
  };
}
