<a id="readme-top"></a>

<p align="left">
  <a href="#license-url" style="text-decoration: none;">
    <img 
      src="https://img.shields.io/github/license/SunSinD/Projet-DO2-NixOS.svg?style=for-the-badge&color=0078D4&logo=github&logoColor=white&labelColor=333" 
      alt="MIT License" 
      class="badge-scale"
      style="
        display: inline-block;
        transition: transform 0.2s ease-in-out;
        border-radius: 6px;
        filter: drop-shadow(0 4px 6px rgba(0,0,0,0.3));
      "
    />
  </a>
</p>

<div align="center" style="margin-top: 50px;">
  <a href="#readme-top">
    <img 
      src="https://i.imgur.com/B2AEZvK.png" 
      alt="Projet DO2 Logo" 
      width="600"
      style="
        display: block; 
        max-width: 100%; 
        height: auto; 
        transition: transform 0.2s ease-in-out; 
        border-radius: 12px;
      "
      class="badge-scale"
    />
  </a>
</div>

<h1 align="center" style="font-size: 3.5em; font-weight: 800; margin-top: 30px; margin-bottom: 10px; color: #f0f6fc;">
  Projet-DO2-NixOS
</h1>

<h3 align="center" style="color: #8b949e; margin-top: 0;">2<sup>e</sup> Vie Pour Les Ordinateurs</h3>

<br />

<div align="center" style="max-width: 800px; margin-left: auto; margin-right: auto; padding: 20px 0; border-top: 1px solid #30363d;">
  <p align="center" style="font-size: 1.15em; line-height: 1.8; color: #c9d1d9; font-weight: 400; text-align: justify; text-justify: inter-word;">
    Configuration et déploiement automatisé de NixOS pour le Projet DO2. Ce dépôt contient l'image Linux personnalisée, les scripts d'installation et la documentation technique pour la revalorisation des ordinateurs destinés à la communauté du Collège Montmorency.
  </p>
</div>

<br />

---

### Installation

**1. Booter depuis la clé USB NixOS**

**2. Se connecter au Wi-Fi (si pas de câble Ethernet) :**
```bash
nmcli device wifi connect "NOM_DU_WIFI" password "MOT_DE_PASSE"
```

**3. Lancer l'installation :**
```bash
sudo bash <(curl -sL https://raw.githubusercontent.com/SunSinD/Projet-DO2-NixOS/main/install.sh)
```

---

### Reconstruire le système (après modification du repo) :

```bash
sudo nixos-rebuild switch --flake github:SunSinD/Projet-DO2-NixOS#do2
```

### Mettre à jour :

```bash
nix flake update --flake ~/do2config/
sudo nixos-rebuild switch --flake ~/do2config/
```

[license-shield]: https://img.shields.io/github/license/SunSinD/Projet-DO2-NixOS.svg?style=for-the-badge&color=0078D4&logo=github&logoColor=white&labelColor=333
[license-url]: https://github.com/SunSinD/Projet-DO2-NixOS/blob/main/LICENSE
