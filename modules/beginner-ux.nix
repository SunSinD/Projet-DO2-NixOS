{ pkgs, lib, ... }:

{
  # Module de compatibilité fusionnable:
  # - certaines branches importent encore ./modules/beginner-ux.nix
  # - on évite volontairement tout override fragile (ex: enableFlatpak)
  #   qui casse selon la version de nixpkgs.
  services.packagekit.enable = true;

  # Garder une référence explicite au paquet pour éviter des conflits
  # "suppression vs ajout" entre branches sans toucher aux overrides.
  environment.systemPackages = [ pkgs.gnome-software ];

  programs.dconf.profiles.user.databases = lib.mkAfter [{
    settings."org/nemo/window-state" = {
      start-with-sidebar = false;
    };
  }];
}
