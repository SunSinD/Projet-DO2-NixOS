#!/usr/bin/env bash
set -euo pipefail

if [[ -f "${BASH_SOURCE[0]:-}" ]]; then
  bootstrap=$(dirname -- "${BASH_SOURCE[0]}")/../do2
  if [[ -f "$bootstrap" ]]; then
    exec bash "$bootstrap"
  fi
fi

bootstrap=$(mktemp -t do2-bootstrap.XXXXXXXX)
trap 'rm -f -- "$bootstrap"' EXIT
curl --proto '=https' -fsSL https://raw.githubusercontent.com/SunSinD/Projet-DO2-NixOS/release/do2 -o "$bootstrap"
bash "$bootstrap"
