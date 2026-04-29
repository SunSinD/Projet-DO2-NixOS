{ lib, ... }:

{
  # Backend requis pour Logiciels (GNOME Software)
  services.packagekit.enable = true;

  # Réduit l'exposition du système de fichiers dans Nemo (vue débutant).
  programs.dconf.profiles.user.databases = lib.mkAfter [{
    settings."org/nemo/window-state" = {
      start-with-sidebar = false;
    };
  }];
}
