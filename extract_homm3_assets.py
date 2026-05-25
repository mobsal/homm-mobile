#!/usr/bin/env python3
"""
Extracteur simple de ressources HoMM3 (.lod files)
Extrait uniquement quelques sprites essentiels pour le projet
"""

import os
import struct
import sys

# Chemins (configurables via CLI)
import sys
HOMM3_PATH = sys.argv[1] if len(sys.argv) > 1 else r".\homm3_data"
OUTPUT_PATH = sys.argv[2] if len(sys.argv) > 2 else r".\homm3_original"

# Fichiers LOD à explorer
LOD_FILES = [
    "H3sprite.lod",      # Sprites animés (créatures, héros, objets)
    "H3bitmap.lod",      # Textures et tuiles
    "H3ab_spr.lod",      # Sprites extension Armageddon's Blade
    "H3ab_bmp.lod",      # Textures extension
]

def extract_lod(lod_path, output_dir):
    """Extrait les fichiers d'une archive LOD"""
    print(f"\n📦 Analyse de: {os.path.basename(lod_path)}")
    
    if not os.path.exists(lod_path):
        print(f"   ❌ Fichier non trouvé: {lod_path}")
        return 0
    
    os.makedirs(output_dir, exist_ok=True)
    
    with open(lod_path, 'rb') as f:
        # Header LOD: "LOD" + version + nombre de fichiers
        header = f.read(4)
        if header != b'LOD\x00':
            print(f"   ❌ Format LOD invalide")
            return 0
        
        # Lire le nombre de fichiers
        f.seek(8)
        num_files = struct.unpack('<I', f.read(4))[0]
        print(f"   📁 {num_files} fichiers trouvés")
        
        # Lire la table des fichiers
        extracted = 0
        for i in range(min(num_files, 100)):  # Limiter à 100 premiers fichiers pour test
            try:
                # Structure: nom (16 bytes), offset (4), taille (4), type? (4)
                entry_pos = 12 + i * 32
                f.seek(entry_pos)
                
                name_bytes = f.read(16)
                name = name_bytes.split(b'\x00')[0].decode('ascii', errors='ignore')
                
                offset = struct.unpack('<I', f.read(4))[0]
                size = struct.unpack('<I', f.read(4))[0]
                
                if size > 0 and name and not name.startswith('.'):
                    # Lire et sauvegarder
                    f.seek(offset)
                    data = f.read(size)
                    
                    # Déterminer l'extension
                    ext = '.bin'
                    if data[:2] == b'BM':
                        ext = '.bmp'
                    elif data[:4] == b'PCX ' or data[:2] == b'\x0A\x05':
                        ext = '.pcx'
                    elif data[:4] == b'DEF ' or data[:4] == b'SPR\x00':
                        ext = '.def'
                    
                    output_file = os.path.join(output_dir, f"{name}{ext}")
                    with open(output_file, 'wb') as out:
                        out.write(data)
                    
                    extracted += 1
                    if extracted <= 10:  # Afficher les 10 premiers
                        print(f"   ✓ {name}{ext} ({size} bytes)")
                    
            except Exception as e:
                continue
        
        print(f"   ✅ {extracted} fichiers extraits dans {output_dir}")
        return extracted

if __name__ == "__main__":
    print("=" * 60)
    print("🎮 Extracteur HoMM3 - Mode Simple")
    print("=" * 60)
    
    total = 0
    for lod_file in LOD_FILES:
        lod_path = os.path.join(HOMM3_PATH, lod_file)
        output_subdir = os.path.join(OUTPUT_PATH, lod_file.replace('.lod', ''))
        total += extract_lod(lod_path, output_subdir)
    
    print("\n" + "=" * 60)
    print(f"🎉 TOTAL: {total} fichiers extraits")
    print(f"📂 Dossier de sortie: {OUTPUT_PATH}")
    print("=" * 60)
