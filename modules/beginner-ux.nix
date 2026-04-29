{ lib, ... }:

{
  # Module de compatibilité:
  # Certaines branches importent encore ./modules/beginner-ux.nix.
  # On garde ce fichier sans override fragile pour éviter les échecs de build.
  services.packagekit.enable = true;

  programs.dconf.profiles.user.databases = lib.mkAfter [{
    settings."org/nemo/window-state" = {
      start-with-sidebar = false;
    };
  }];
}
