# Projet DO2 NixOS

Le projet DO2 remet en état des ordinateurs usagés du Collège Montmorency pour les donner à des personnes qui en ont besoin. Cette configuration installe NixOS avec le bureau Cinnamon en français canadien et des applications pour le travail, les études et les appels vidéo.

[Site du projet](https://sunsind.github.io/Projet-DO2-NixOS/) | [Guide d’utilisation](https://sunsind.github.io/Projet-DO2-NixOS/guides/Guide-DO2.html)

## Installer sur un ordinateur

Il faut un ordinateur x86_64, un disque interne d’au moins 32 Go et une connexion Internet pour installer DO2. L’installation efface le disque choisi. Sauvegardez les fichiers à garder et débranchez les autres disques externes. Désactivez Secure Boot dans les réglages UEFI s’il est actif.

1. Téléchargez l’[image DO2 v1.1.0](https://github.com/SunSinD/Projet-DO2-NixOS/releases/tag/v1.1.0). Comparez son empreinte SHA256 au fichier `SHA256SUMS` publié avec la version.
2. Écrivez l’image sur une clé USB avec Rufus ou balenaEtcher. Démarrez sur la clé depuis le menu de démarrage de l’ordinateur. La touche dépend du modèle. Essayez F12 ou Échap.
3. Attendez l’ouverture du bureau Cinnamon. Vous pouvez essayer le bureau depuis la clé. Pour installer DO2, connectez la machine à Internet et ouvrez le raccourci **Installer DO2**.
4. Vérifiez le modèle et la taille du disque. Tapez son chemin complet, par exemple `/dev/nvme0n1`, pour confirmer. Le temps d’installation dépend de la machine et de la connexion.
5. À la fin, choisissez le mot de passe du compte `user`. Quand le script confirme la réussite, lancez `sudo reboot`. Retirez la clé USB au redémarrage et ouvrez la session avec le mot de passe choisi.

### Avec la clé NixOS minimale

Démarrez sur l’[ISO minimale de NixOS 26.05](https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso). Connectez la machine par Ethernet, par partage USB ou avec `sudo nmcli --ask device wifi connect "NOM_DU_WIFI"`. Dans le terminal, lancez les commandes suivantes :

```bash
curl --proto '=https' -fsSL https://raw.githubusercontent.com/SunSinD/Projet-DO2-NixOS/release/do2 -o do2-install && sudo bash do2-install
```

### Vérifier le poste avant la remise

Avant de remettre l’ordinateur, redémarrez sans la clé et testez la connexion, le son, le micro, la caméra, le clavier, la luminosité et l’ouverture des applications. Le raccourci Guide DO2 est sur le bureau.

## Applications du système installé

| Usage | Applications |
|---|---|
| Web | Chrome, Firefox |
| Bureautique et études | LibreOffice, Anki, Xournal++, éditeur de texte, calculatrice |
| Communication | Zoom, TeamViewer, raccourcis web pour Teams, Outlook et Google Meet |
| Images et multimédia | GIMP, VLC, OBS Studio, Audacity, Flameshot, Excalidraw |
| Autres | Dialect, GoldenDict NG (ajoutez vos dictionnaires pour les utiliser hors ligne), qBittorrent, Logiciels (Flathub) |

Le clavier japonais peut être ajouté sur un poste avec `do2-japanese-keyboard enable`. Redémarrez ensuite et choisissez Mozc dans le panneau.

Sur la clé DO2, utilisez Firefox pour essayer le bureau. Chrome, Zoom, TeamViewer et les raccourcis web associés sont téléchargés pour le système installé.

## Mettre à jour un poste

Sur un ordinateur installé avec DO2 v1.1.0 ou une version plus récente, ouvrez le terminal et lancez :

```bash
update-do2
sudo reboot
```

La commande récupère la branche `release`. Attendez la confirmation avant de redémarrer. Une erreur de téléchargement ou de compilation laisse la configuration en place. Sur un poste qui utilise encore l’ancien mot de passe `pass`, changez-le avec `passwd`. En cas de problème au démarrage, choisissez une génération précédente dans le menu GRUB.

La configuration d’avant la dernière mise à jour est sauvegardée dans `/etc/nixos/config.previous.tar.gz`.

L’ancien outil de mise à jour de la version 1.0.0 suit encore la branche `main`. Vérifiez l’état du poste et sauvegardez les fichiers avant de choisir une mise à niveau ou une réinstallation.

## Préparer la prochaine session

Les dépendances sont épinglées dans `flake.lock`. NixOS 26.05 reçoit des mises à jour de sécurité jusqu’au 31 décembre 2026. Pour la session d’hiver 2027, passez à la version stable alors prise en charge et mettez à jour le fichier de verrouillage et les liens vers l’ISO minimale. Testez le démarrage de l’image, l’installation et la mise à jour sur un poste de test avant de faire avancer la branche `release`.

```bash
nix flake update
nix build .#nixosConfigurations.do2.config.system.build.toplevel
nix build .#nixosConfigurations.do2-iso.config.system.build.isoImage
```

L’image est dans `result/iso`. Calculez l’empreinte avec `sha256sum` avant de la publier.

L’[image DO2 v1.0.0](https://archive.org/details/montmorency-do-2-v-1.0.0) reste disponible comme archive. Pour un nouveau poste, suivez les étapes d’installation ci-dessus.
