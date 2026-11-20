{ lib, device, ... }:

let
  partition = index:
    let
      suffix =
        if lib.hasPrefix "/dev/disk/" device then "-part"
        else if builtins.match ".*[0-9]" device != null then "p"
        else "";
    in "${device}${suffix}${toString index}";
in {
  disko.devices.disk.nixos = {
    type   = "disk";
    device = lib.mkDefault device;
    content = {
      type = "gpt";
      partitions = {

        # Required for BIOS/legacy boot
        boot = {
          priority = 1;
          size = "1M";
          type = "EF02";
        };

        # EFI partition for UEFI boot
        ESP = {
          priority = 2;
          device = partition 2;
          size = "1G";
          type = "EF00";
          content = {
            type        = "filesystem";
            format      = "vfat";
            mountpoint  = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        # Root partition (everything else)
        root = {
          priority = 3;
          device = partition 3;
          size = "100%";
          content = {
            type        = "filesystem";
            format      = "ext4";
            mountpoint  = "/";
            mountOptions = [ "noatime" ];
          };
        };

      };
    };
  };
}
