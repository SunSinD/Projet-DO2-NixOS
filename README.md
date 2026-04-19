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
    Configuration NixOS automatisée pour le Projet DO2.<br/>
    Installation en une commande, interface Cinnamon en français, prête à l'emploi.<br/>
  </p>
  <a href="https://sunSinD.github.io/Projet-DO2-NixOS"><strong>Site Web du Projet</strong></a>
</div>

<br/>

---

## À propos

Le projet DO2 (Don d'ordinateur, Deuxième vie) redonne vie à des ordinateurs usagés du Collège Montmorency pour les distribuer à des personnes dans le besoin. Chaque machine est livrée avec NixOS, entièrement en français, prête à l'emploi.

| | |
|---|---|
| **Distro** | NixOS 25.11 (Flake) |
| **Bureau** | Cinnamon, interface en français |
| **Installation** | Automatisée, 1 commande, 5-15 min |

---

## Applications incluses

| Application | Usage |
|---|---|
| Google Chrome | Navigateur web |
| LibreOffice | Bureautique (Writer, Calc, Draw, Impress, Math, Base) |
| Microsoft Teams | Messagerie et appels vidéo |
| Outlook | Courriel Microsoft |
| Zoom | Vidéoconférence |
| Dialect | Traducteur de langues |
| GIMP | Éditeur d'images |
| VLC | Lecteur vidéo et audio |
| Excalidraw | Dessin collaboratif |
| Logithèque (Flatpak) | Installation d'apps via interface graphique |

---

## Installation

**1. Démarrer depuis la clé USB NixOS** (ISO minimal)

Insérez la clé USB. Allumez l'ordinateur et appuyez sur `F12` (ou `Échap` / `F2`) pour ouvrir le menu de démarrage, puis sélectionnez la clé USB.

> **Important :** Choisissez la première option : **NixOS LTS**. Ne choisissez pas la version avec des chiffres.

> **Hint :** Si `F12` ne fonctionne pas, essayez `F10`, `F11` ou `Del`. Sur certains ThinkPads, c'est le bouton *Novo* près du port d'alimentation.

**2. Se connecter au réseau**

**Tethering USB (au Collège) :**

Connectez votre téléphone au Wi-Fi `Le_College_Montmorency`, complétez le portail, puis branchez le téléphone par USB et activez le tethering.

- **Android :** Paramètres → Connexions → Point d'accès mobile → Modem USB → Activer
- **iPhone :** Réglages → Partage de connexion → Autoriser les autres à rejoindre

**Wi-Fi normal (maison) :**
```bash
nmcli device wifi connect "NOM_DU_WIFI" password "MOT_DE_PASSE"
```

**3. Vérifier la connexion :**
```bash
ping -c 3 github.com
```

**4. Lancer l'installation :**
```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/SunSinD/Projet-DO2-NixOS/main/install.sh)"
```

Le script affiche `[0]`, `[1]`, etc. : entrez **seulement le chiffre** (0 ou 1). Durée : **5 à 15 minutes**.

> Identifiants par défaut : Utilisateur : `user` / Mot de passe : `pass`

---

## Mise à jour

Sur un ordinateur déjà installé :

```bash
update-do2
sudo reboot
```

---

*Collège Montmorency · Département de technologie de génie électrique · 243-44A-MO · Hiver 2026*
