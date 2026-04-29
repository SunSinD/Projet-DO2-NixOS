# Options « débutant » sans patch de paquets.
# Nemo : l’entrée « Système de fichiers » dans la barre latérale est retirée en
# recomposant pkgs.nemo (voir flake.nix, ./patches/nemo-hide-filesystem-sidebar.patch).
# Il n’existe pas de clef GSettings pour masquer seulement cette entrée.
# Logiciels / Flatpak : modules/software.nix ; packagekit : modules/core.nix.
{ ... }:

{ }
