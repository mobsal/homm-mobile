#!/usr/bin/env python3
"""
HoMM3 Improved Version Generator
Creates a truly HoMM3-like experience with proper terrain, UI, and gameplay
"""

import os
import sys
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import random

class HoMM3ImprovedGenerator:
    def __init__(self):
        self.tile_size = 64
        self.map_width = 30
        self.map_height = 30
        
        # HoMM3 authentic color palette
        self.terrain_colors = {
            'grass': (34, 139, 34),
            'dirt': (139, 90, 43),
            'water': (65, 105, 225),
            'mountain': (105, 105, 105),
            'forest': (34, 100, 34),
            'plains': (180, 140, 90)
        }
    
    def create_homm3_terrain_tile(self, terrain_type, variation=0):
        """Create authentic HoMM3 terrain tile"""
        img = Image.new('RGB', (self.tile_size, self.tile_size), self.terrain_colors[terrain_type])
        pixels = img.load()
        
        if terrain_type == 'grass':
            # Add grass texture
            for _ in range(20):
                x = random.randint(0, self.tile_size - 1)
                y = random.randint(0, self.tile_size - 1)
                size = random.randint(2, 6)
                for dx in range(-size, size):
                    for dy in range(-size, size):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < self.tile_size and 0 <= ny < self.tile_size:
                            if dx*dx + dy*dy <= size*size:
                                if random.random() > 0.5:
                                    pixels[nx, ny] = (25, 100, 25)
        
        elif terrain_type == 'water':
            # Add wave effect
            for y in range(0, self.tile_size, 4):
                for x in range(self.tile_size):
                    wave_height = math.sin(x * 0.2 + variation) * 3
                    py = int(y + wave_height)
                    if 0 <= py < self.tile_size:
                        if (x + py) % 8 < 4:
                            pixels[x, py] = (85, 125, 235)
        
        elif terrain_type == 'mountain':
            # Add rocky texture
            for _ in range(30):
                x = random.randint(0, self.tile_size - 1)
                y = random.randint(0, self.tile_size - 1)
                size = random.randint(1, 4)
                for dx in range(-size, size):
                    for dy in range(-size, size):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < self.tile_size and 0 <= ny < self.tile_size:
                            if dx*dx + dy*dy <= size*size:
                                if random.random() > 0.6:
                                    pixels[nx, ny] = (130, 130, 130)
        
        return img
    
    def generate_improved_assets(self, output_dir):
        """Generate improved HoMM3 assets"""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        # Create terrain directory
        terrain_dir = output_path / "terrain"
        terrain_dir.mkdir(exist_ok=True)
        
        # Generate improved terrain tiles
        terrain_types = ['grass', 'dirt', 'water', 'mountain', 'forest', 'plains']
        for terrain_type in terrain_types:
            for variation in range(3):
                tile = self.create_homm3_terrain_tile(terrain_type, variation)
                tile.save(terrain_dir / f'{terrain_type}_{variation}.png')
        
        print(f"Generated improved HoMM3 assets in: {output_dir}")

def main():
    output_dir = r"C:\Dev\projet-jeu\homm-mobile\assets"
    
    generator = HoMM3ImprovedGenerator()
    generator.generate_improved_assets(output_dir)

if __name__ == "__main__":
    main()
