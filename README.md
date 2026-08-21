# flclashx-flake

[![Nix flake check](https://img.shields.io/badge/nix-flake-blue)](https://github.com/pirate-boop/flclashx-flake)

Modern Clash Meta GUI packaged for NixOS with automated updates.

## Features
- 🔄 **Auto-Updating Hash:** Utilizes `update.sh` and GitHub Actions to automatically fetch new releases and update hashes.
- 🚀 **Ready to Use:** Simple flake setup for `nix run` or direct integration.

## Installation

### Using `nix run`
```bash
nix run github:pirate-boop/flclashx-flake
