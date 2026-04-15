{ lib, device ? "/dev/sda", ... }: {
  disko.devices.disk.nixos = {
    type   = "disk";
    device = lib.mkDefault device;
    content = {
      type = "gpt";
      partitions = {

        # Required for BIOS/legacy boot
        boot = {
          size = "1M";
          type = "EF02";
        };

        # EFI partition for UEFI boot
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type        = "filesystem";
            format      = "vfat";
            mountpoint  = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        # Root partition — everything else
        root = {
          size = "100%";
          content = {
            type        = "filesystem";
            format      = "ext4";
            mountpoint  = "/";
            mountOptions = [ "noatime" "discard" ];
          };
        };

      };
    };
  };
}
