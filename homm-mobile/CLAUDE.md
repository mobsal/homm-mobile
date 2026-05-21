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

## Règles pour l'agent IA
- Toujours coder en GDScript (pas C#)
- Privilégier la lisibilité sur la performance pour l'instant
- Une scène Godot par fonctionnalité majeure

## Structure du projet
res://
├── scenes/       # Scènes Godot (.tscn)
├── scripts/      # Scripts GDScript (.gd)
│   ├── hud.gd              # Interface complète (auto-gérée)
│   ├── tile_map_world.gd   # Monde, carte, héros, logique
│   ├── game_data.gd        # Singleton état global
│   ├── combat_manager.gd   # Système de combat
│   ├── map_input_controller.gd # Contrôle tactile (drag / tap+valider)
│   └── ...
├── assets/       # Images, sons
└── CLAUDE.md