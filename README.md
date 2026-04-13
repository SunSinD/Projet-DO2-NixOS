<a id="readme-top"></a>

<p align="left">
  <a href="https://github.com/SunSinD/Projet-DO2-NixOS/blob/main/LICENSE">
    </a>
    <img src="https://img.shields.io/github/license/SunSinD/Projet-DO2-NixOS.svg?style=for-the-badge&color=0078D4&logo=github&logoColor=white&labelColor=333" alt="MIT License" />
  </a>
  <img src="https://img.shields.io/badge/NixOS-25.11-5277C3?style=for-the-badge&logo=nixos&logoColor=white&labelColor=333" alt="NixOS 25.11" />
  <img src="https://img.shields.io/badge/GNOME-Français-4A86CF?style=for-the-badge&logo=gnome&logoColor=white&labelColor=333" alt="GNOME Français" />
</p>

<div align="center">
  <a href="#readme-top">
    <img src="https://i.imgur.com/B2AEZvK.png" alt="Projet DO2 Logo" width="600" />
  </a>
</div>

<h1 align="center">Projet-DO2-NixOS</h1>
<h3 align="center">2<sup>e</sup> Vie Pour Les Ordinateurs</h3>

<div align="center">
  <p align="center">
    Configuration et déploiement automatisé de NixOS pour le Projet DO2.<br/>
    Ce dépôt contient l'image Linux personnalisée, les scripts d'installation et la documentation technique<br/>
    pour la revalorisation des ordinateurs destinés à la communauté du Collège Montmorency.
  </p>
  <a href="https://sunSinD.github.io/Projet-DO2-NixOS"><strong>Site Web du Projet</strong></a>
</div>

<br/>

---

## À propos

Le projet DO2, Don d'ordinateur, Deuxième vie, redonne vie à des ordinateurs usagés du Collège Montmorency pour les distribuer gratuitement à des immigrants en cours de francisation. Chaque machine est livrée avec une installation NixOS complète, entièrement en français, prête à l'emploi.

| | |
|---|---|
| **Distro** | NixOS 25.11 (stable) |
| **Bureau** | GNOME, interface en français |
| **Installation** | Automatisée, 1 commande |
| **Deadline** | 22 mai 2026 |

---

## Applications incluses

| Application | Usage |
|---|---|
| Google Chrome | Navigateur web |
| LibreOffice | Bureautique (texte, tableur, présentations) |
| Dialect | Traducteur |
| MPV | Lecteur vidéo et audio |
| Gmail | Courriel (web) |
| Outlook | Courriel Microsoft (web) |
| Microsoft Teams | Messagerie (web) |
| Google Meet | Vidéoconférence (web) |
| Zoom | Vidéoconférence (natif) |
| Excalidraw | Dessin collaboratif (web) |
| GNOME Fichiers | Gestionnaire de fichiers |

---

## Installation

**1. Booter depuis la clé USB NixOS** (ISO minimal, pas graphique)

**2. Se connecter au Wi-Fi** si pas de câble Ethernet :
```bash
nmcli device wifi connect "NOM_DU_WIFI" password "MOT_DE_PASSE"
```

**3. Lancer l'installation :**
```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/SunSinD/Projet-DO2-NixOS/main/install.sh)"
```

Le script détecte le disque, partitionne, installe tout et redémarre automatiquement. Durée : **10 à 30 minutes**.

> Identifiants par défaut — Utilisateur : `user` · Mot de passe : `pass`

---

## Reconstruire le système

Après une modification du repo, depuis n'importe quelle machine déjà installée :
```bash
sudo nixos-rebuild switch --flake github:SunSinD/Projet-DO2-NixOS#do2 --no-write-lock-file
```

> Le flag `--no-write-lock-file` est requis quand on rebuild directement depuis GitHub (pas de repo local).

---

## Mettre à jour les dépendances

```bash
nix flake update --flake /etc/nixos
sudo nixos-rebuild switch --flake github:SunSinD/Projet-DO2-NixOS#do2 --no-write-lock-file
```

---

*Collège Montmorency · Département de technologie de génie électrique · 243-44A-MO · Hiver 2026*

[license-shield]: https://img.shields.io/github/license/SunSinD/Projet-DO2-NixOS.svg?style=for-the-badge&color=0078D4&logo=github&logoColor=white&labelColor=333
[license-url]: https://github.com/SunSinD/Projet-DO2-NixOS/blob/main/LICENSE
