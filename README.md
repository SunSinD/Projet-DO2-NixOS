<a id="readme-top"></a>

<p align="left">
  <a href="https://github.com/SunSinD/Projet-DO2-NixOS/blob/main/LICENSE">
      </a>
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

Le projet DO2 redonne vie à des ordinateurs usagés du Collège Montmorency pour les donner à des personnes qui en ont besoin.

<br/>

<table>
  <tbody>
    <tr>
      <td><strong>Distribution</strong></td>
      <td>NixOS 25.11 (Flake)</td>
    </tr>
    <tr>
      <td><strong>Bureau</strong></td>
      <td>Cinnamon, interface en français</td>
    </tr>
    <tr>
      <td><strong>Installation</strong></td>
      <td>Automatisée, une commande, environ 10 min</td>
    </tr>
  </tbody>
</table>

<br/>

---

## Applications incluses

<br/>

| Application | Usage |
|---|---|
| Google Chrome | Navigateur web |
| Firefox | Navigateur web |
| LibreOffice | Bureautique (Writer, Calc, Draw, Impress, Math, Base) |
| Anki | Cartes mémoire (flashcards) |
| Xournal++ | Annotation PDF / prise de notes |
| Microsoft Teams | Messagerie et appels vidéo |
| Outlook | Courriel Microsoft |
| Zoom | Vidéoconférence |
| Google Meet | Vidéoconférence |
| TeamViewer | Contrôle à distance / support technique |
| Dialect | Traducteur |
| GoldenDict | Dictionnaire multilingue hors ligne |
| GIMP | Éditeur d'images |
| VLC | Lecteur multimédia |
| OBS Studio | Enregistrement vidéo |
| Audacity | Édition audio |
| Flameshot | Capture d'écran |
| Éditeur de texte | Bloc-notes |
| qBittorrent | Client torrent |
| Excalidraw | Dessin collaboratif |
| Logiciels | Installation d'apps (Flatpak) |

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
curl -sL sunsind.github.io/Projet-DO2-NixOS/do2 | sudo bash
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
