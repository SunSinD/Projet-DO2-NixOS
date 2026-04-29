# Projet DO2 — Recommandations d'implémentation (NixOS immuable, public débutant)

Ce document propose des améliorations **concrètes** orientées pour un public « zéro terminal ».

## 1) Installation « one-click » avec auto-sélection de disque (safe fallback)

### Pourquoi
- Aujourd'hui, l'installateur demande un choix interactif du disque et une confirmation texte (`oui/non`), ce qui est fiable pour un technicien, mais pas idéal pour une chaîne d'installation rapide sur 140 portables.
- Le partitionnement Disko est déjà BIOS+UEFI compatible, ce qui est excellent.

### Implémentation proposée
- Ajouter un mode `--auto` au script `do2-install.sh` :
  - exclut le disque d'amorçage ISO,
  - ignore les périphériques USB,
  - choisit automatiquement **le plus grand disque interne**,
  - garde un fallback interactif si ambiguïté.

```bash
# Exemple d'ajout en haut de do2-install.sh
AUTO_MODE=false
if [[ "${1:-}" == "--auto" ]]; then
  AUTO_MODE=true
fi

# Après la construction de DISK_NAMES
pick_best_disk() {
  local best="" best_size=0
  for d in "${DISK_NAMES[@]}"; do
    # taille en bytes
    s=$(lsblk -bdno SIZE "/dev/$d" 2>/dev/null || echo 0)
    # ignorer USB
    if lsblk -no TRAN "/dev/$d" 2>/dev/null | grep -qi usb; then
      continue
    fi
    if [[ "$s" -gt "$best_size" ]]; then
      best_size="$s"
      best="$d"
    fi
  done
  [[ -n "$best" ]] && echo "$best"
}

if $AUTO_MODE; then
  best_disk=$(pick_best_disk || true)
  if [[ -n "$best_disk" ]]; then
    DEV="/dev/$best_disk"
    echo "  [AUTO] Disque choisi: $DEV"
  else
    echo "  [AUTO] Aucun disque interne clair, retour mode interactif."
  fi
fi
```

---

## 2) Swap dimensionné automatiquement selon RAM/disque

### Pourquoi
- Le swapfile est actuellement fixe à 4G. Sur des machines 4–8G RAM, c'est parfois trop petit; sur des SSD limités, parfois trop grand.

### Implémentation proposée
- Dans `do2-install.sh`, calculer dynamiquement la taille (`min(8G, max(2G, RAM))`) avec limite par espace disque.

```bash
# Remplacer bloc swap statique dans do2-install.sh
ram_gb=$(awk '/MemTotal/ { printf "%d", ($2/1024/1024)+0.5 }' /proc/meminfo)
if [[ "$ram_gb" -lt 2 ]]; then target_swap_gb=2
elif [[ "$ram_gb" -gt 8 ]]; then target_swap_gb=8
else target_swap_gb="$ram_gb"
fi

sudo mkdir -p /mnt/var/lib
sudo fallocate -l "${target_swap_gb}G" /mnt/var/lib/swapfile
sudo chmod 600 /mnt/var/lib/swapfile
sudo mkswap /mnt/var/lib/swapfile
sudo swapon /mnt/var/lib/swapfile
```

---

## 3) « Unbreakable » côté utilisateur: génération protégée + rollback GUI

### Pourquoi
- Vous avez déjà le socle immuable NixOS, mais l'expérience de reprise doit être visible en GUI pour un novice.

### Implémentation proposée
- Augmenter `boot.loader.grub.configurationLimit` (ex: 8 au lieu de 1).
- Ajouter un lanceur bureau « Restaurer version précédente » qui exécute un script root minimal (pkexec + `nixos-rebuild --rollback switch`) puis redémarre.

```nix
# modules/core.nix
boot.loader.grub.configurationLimit = 8;

# Script système
environment.systemPackages = [
  (pkgs.writeShellScriptBin "do2-rollback" ''
    set -euo pipefail
    pkexec /run/current-system/sw/bin/nixos-rebuild --rollback switch
    pkexec /run/current-system/sw/bin/systemctl reboot
  '')
];
```

```nix
# modules/desktop.nix — raccourci desktop
environment.etc."skel/Desktop/Restaurer-DO2.desktop".text = ''
  [Desktop Entry]
  Name=Restaurer version précédente
  Exec=do2-rollback
  Icon=system-reboot
  Terminal=false
  Type=Application
  Categories=System;
'';
```

