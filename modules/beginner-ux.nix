{ lib, ... }:

{
  # Logiciels / Flatpak : gnome-software est dans modules/software.nix ;
  # packagekit dans core.nix. Dans nixpkgs 25.11, gnome-software est toujours
  # compilé avec le support Flatpak (l’argument enableFlatpak n’existe plus).

  # Réduit l'exposition du système de fichiers dans Nemo (vue débutant).
  programs.dconf.profiles.user.databases = lib.mkAfter [{
    settings."org/nemo/window-state" = {
      start-with-sidebar = false;
    };
  }];
}
