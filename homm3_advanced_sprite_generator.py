#!/usr/bin/env python3
"""
Générateur Avancé de Sprites HoMM3
Crée des sprites de haute qualité avec animations, effets, et style authentique
"""

import os
import sys
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import random

class HoMM3AdvancedSpriteGenerator:
    def __init__(self):
        self.sprite_size = 64
        self.output_dir = Path("C:/Dev/projet-jeu/homm-mobile/assets/homm3_advanced")
        
        # Palette HoMM3 authentique
        self.colors = {
            'grass_primary': (34, 139, 34),
            'grass_secondary': (25, 100, 25),
            'grass_dark': (20, 80, 20),
            'dirt': (139, 90, 43),
            'stone': (105, 105, 105),
            'water': (65, 105, 225),
            'water_deep': (45, 85, 205),
            'forest': (34, 100, 34),
            'forest_dark': (20, 70, 20),
            'mountain': (105, 105, 105),
            'mountain_shadow': (80, 80, 80),
            'gold': (255, 215, 0),
            'wood': (139, 90, 43),
            'ore': (192, 192, 192),
            'ui_panel': (40, 35, 30),
            'ui_border': (139, 90, 43),
            'ui_button': (139, 90, 43),
            'ui_button_hover': (169, 120, 73),
            'hero_armor': (100, 100, 120),
            'hero_cape': (180, 50, 50),
            'hero_skin': (255, 220, 177),
            'sword_steel': (192, 192, 192),
            'sword_silver': (192, 192, 192),
            'arrow_shaft': (139, 69, 19),
            'arrow_fletching': (205, 133, 63),
            'fire': (255, 100, 0),
            'ice': (200, 220, 255),
            'lightning': (255, 255, 200)
        }
        
        # Créer le répertoire de sortie
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def create_terrain_sprites(self):
        """Crée des sprites de terrain de haute qualité HoMM3"""
        terrain_dir = self.output_dir / "terrain"
        terrain_dir.mkdir(exist_ok=True)
        
        # Herbe avec variations naturelles
        for variation in range(3):
            img = Image.new('RGBA', (self.sprite_size, self.sprite_size), (0, 0, 0, 0))
            pixels = img.load()
            
            for y in range(self.sprite_size):
                for x in range(self.sprite_size):
                    # Base d'herbe
                    base_color = self.colors['grass_primary']
                    
                    # Ajouter des variations naturelles
                    noise = math.sin(x * 0.15 + variation) * math.cos(y * 0.15 + variation) * 0.3
                    if random.random() > 0.7:
                        # Herbe plus foncée
                        base_color = self.colors['grass_secondary']
                    elif random.random() > 0.9:
                        # Herbe sombre
                        base_color = self.colors['grass_dark']
                    
                    # Gradient subtil
                    gradient = 1.0 - (y / self.sprite_size) * 0.2
                    final_color = (
                        int(base_color[0] * gradient + noise * 20),
                        int(base_color[1] * gradient + noise * 15),
                        int(base_color[2] * gradient + noise * 10)
                    )
                    
                    pixels[x, y] = (*final_color, 255)
            
            # Ajouter des détails d'herbe
            self._add_grass_details(pixels)
            
            img.save(terrain_dir / f"grass_{variation}.png")
        
        # Eau avec effets de vagues
        for variation in range(3):
            img = Image.new('RGBA', (self.sprite_size, self.sprite_size), (0, 0, 0, 0))
            pixels = img.load()
            
            for y in range(self.sprite_size):
                for x in range(self.sprite_size):
                    # Base d'eau
                    wave = math.sin(x * 0.2 + variation) * 3
                    depth = (y / self.sprite_size) * 0.5
                    
                    base_color = self.colors['water']
                    if wave > 0:
                        base_color = self.colors['water_deep']
                    
                    # Effet de profondeur et de vague
                    gradient = 1.0 - depth * 0.3
                    final_color = (
                        int(base_color[0] * gradient + wave * 10),
                        int(base_color[1] * gradient + wave * 8),
                        int(base_color[2] * gradient + wave * 5)
                    )
                    
                    pixels[x, y] = (*final_color, 255)
            
            img.save(terrain_dir / f"water_{variation}.png")
        
        # Forêt avec arbres
        for variation in range(3):
            img = Image.new('RGBA', (self.sprite_size, self.sprite_size), (0, 0, 0, 0))
            pixels = img.load()
            
            for y in range(self.sprite_size):
                for x in range(self.sprite_size):
                    # Base de forêt
                    base_color = self.colors['forest']
                    
                    # Ajouter des arbres stylisés
                    if random.random() > 0.15:
                        # Tronc d'arbre
                        if x > 5 and x < 10 and y > 10 and y < 20:
                            pixels[x, y] = self.colors['forest_dark']
                        elif x > 20 and x < 25 and y > 5 and y < 15:
                            pixels[x, y] = self.colors['forest_dark']
                    
                    # Gradient subtil
                    gradient = 1.0 - (y / self.sprite_size) * 0.15
                    final_color = (
                        int(base_color[0] * gradient),
                        int(base_color[1] * gradient * 0.9),
                        int(base_color[2] * gradient * 0.8)
                    )
                    
                    pixels[x, y] = (*final_color, 255)
            
            img.save(terrain_dir / f"forest_{variation}.png")
        
        # Montagnes avec roches
        for variation in range(3):
            img = Image.new('RGBA', (self.sprite_size, self.sprite_size), (0, 0, 0, 0))
            pixels = img.load()
            
            for y in range(self.sprite_size):
                for x in range(self.sprite_size):
                    # Base de montagne
                    base_color = self.colors['mountain']
                    
                    # Ajouter des ombres et roches
                    if random.random() > 0.3:
                        base_color = self.colors['mountain_shadow']
                    
                    # Gradient pour effet 3D
                    gradient = 1.0 - (y / self.sprite_size) * 0.4
                    highlight = math.sin(x * 0.3 + variation) * 0.2
                    
                    final_color = (
                        int(base_color[0] * gradient + highlight * 30),
                        int(base_color[1] * gradient + highlight * 20),
                        int(base_color[2] * gradient + highlight * 10)
                    )
                    
                    pixels[x, y] = (*final_color, 255)
            
            img.save(terrain_dir / f"mountain_{variation}.png")
        
        print(f"✅ 12 sprites de terrain créés avec variations naturelles")
    
    def _add_grass_details(self, pixels):
        """Ajoute des détails d'herbe réalistes"""
        for y in range(5, self.sprite_size - 5, 10):
            for x in range(5, self.sprite_size - 5, 10):
                if random.random() > 0.8:
                    # Brins d'herbe
                    pixels[x, y] = self.colors['grass_secondary']
                    pixels[x+1, y] = self.colors['grass_secondary']
                    pixels[x, y+1] = self.colors['grass_secondary']
                    pixels[x, y+2] = self.colors['grass_secondary']
    
    def create_unit_sprites(self):
        """Crée des sprites d'unités animés HoMM3"""
        units_dir = self.output_dir / "units"
        units_dir.mkdir(exist_ok=True)
        
        units = {
            'swordsman': {
                'primary': (100, 100, 120),
                'secondary': (80, 80, 100),
                'metal': (192, 192, 192),
                'skin': (255, 220, 177)
            },
            'archer': {
                'primary': (34, 100, 34),
                'secondary': (20, 70, 20),
                'leather': (139, 69, 19),
                'skin': (255, 200, 150)
            },
            'knight': {
                'primary': (150, 150, 150),
                'secondary': (100, 100, 100),
                'metal': (192, 192, 192),
                'skin': (255, 180, 120)
            },
            'goblin': {
                'primary': (34, 139, 34),
                'secondary': (20, 70, 20),
                'skin': (139, 90, 60)
            },
            'skeleton': {
                'primary': (200, 200, 200),
                'secondary': (150, 150, 150),
                'bones': (255, 255, 200)
            }
        }
        
        for unit_name, unit_data in units.items():
            # Créer 8 directions pour chaque unité
            for direction in ['north', 'northeast', 'east', 'southeast', 'south', 'southwest', 'west', 'northwest']:
                for frame in range(4):  # 4 frames d'animation par direction
                    
                    img = Image.new('RGBA', (self.sprite_size, self.sprite_size), (0, 0, 0, 0))
                    pixels = img.load()
                    
                    # Dessiner l'unité selon la direction
                    self._draw_unit_sprite(pixels, unit_name, direction, frame, unit_data)
                    
                    img.save(units_dir / f"{unit_name}_{direction}_{frame}.png")
        
        print(f"✅ {len(units) * 8 * 4} sprites d'unités créés avec animations")
    
    def _draw_unit_sprite(self, pixels, unit_name, direction, frame, unit_data):
        """Dessine un sprite d'unité HoMM3 stylisé"""
        colors = unit_data
        
        # Effacer le fond
        for y in range(self.sprite_size):
            for x in range(self.sprite_size):
                pixels[x, y] = (0, 0, 0, 0)
        
        center = self.sprite_size // 2
        
        if unit_name == 'swordsman':
            self._draw_swordsman(pixels, center, colors, direction, frame)
        elif unit_name == 'archer':
            self._draw_archer(pixels, center, colors, direction, frame)
        elif unit_name == 'knight':
            self._draw_knight(pixels, center, colors, direction, frame)
        elif unit_name == 'goblin':
            self._draw_goblin(pixels, center, colors, direction, frame)
        elif unit_name == 'skeleton':
            self._draw_skeleton(pixels, center, colors, direction, frame)
    
    def _draw_swordsman(self, pixels, center, colors, direction, frame):
        """Dessine un épéiste HoMM3"""
        # Corps
        self._draw_circle(pixels, center, 12, colors['primary'])

        # Tête
        head_y = center[1] - 25
        self._draw_circle(pixels, (center[0], head_y), 8, colors['skin'])

        # Casque
        helmet_y = head_y - 8
        self._draw_circle(pixels, (center[0], helmet_y), 10, colors['metal'])

        # Épée
        if direction in ['east', 'northeast']:
            sword_start = (center[0] + 20, center[1])
            sword_end = (center[0] + 35, center[1] - 5)
        elif direction in ['west', 'northwest']:
            sword_start = (center[0] - 35, center[1])
            sword_end = (center[0] - 20, center[1] + 5)
        else:
            sword_y = center[1] - 10
            sword_start = (center[0], sword_y - 15)
            sword_end = (center[0], sword_y + 15)

        self._draw_line(pixels, sword_start, sword_end, colors['metal'], 3)

        # Bouclier
        shield_x = center[0] - 20
        self._draw_circle(pixels, (shield_x, center[1]), 8, colors['secondary'])

        # Animation
        if frame > 0:
            self._add_animation_frame(pixels, center, colors, frame)
    def _draw_archer(self, pixels, center, colors, direction, frame):
        """Dessine un archer HoMM3"""
        # Corps
        self._draw_circle(pixels, center, 10, colors['primary'])
        
        # Tête
        head_y = center - 20
        self._draw_circle(pixels, (center, head_y), 7, colors['skin'])
        
        # Arc
        if direction in ['east', 'northeast']:
            bow_start = (center + 15, center - 10)
            bow_end = (center + 25, center - 5)
        elif direction in ['west', 'northwest']:
            bow_start = (center - 25, center - 10)
            bow_end = (center - 15, center + 5)
        else:
            bow_y = center - 15
            bow_start = (center, bow_y - 12)
            bow_end = (center, bow_y + 12)
        
        self._draw_line(pixels, bow_start, bow_end, colors['leather'], 2)
        
        # Flèche
        if direction in ['east', 'northeast']:
            arrow_x = center + 30
            arrow_y = center - 5
        elif direction in ['west', 'northwest']:
            arrow_x = center - 30
            arrow_y = center - 5
        else:
            arrow_x = center
            arrow_y = center - 25
        
        # Flèche
        self._draw_line(pixels, (arrow_x, arrow_y), (arrow_x + 15, arrow_y), colors['secondary'], 1)
        
        # Animation
        if frame > 0:
            self._add_animation_frame(pixels, center, colors, frame)
    
    def _draw_knight(self, pixels, center, colors, direction, frame):
        """Dessine un chevalier HoMM3"""
        # Corps avec armure
        self._draw_circle(pixels, center, 15, colors['primary'])
        
        # Tête
        head_y = center - 30
        self._draw_circle(pixels, (center, head_y), 10, colors['skin'])
        
        # Casque
        helmet_y = head_y - 10
        self._draw_circle(pixels, (center, helmet_y), 12, colors['metal'])
        
        # Lance
        if direction in ['east', 'northeast']:
            lance_start = (center + 25, center - 15)
            lance_end = (center + 40, center - 25)
        elif direction in ['west', 'northwest']:
            lance_start = (center - 40, center - 25)
            lance_end = (center - 25, center + 25)
        else:
            lance_y = center - 20
            lance_start = (center, lance_y - 18)
            lance_end = (center, lance_y + 18)
        
        self._draw_line(pixels, lance_start, lance_end, colors['metal'], 4)
        
        # Animation
        if frame > 0:
            self._add_animation_frame(pixels, center, colors, frame)
    
    def _draw_goblin(self, pixels, center, colors, direction, frame):
        """Dessine un gobelin HoMM3"""
        # Corps
        self._draw_circle(pixels, center, 8, colors['primary'])
        
        # Tête
        head_y = center - 15
        self._draw_circle(pixels, (center, head_y), 6, colors['skin'])
        
        # Oreilles
        ear_y = head_y - 8
        self._draw_circle(pixels, (center - 4, ear_y), 3, colors['skin'])
        self._draw_circle(pixels, (center + 4, ear_y), 3, colors['skin'])
        
        # Massue
        club_x = center - 18
        club_y = center + 5
        self._draw_line(pixels, (club_x, club_y), (club_x + 8, club_y), colors['secondary'], 3)
        
        # Animation
        if frame > 0:
            self._add_animation_frame(pixels, center, colors, frame)
    
    def _draw_skeleton(self, pixels, center, colors, direction, frame):
        """Dessine un squelette HoMM3"""
        # Crâne
        self._draw_circle(pixels, center, 12, colors['primary'])
        
        # Corps
        body_y = center + 5
        self._draw_circle(pixels, (center, body_y), 10, colors['secondary'])
        self._draw_circle(pixels, (center, body_y + 8), 8, colors['secondary'])
        
        # Bras
        arm_y = body_y - 5
        self._draw_line(pixels, (center - 10, arm_y), (center - 5, arm_y + 5), colors['bones'], 2)
        self._draw_line(pixels, (center + 10, arm_y), (center + 5, arm_y + 5), colors['bones'], 2)
        
        # Animation
        if frame > 0:
            self._add_animation_frame(pixels, center, colors, frame)
    
    def _draw_circle(self, pixels, center, radius, color):
        """Dessine un cercle"""
        center_x, center_y = center
        for y in range(center_y - radius, center_y + radius):
            for x in range(center_x - radius, center_x + radius):
                dist = math.sqrt((x - center_x) ** 2 + (y - center_y) ** 2)
                if dist <= radius:
                    pixels[x, y] = color
    
    def _draw_line(self, pixels, start, end, color, width):
        """Dessine une ligne"""
        x1, y1 = start
        x2, y2 = end

        # Algorithme de ligne de Bresenham
        dx = abs(x2 - x1)
        dy = abs(y2 - y1)
        sx = 1 if x1 < x2 else -1
        sy = 1 if y1 < y2 else -1

        x, y = x1, y1
        err = dx - dy

        while True:
            # Dessiner le pixel avec la largeur
            for wx in range(-width//2, width//2 + 1):
                for wy in range(-width//2, width//2 + 1):
                    px, py = x + wx, y + wy
                    if 0 <= px < self.sprite_size and 0 <= py < self.sprite_size:
                        pixels[px, py] = color

            # Vérifier si on a atteint la fin
            if x == x2 and y == y2:
                break

            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                x += sx
            if e2 < dx:
                err += dx
                y += sy
    
    def _add_animation_frame(self, pixels, center, colors, frame):
        """Ajoute un effet d'animation"""
        offset = frame * 2
        
        # Effet de mouvement
        for i in range(3):
            alpha = 255 - (i + 1) * 60
            color = (*colors['primary'][:3], alpha)
            
            # Position décalée selon la frame
            if i == 0:
                pos = (center[0] + offset, center[1] - offset)
            elif i == 1:
                pos = (center[0] - offset, center[1] + offset)
            else:
                pos = (center[0], center[1] - offset)
            
            self._draw_circle(pixels, pos, 3, color)
    
    def generate_ui_elements(self):
        """Génère des éléments d'interface HoMM3"""
        ui_dir = self.output_dir / "ui"
        ui_dir.mkdir(exist_ok=True)
        
        # Panneau principal
        panel_img = Image.new('RGBA', (300, 200), (0, 0, 0, 0))
        pixels = panel_img.load()
        
        # Fond avec texture bois
        for y in range(200):
            for x in range(300):
                # Base bois
                base_color = self.colors['ui_panel']
                
                # Grain de bois
                if random.random() > 0.8:
                    base_color = (
                        int(base_color[0] * 0.8),
                        int(base_color[1] * 0.7),
                        int(base_color[2] * 0.6)
                    )
                
                pixels[x, y] = (*base_color, 255)
        
        # Bordure dorée
        self._draw_border(pixels, 0, 0, 300, 200, self.colors['ui_border'], 3)
        
        panel_img.save(ui_dir / "panel.png")
        
        # Boutons
        for button_type in ['normal', 'hover', 'pressed']:
            img = Image.new('RGBA', (120, 40), (0, 0, 0, 0))
            pixels = img.load()
            
            # Couleur selon le type
            if button_type == 'normal':
                button_color = self.colors['ui_button']
            elif button_type == 'hover':
                button_color = self.colors['ui_button_hover']
            else:
                button_color = self.colors['ui_border']
            
            # Fond du bouton
            for y in range(40):
                for x in range(120):
                    pixels[x, y] = button_color
            
            # Bordure
            self._draw_border(pixels, 0, 0, 120, 40, self.colors['ui_border'], 2)
            
            img.save(ui_dir / f"button_{button_type}.png")
        
        # Icônes de ressources
        resources = ['gold', 'wood', 'ore']
        for resource in resources:
            img = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
            pixels = img.load()
            
            if resource == 'gold':
                # Pièce d'or
                for y in range(32):
                    for x in range(32):
                        dist = math.sqrt((x - 16) ** 2 + (y - 16) ** 2)
                        if dist <= 12:
                            pixels[x, y] = self.colors['gold']
                        else:
                            pixels[x, y] = (255, 255, 255, 0)
                
                # Symbole $
                font = ImageFont.load_default()
                text = "$"
                # Use getbbox instead of deprecated getsize
                bbox = font.getbbox(text)
                text_width = bbox[2] - bbox[0]
                text_height = bbox[3] - bbox[1]
                text_x = (32 - text_width) // 2
                text_y = (32 - text_height) // 2

                # Draw text using ImageDraw
                draw = ImageDraw.Draw(img)
                draw.text((text_x, text_y), text, fill=self.colors['gold'], font=font)
            
            elif resource == 'wood':
                # Planche de bois
                for y in range(32):
                    for x in range(32):
                        if x < 8 or x > 24 or y < 8 or y > 24:
                            pixels[x, y] = self.colors['wood']
                        else:
                            pixels[x, y] = (255, 255, 255, 0)
            
            elif resource == 'ore':
                # Cristaux de minerai
                for y in range(32):
                    for x in range(32):
                        if x < 10 or x > 22 or y < 10 or y > 22:
                            pixels[x, y] = self.colors['ore']
                        else:
                            pixels[x, y] = (255, 255, 255, 0)
            
            img.save(ui_dir / f"{resource}_icon.png")
        
        print(f"✅ Éléments UI créés avec style HoMM3 authentique")
    
    def _draw_border(self, pixels, x, y, width, height, color):
        """Dessine une bordure"""
        for py in range(y, y + height):
            for px in range(x, x + width):
                pixels[px, py] = color
    
    def generate_hero_portraits(self):
        """Génère des portraits de héros HoMM3"""
        heroes_dir = self.output_dir / "heroes"
        heroes_dir.mkdir(exist_ok=True)
        
        heroes = {
            'knight': {
                'skin': (255, 220, 177),
                'hair': (139, 69, 19),
                'armor': (100, 100, 120),
                'background': (34, 100, 34)
            },
            'wizard': {
                'skin': (255, 200, 150),
                'hair': (200, 150, 100),
                'robe': (100, 50, 200),
                'background': (25, 25, 112)
            },
            'ranger': {
                'skin': (255, 180, 120),
                'hair': (139, 90, 60),
                'leather': (139, 69, 19),
                'background': (34, 139, 34)
            }
        }
        
        for hero_name, hero_data in heroes.items():
            img = Image.new('RGBA', (80, 80), (0, 0, 0, 0))
            pixels = img.load()
            
            # Fond
            bg_color = hero_data['background']
            for y in range(80):
                for x in range(80):
                    # Gradient subtil
                    gradient = 1.0 - (y / 80) * 0.3
                    final_color = (
                        int(bg_color[0] * gradient),
                        int(bg_color[1] * gradient * 0.9),
                        int(bg_color[2] * gradient * 0.8)
                    )
                    pixels[x, y] = (*final_color, 255)
            
            # Dessiner le portrait
            self._draw_hero_portrait(pixels, hero_name, hero_data)
            
            img.save(heroes_dir / f"{hero_name}_portrait.png")
        
        print(f"✅ 3 portraits de héros créés avec style HoMM3")
    
    def _draw_hero_portrait(self, pixels, hero_name, hero_data):
        """Dessine un portrait de héros HoMM3"""
        colors = hero_data
        center = (40, 40)
        
        # Corps
        if hero_name == 'knight':
            # Armure complète
            self._draw_circle(pixels, center, 25, colors['armor'])
            self._draw_circle(pixels, center, 20, colors['skin'])  # Tête
            self._draw_circle(pixels, (center, 30), 15, colors['hair'])  # Cheveux
            
            # Casque
            helmet_y = 30
            self._draw_circle(pixels, (center, helmet_y), 18, colors['armor'])
            self._draw_circle(pixels, (center, helmet_y), 12, colors['skin'])
            
        elif hero_name == 'wizard':
            # Robe
            self._draw_circle(pixels, center, 22, colors['robe'])
            self._draw_circle(pixels, center, 18, colors['skin'])  # Tête
            self._draw_circle(pixels, (center, 28), 15, colors['hair'])  # Cheveux
            
            # Chapeau
            hat_y = 8
            self._draw_circle(pixels, (center, hat_y), 20, colors['robe'])
            
        elif hero_name == 'ranger':
            # Tenue de cuir
            self._draw_circle(pixels, center, 20, colors['leather'])
            self._draw_circle(pixels, center, 18, colors['skin'])  # Tête
            self._draw_circle(pixels, (center, 28), 12, colors['hair'])  # Cheveux
            
            # Capuche
            hood_y = 8
            self._draw_circle(pixels, (center, hood_y), 15, colors['leather'])
    
    def generate_all_assets(self):
        """Génère tous les assets HoMM3 avancés"""
        print("=== Générateur Avancé de Sprites HoMM3 ===")
        print("Création d'assets de haute qualité avec animations et effets...")
        
        self.create_terrain_sprites()
        self.create_unit_sprites()
        self.generate_ui_elements()
        self.generate_hero_portraits()
        
        print(f"✅ Tous les assets HoMM3 avancés créés dans: {self.output_dir}")
        print("Prêt pour l'intégration dans Godot 4!")

def main():
    generator = HoMM3AdvancedSpriteGenerator()
    generator.generate_all_assets()

if __name__ == "__main__":
    main()
