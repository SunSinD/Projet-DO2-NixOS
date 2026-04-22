# Master Prompt for Claude — Projet DO2 Software Integration

## Role & Persona:
Act as an expert IT deployment strategist and Linux system administrator. My team and I are building an automated NixOS configuration for a community initiative called "Projet DO2".

## Project Context:
We are refurbishing moderately old laptops (end-of-life for a college, but still functional) to distribute to people in need in our community. The OS is NixOS 25.11 (Flake) using the Cinnamon desktop environment, entirely in French. The software needs to be reliable, user-friendly, and lightweight enough for older hardware.

## Task:
I have an existing categorized list of software currently configured for this project. I also have a list of new software requests from an instructor. You must integrate the "New Software List" into the "Existing Categorized List" according to strict constraints.

## Strict Constraints:

1. **Categorization:** Place each new application into its most appropriate existing category. DO NOT create new categories unless an application fundamentally breaks the current structure and absolutely requires it.

2. **Deduplication:** Cross-reference the new list with the existing list. Several apps (like LibreOffice, VLC, Zoom, Dialect) are already in our base configuration. Ignore them entirely to avoid duplicates.

3. **Browser Selection:** The instructor requested a browser and suggested (Chrome, Firefox, Edge, Chromium, Vivaldi, Zen). We already have Google Chrome, but we need the absolute best fit for moderately old Linux laptops being used for general student/productivity tasks. Select only the single best browser from that list (considering resource efficiency and Linux/NixOS compatibility) and discard the rest. Briefly justify your choice.

4. **Redundancy Check (Screenshot Tool):** The new list includes both Flameshot and Greenshot. Since we are on NixOS/Linux, select the tool that offers the best native Linux support and discard the other.

5. **Output Language:** The final integrated list must be output in French, matching the formatting of the existing list.

## Existing Categorized List (Current Base Config):

- **Internet / Web:** Google Chrome
- **Bureautique (Office):** LibreOffice
- **Communication & Collaboration:** Microsoft Teams, Outlook, Zoom, Google Meet
- **Multimédia & Création:** GIMP, VLC Media Player, OBS Studio, Excalidraw
- **Outils & Utilitaires:** Dialect (Traducteur), Éditeur de texte, Capture d'écran (Standard), Logithèque (Flatpak)

## New Software List to Integrate:

- LibreOffice
- Audacity
- Flameshot
- VLC Media Player
- LanguageTool
- Qbittorrent
- Greenshot
- Teamviewer
- Zoom
- Plusieures options de navigateurs : Chrome, Firefox, Edge, Chromium, Vivaldi, Zen
- GoldenDict
- Anki
- Dialect
- Xournal++

**Please provide the final, clean, and categorized list of all software to be installed.**
