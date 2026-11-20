{ do2Source, lib, pkgs, ... }:

{
  image.baseName = lib.mkForce "Montmorency-DO2-v1.1.0-x86_64";
  isoImage = {
    volumeID = "DO2_1_1_0";
    appendToMenuLabel = " DO2";
    squashfsCompression = "zstd -Xcompression-level 10";
    contents = [{
      source = do2Source;
      target = "/do2";
    }];
  };

  boot.loader.timeout = lib.mkForce 5;
  boot.plymouth.enable = lib.mkForce false;
  boot.zfs.forceImportRoot = false;
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "do2-install" ''
      set -euo pipefail
      if [[ $EUID -ne 0 ]]; then
        exec sudo -- "$0" "$@"
      fi
      work=$(mktemp -d -t do2.XXXXXXXX)
      trap 'rm -rf -- "$work"' EXIT
      cp -R -- /iso/do2/. "$work/"
      chmod -R u+w "$work"
      git -C "$work" init -q
      git -C "$work" remote add origin https://github.com/SunSinD/Projet-DO2-NixOS.git
      bash "$work/scripts/do2-install.sh"
    '')
    (pkgs.makeDesktopItem {
      name = "do2-install";
      desktopName = "Installer DO2";
      exec = "${pkgs.xterm}/bin/xterm -hold -e do2-install";
      icon = "drive-harddisk";
      categories = [ "Utility" ];
    })
  ];
}
