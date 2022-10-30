# HSNL Matrix Setup
NixOS hosts deployed with [morph](https://github.com/DBCDK/morph);
`morph deploy --on perzik nodes.nix switch`

Secrets are encrypted in-repo with [git-crypt](https://github.com/AGWA/git-crypt)

## Servers
- perzik
Currently the only server, runs matrix-synapse with a worker configuration