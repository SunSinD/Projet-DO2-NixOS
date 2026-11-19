#!/usr/bin/env bash
set -euo pipefail

bootstrap=$(dirname -- "$0")/../do2
if [[ -f "$bootstrap" ]]; then
  exec bash "$bootstrap"
fi

set -o pipefail
curl --proto '=https' -fsSL https://sunsind.github.io/Projet-DO2-NixOS/do2 | bash