---

## 4) Mises à jour automatiques non intrusives + redémarrage différé

### Pourquoi
- Le service `do2-auto-update` existe déjà: très bonne base.
- Il manque une politique utilisateur explicite: quand redémarrer sans perturber l'usage.

### Implémentation proposée
- Conserver update en fond, mais notifier en GUI qu'un redémarrage est requis.
- Exécuter update via timer (ex: nuit) et pas seulement au boot réseau.

```nix
# modules/core.nix
systemd.timers.do2-auto-update = {
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "*-*-* 03:30:00";
    Persistent = true;
    RandomizedDelaySec = "30m";
  };
};
```

```bash
# fin du script do2-auto-update (ExecStart)
if [ -f /run/current-system/sw/bin/notify-send ]; then
  su - user -c 'DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    notify-send "DO2" "Mise à jour installée. Redémarrez quand vous êtes prêt."' || true
fi
```

---

## 5) App Store simplifié (GUI only) + politique Flatpak

### Pourquoi
- Vous avez déjà `gnome-software` + Flatpak + Flathub bootstrap.
- Pour des débutants, limiter les surfaces de confusion augmente la réussite.

### Implémentation proposée
- Ajouter plugins Flatpak GNOME Software explicitement.
- Masquer sources non nécessaires et prioriser Flathub.

```nix
# modules/software.nix
environment.systemPackages = with pkgs; [
  gnome-software
  gnome-software-plugin-flatpak
  flatpak
];

services.flatpak.enable = true;
```

---

## 6) Welcome app orientée bénéficiaire (pas seulement post-install QA)

### Pourquoi
- `do2-welcome.sh` actuel est orienté technicien (checklist de remise), pas bénéficiaire.

### Implémentation proposée
- Créer un mode double:
  - `--technicien` (actuel),
  - `--utilisateur` (premier démarrage): Wi‑Fi, mot de passe, ouvrir guide, ouvrir app store.

```bash
# do2-welcome.sh (idée)
MODE="${1:-utilisateur}"
if [[ "$MODE" == "technicien" ]]; then
  # popup checklist existante
else
  yad --title="Bienvenue sur votre ordinateur" \
    --text="1) Connectez-vous au Wi‑Fi\n2) Changez votre mot de passe\n3) Ouvrez le Guide DO2" \
    --button="Ouvrir Guide:0" --button="Plus tard:1"
  [ $? -eq 0 ] && xdg-open /etc/do2/guides/Guide-DO2.html
fi
```

---

## 7) Sécuriser la maintenance locale contre suppression accidentelle

### Pourquoi
- `update-do2` fait un `git reset --hard` et `clean -fd` dans `/etc/nixos/config` : efficace mais brutal.

### Implémentation proposée
- Sauvegarder plus de fichiers machine-locaux (ex. overrides futurs) dans `/var/lib/do2-backups/` avant reset.

```bash
# update-do2 dans modules/core.nix
BACKUP_DIR=/var/lib/do2-backups
sudo mkdir -p "$BACKUP_DIR"
sudo cp "$CONFIG/hardware-configuration.nix" "$BACKUP_DIR/hardware-configuration.nix"
# ajouter ici d'autres fichiers locaux si besoin
```

---

## 8) Accessibilité débutants: taille police, contraste, assistance

### Pourquoi
- Le public cible inclut des personnes potentiellement peu à l'aise visuellement/numériquement.

### Implémentation proposée
- Définir par défaut:
  - facteur de texte 1.1–1.2,
  - thème haut contraste en option,
  - raccourci « Aide rapide DO2 » sur le bureau.

```nix
# modules/desktop.nix, dans dconf defaults
"org/cinnamon/desktop/interface" = {
  text-scaling-factor = 1.1;
  enable-animations = false;
};
```

---

## Plan de déploiement recommandé (140 machines)

1. **Pilote 5 machines**: activer mode `--auto`, swap dynamique, timer update.
2. **Vérification terrain 1 semaine**: incidents Wi‑Fi, boot, update, app installs.
3. **Vague 1 (40 machines)**: activer rollback GUI + welcome utilisateur.
4. **Vague 2 (95 machines)**: rollout complet + support guide imprimé 1 page.

---

## Résultat attendu
- Installation plus rapide pour l'équipe (moins d'input humain).
- Expérience bénéficiaire sans terminal.
- Meilleure résilience perçue (rollback visible).
- Maintenance silencieuse, avec interruption minimale.
