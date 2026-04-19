<a id="readme-top"></a>

<p align="left">
  <a href="https://github.com/SunSinD/Projet-DO2-NixOS/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/SunSinD/Projet-DO2-NixOS.svg?style=for-the-badge&color=0078D4&logo=github&logoColor=white&labelColor=333" alt="MIT License" />
  </a>
  <img src="https://img.shields.io/badge/NixOS-25.11-5277C3?style=for-the-badge&logo=nixos&logoColor=white&labelColor=333" alt="NixOS 25.11" />
  <img src="https://img.shields.io/badge/Cinnamon-Français-4A86CF?style=for-the-badge&logo=linux&logoColor=white&labelColor=333" alt="Cinnamon Français" />
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
    Configuration NixOS automatisée pour le Projet DO2 du Collège Montmorency.<br/>
    Installation en une commande, prête à l'emploi.
  </p>
  <a href="https://sunSinD.github.io/Projet-DO2-NixOS"><strong>Site Web du Projet</strong></a>
</div>

<br/>

---

## À propos

Le projet DO2 redonne vie à des ordinateurs usagés du Collège Montmorency pour les distribuer à des personnes dans le besoin.

<br/>

| | |
|---|---|
| **Distro** | NixOS 25.11 (Flake) |
| **Bureau** | Cinnamon, interface en français |
| **Installation** | Automatisée, 1 commande, ~10 min |

<br/>

---

## Applications incluses

<br/>

| Application | Usage |
|---|---|
| Google Chrome | Navigateur web |
| LibreOffice | Bureautique (Writer, Calc, Draw, Impress, Math, Base) |
| Microsoft Teams | Messagerie et appels vidéo |
| Outlook | Courriel Microsoft |
| Zoom | Vidéoconférence |
| Google Meet | Vidéoconférence |
| Dialect | Traducteur |
| GIMP | Éditeur d'images |
| VLC | Lecteur multimédia |
| OBS Studio | Enregistrement vidéo |
| Éditeur de texte | Bloc-notes |
| Capture d'écran | Capture d'écran |
| Excalidraw | Dessin collaboratif |
| Logithèque | Installation d'apps (Flatpak) |

<br/>

---

## Installation

<br/>

**1.** Démarrer depuis la clé USB NixOS (ISO minimal). Appuyez sur `F12` au démarrage.

> **Hint :** Si `F12` ne fonctionne pas, essayez `F10`, `F11` ou `Del`.

<br/>

**2.** Connectez-vous au réseau (tethering USB ou Wi-Fi).

<br/>

**3.** Vérifiez la connexion :
```bash
nmcli device status
```

<br/>

**4.** Lancez l'installation :
```bash
curl -sL sunsind.github.io/Projet-DO2-NixOS/i | sudo bash
```
Le script vous guide pour le reste. Durée : **5 à 15 minutes**.

<br/>

> Identifiants par défaut — Utilisateur : `user` · Mot de passe : `pass`

<br/>

---

## Mise à jour

<br/>

```bash
update-do2
sudo reboot
```

<br/>

---

*Collège Montmorency · Département de technologie de génie électrique · 243-44A-MO · Hiver 2026*
