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

configure_machine() {
  local disk=$1 flake=$2 vendor product chromebook=false
  vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)
  product=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
  if [[ "$vendor" == Google && "$product" != "Google Compute Engine" ]]; then
    chromebook=true
  fi
  if ! grep -Fq 'device = "/dev/sda"; # DO2_DISK' "$flake"; then
    echo "Paramètre du disque DO2 introuvable dans $flake." >&2
    return 1
  fi
  sed -i \
    -e "s|device = \"/dev/sda\"; # DO2_DISK|device = \"$disk\"; # DO2_DISK|" \
    -e "s|chromebook = false; # DO2_CHROMEBOOK|chromebook = $chromebook; # DO2_CHROMEBOOK|" \
    "$flake"
}
