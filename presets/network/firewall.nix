{ ... }:
let
  blockedIPv4 = [
    "158.101.19.243" # full-text search scraper https://macaw.social/@angilly/109597402157254670
    "207.231.106.226" # fediverse.network / fedi.ninja
    "45.81.20.80" # instances.social
    "198.58.122.231" # fedimapper.tedivm.com
    "142.93.3.121" # fedidb.org
    "45.158.40.164" # fedi.buzz
    "170.39.215.216" # fediverse.observer
    "87.157.136.163" # fedi_stats
    "94.31.103.67" # python/federation
    "45.56.100.29" # scottherr? same as :5a13
    "173.230.137.240" # scottherr@mastodon.social
    "138.37.89.34"
    "104.21.80.126" # gangstalking.services
    "172.67.181.16" # gangstalking.services
    "198.98.54.220" # ryona.agency
    "35.173.245.194"
    "99.105.215.234" # public tl
    "65.108.204.30" # unknown
    "65.109.31.111" # @fediverse@mastodont.cat
    "54.37.233.246" # fba.ryona.agency domain block scraper
    "185.244.192.119" # mooneyed.de / drow.be / bka.li blocklist scraper
    "23.24.204.110" # ryona tool fed.dembased.xyz / annihilation.social blocklist scraper
    "187.190.192.31" # ryona tool unfediblockthefedi.now
    "70.106.192.146" # blocklist scraper
    # https://openai.com/gptbot-ranges.txt
    "20.15.240.64/28"
    "20.15.240.80/28"
    "20.15.240.96/28"
    "20.15.240.176/28"
    "52.230.152.0/24"
    "52.233.106.0/24"
    "20.15.241.0/28"
    "20.15.242.128/28"
    "20.15.242.144/28"
    "20.15.242.192/28"
    "20.171.206.0/24"
    "20.171.207.0/24"
    "4.227.36.0/25"
    "172.182.201.192/28"
    "40.83.2.64/28"
  ];
  blockedIPv6 = [
    "2003:cb:ff2c:2700::1/64" # fedi_stats
    "2600:3c02::/64" # scottherr stats
    "2600:3c03::/64" # unknown, tries public tl access
    "2605:6400:10:1fe::1/64" # ryona.agency
    "2a01:4f9:5a:1cc4::2" # @fediverse@mastodont.cat
    "2604:a880:400:d1::1/64" # fedidb.org
    "2a01:4f8:162:6027::1/64" # blocklist scraper 
  ];
in
{
  networking.nftables = {
    enable = true;
    tables.wireguard = {
      # block packets from wireguard ip blocks that aren't from the wireguard interface
      family = "inet"; # v4 and v6
      content = ''
        chain input {
          type filter hook input priority 0; policy accept;

          ip saddr 10.0.0.0/24 meta iifname != "wg0" drop;
          ip6 saddr fd42:42::/36 meta iifname != "wg0" drop;
        }
      '';
    };
    tables.ipblock = {
      family = "inet"; # v4 and v6
      content = ''
        chain input {
          type filter hook input priority 0; policy accept;

          ip saddr { ${builtins.concatStringsSep ", " blockedIPv4} } drop;
          ip6 saddr { ${builtins.concatStringsSep ", " blockedIPv6} } drop;
        }
        chain output {
          type filter hook output priority 0; policy accept;

          ip daddr { ${builtins.concatStringsSep ", " blockedIPv4} } drop;
          ip6 daddr { ${builtins.concatStringsSep ", " blockedIPv6} } drop;
        }
      '';
    };
  };
}
