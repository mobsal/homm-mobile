# Projet — Homura: Heroes of Conquest

## C'est quoi ce jeu ?
Jeu de stratégie au tour par tour mobile, inspiré de Heroes of Might & Magic 3.
Aucune ressource originale réutilisée — mécaniques seulement.
Thème japonais médiéval.

## Stack technique
- Moteur : Godot 4.6 (GDScript)
- Cible : iOS et Android
- Résolution : 1080×2400 (portrait)
- Backend (plus tard) : Supabase + Firebase Cloud Messaging

## Interface (design portrait)
L'interface est gérée par `hud.gd` (auto-contenu, étend CanvasLayer).
- **Barre du haut** : Boutons héros (H1-H3) à gauche, GH/DH/GM/DM au centre, villes (V1-V3) à droite
- **Panneau de sélection** : BT1 (nom), BT2 (couleur), barre de créatures C1-C7, BT3/BT4 (ressources)
- **Barre du bas** : GBI (image sélection), GBT (texte), ressources/or/bois/minerai, MP, date, DBI (sablier/tours), DBT (fin de tour)
- **Minimap** : Toggle via bouton GH
- **Pause** : Bouton ⏸ en bas à gauche → overlay (Continuer, Sauvegarder, Volume, Menu Principal, Quitter)
- **Zoom** : +/− en bas à gauche + pincement tactile + molette (debounce 200ms)
- **Musique** : Menu (menu.mp3), exploration (explo.mp3), combat (combat.mp3), volume global

## Règles pour l'agent IA
- Toujours coder en GDScript (pas C#)
- Privilégier la lisibilité sur la performance pour l'instant
- Une scène Godot par fonctionnalité majeure

## Structure du projet
res://
├── scenes/            # Scènes Godot (.tscn)
├── scripts/
│   ├── hud.gd               # Interface complète (auto-gérée)
│   ├── tile_map_world.gd    # Monde, carte, héros, logique, zoom, pause
│   ├── game_data.gd         # Singleton état global (+ sauvegarde JSON)
│   ├── combat_manager.gd    # Système de combat
│   ├── retro_bgm.gd         # Musique (menu/explo/combat)
│   ├── sfx_manager.gd       # Effets sonores
│   ├── loading_screen.gd    # Écran de chargement
│   ├── map_input_controller.gd  # Contrôle tactile (drag / tap+valider)
│   └── main.gd              # FontLoader
├── assets/
│   ├── music/               # menu.mp3, explo.mp3, combat.mp3
│   └── ...
└── CLAUDE.md

## Notes techniques
- `retro_bgm.gd` : `_menu_player` pour le menu, `_player` pour jeu ; `_theme = ""` initialement pour éviter l'early-return
- Pause/zoom boutons reparentés dans `SystemOverlay` (CanvasLayer.layer=128) pour rester visibles en combat
- Menu pause créé sur un CanvasLayer.layer=128 dédié (visible par‑dessus le combat)
- Sauvegarde : `FileAccess.WRITE` → `user://save_game.json` (un seul fichier, écrase à chaque sauvegarde)
- Zoom tactile : `_touch_points[event.index]`, pinch détecté via `event.position.distance_to()`
- Export APK : `package/signed=false`, `config/icon="res://icon.svg"`
