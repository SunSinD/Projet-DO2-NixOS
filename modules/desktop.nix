# Bureau Cinnamon, panneau, fond d'ecran, clavier, audio.
{ config, pkgs, lib, ... }:

{
  # ── Serveur X / Cinnamon ────────────────────────────────────────────────
  services.xserver.enable = true;
  services.xserver.xkb.layout  = "ca";
  services.xserver.xkb.variant = "";

  services.xserver.displayManager.lightdm.enable   = lib.mkDefault true;
  services.xserver.displayManager.lightdm.background = "#000000";
  services.xserver.desktopManager.cinnamon.enable   = lib.mkDefault true;

  # Auto-login (Cinnamon se charge pendant le boot = bureau instantane)
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user   = "user";

  # Fond noir avant que Cinnamon se charge (pas de flash du bureau)
  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xsetroot}/bin/xsetroot -solid black &
  '';

  # ── Exclure les apps Cinnamon inutiles ──────────────────────────────────
  environment.cinnamon.excludePackages = with pkgs; [
    celluloid        # on a VLC
    pix              # on a GIMP
    gnome-calendar   # pas essentiel
    hexchat          # pas necessaire
    warpinator       # transfert reseau local inutile
  ];

  # ── Desactiver la mise en veille prolongee (hibernate) ──────────────────
  systemd.targets.hibernate.enable    = false;
  systemd.targets.hybrid-sleep.enable = false;
  systemd.sleep.extraConfig = ''
    AllowHibernation=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
  '';

  # ── Arret/redemarrage rapide ────────────────────────────────────────────
  systemd.settings.Manager.DefaultTimeoutStopSec = "1s";

  # Cacher le bureau au shutdown/reboot (ecran noir au lieu du taskbar)
  systemd.services.hide-desktop-on-shutdown = {
    description = "Hide desktop on shutdown";
    wantedBy = [ "graphical.target" ];
    after    = [ "graphical.target" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      ExecStart       = "/run/current-system/sw/bin/true";
      ExecStop        = "${pkgs.kbd}/bin/chvt 1";
    };
  };
  # ── Audio (PipeWire) ────────────────────────────────────────────────────
  security.rtkit.enable = true;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };

  # ── Peripheriques d'entree ──────────────────────────────────────────────
  services.libinput.enable      = true;
  services.xserver.wacom.enable = true;

  # ── Energie ─────────────────────────────────────────────────────────────
  services.upower.enable                = true;
  services.power-profiles-daemon.enable = true;

  # ── Trousseau de cles (deverrouille automatiquement, pas de popup) ──────
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.lightdm.enableGnomeKeyring           = true;
  security.pam.services.lightdm-autologin.enableGnomeKeyring = true;

  # ── Fond d'ecran ────────────────────────────────────────────────────────
  environment.etc."backgrounds/do2-wallpaper.png".source = ../assets/do2-wallpaper.png;

  # ── Configuration du premier demarrage ──────────────────────────────────
  environment.etc."do2/do2-setup-user.sh" = {
    source = ../do2-setup-user.sh;
    mode   = "0755";
  };
  environment.etc."do2/do2-welcome.sh" = {
    source = ../do2-welcome.sh;
    mode   = "0755";
  };
  environment.etc."do2/guides/Guide-DO2.html".source = ../guides/Guide-DO2.html;

  # Configurations Cinnamon (applets du panneau)
  # Note : @ est interdit dans les chemins Nix, donc on concatene une chaine.
  environment.etc."do2/config/cinnamon/spices/grouped-window-list@cinnamon.org/2.json".source =
    ../config/config/cinnamon/spices + "/grouped-window-list@cinnamon.org/2.json";
  environment.etc."do2/config/cinnamon/spices/menu@cinnamon.org/0.json".source =
    ../config/config/cinnamon/spices + "/menu@cinnamon.org/0.json";

  # Verrouiller l'ecran au demarrage (mot de passe requis)
  environment.etc."xdg/autostart/do2-lock-screen.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=DO2 Lock Screen
    Exec=bash -c "sleep 0.5 && cinnamon-screensaver-command --lock"
    Terminal=false
    X-GNOME-Autostart-enabled=true
    NoDisplay=true
  '';

  # Lancer la configuration utilisateur au login (autostart)
  environment.etc."xdg/autostart/do2-setup-user.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=DO2 Configuration utilisateur
    Exec=/etc/do2/do2-setup-user.sh
    Terminal=false
    X-GNOME-Autostart-enabled=true
    NoDisplay=true
  '';

  # ── Parametres dconf par defaut (Cinnamon) ──────────────────────────────
  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      settings = {
        # Fond d'ecran
        "org/cinnamon/desktop/background" = {
          picture-uri      = "file:///etc/backgrounds/do2-wallpaper.png";
          picture-options  = "zoom";
        };

        # Clavier francais canadien
        "org/cinnamon/desktop/input-sources" = {
          sources = [ (lib.gvariant.mkTuple [ "xkb" "ca" ]) ];
        };

        # Panneau en bas + performances
        "org/cinnamon" = {
          panels-enabled = [ "1:0:bottom" ];
          panels-height  = [ "1:40" ];
          favorite-apps  = [ "cinnamon-settings.desktop" "nemo.desktop" ];
          desktop-effects    = false;
          startup-animation  = false;
          enabled-applets = [
            "panel1:left:0:menu@cinnamon.org:0"
            "panel1:left:1:grouped-window-list@cinnamon.org:2"
            "panel1:right:0:systray@cinnamon.org:3"
            "panel1:right:1:xapp-status@cinnamon.org:4"
            "panel1:right:2:notifications@cinnamon.org:5"
            "panel1:right:3:printers@cinnamon.org:6"
            "panel1:right:4:removable-drives@cinnamon.org:7"
            "panel1:right:5:network@cinnamon.org:8"
            "panel1:right:6:sound@cinnamon.org:9"
            "panel1:right:7:power@cinnamon.org:10"
            "panel1:right:8:calendar@cinnamon.org:11"
            "panel1:right:9:cornerbar@cinnamon.org:12"
          ];
        };

        # Bureau avec icones
        "org/nemo/desktop" = {
          desktop-layout   = "true::false";
          show-desktop-icons = true;
        };

        # Session : pas de delai pour shutdown/reboot/logout
        "org/cinnamon/desktop/session" = {
          idle-delay  = lib.gvariant.mkUint32 900;
        };
        "org/gnome/SessionManager" = {
          logout-prompt = false;
        };

        # Performances : desactiver les animations pour fluidite
        "org/cinnamon/desktop/interface" = {
          gtk-theme       = "Mint-Y-Dark-Aqua";
          icon-theme      = "Mint-Y-Dark-Aqua";
          enable-animations = false;
        };
        "org/cinnamon/muffin" = {
          unredirect-fullscreen-windows = true;
        };
        "org/cinnamon/theme" = {
          name = "Mint-Y-Dark-Aqua";
        };

        # Ecran de verrouillage
        "org/cinnamon/desktop/screensaver" = {
          lock-enabled = true;
          lock-delay   = lib.gvariant.mkUint32 0;
        };
      };
    }];
  };

  # ── Polices ─────────────────────────────────────────────────────────────
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      liberation_ttf
      dejavu_fonts
      cantarell-fonts
      ubuntu-classic
      roboto
      freefont_ttf
      corefonts
    ];
    fontDir.enable = true;
    fontconfig.defaultFonts = {
      sansSerif = [ "Noto Sans" "DejaVu Sans" ];
      serif     = [ "Noto Serif" "DejaVu Serif" ];
      monospace = [ "Noto Sans Mono" "DejaVu Sans Mono" ];
    };
  };

  # ── Intégration Qt (thème sombre pour GoldenDict, qBittorrent, Anki) ────
  qt = {
    enable = true;
    platformTheme = "gtk2";
    style = "adwaita-dark";
  };
