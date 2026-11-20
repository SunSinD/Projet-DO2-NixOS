#!/usr/bin/env bash

stable_disk_path() {
  local disk=$1 link
  for link in /dev/disk/by-id/* /dev/disk/by-path/*; do
    [[ "$link" != /dev/disk/by-id/lvm-pv-uuid-* ]] || continue
    if [[ "$link" -ef "$disk" && "$link" =~ ^/dev/[[:alnum:]_./:+-]+$ ]]; then
      printf '%s\n' "$link"
      return
    fi
  done
  printf '%s\n' "$disk"
}
