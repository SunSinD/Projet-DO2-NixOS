{ pkgs, lib, ... }:

{
  # Backend requis pour Logiciels (GNOME Software)
  services.packagekit.enable = true;

  # Logiciels avec support Flatpak explicite pour éviter l'écran blanc.
  environment.systemPackages = [
    (pkgs.gnome-software.override {
      enableFlatpak = true;
    })
  ];

  # Réduit l'exposition du système de fichiers dans Nemo (vue débutant).
  programs.dconf.profiles.user.databases = lib.mkAfter [{
    settings."org/nemo/window-state" = {
      start-with-sidebar = false;
    };
  }];
}
