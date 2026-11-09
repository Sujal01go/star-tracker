import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

os.makedirs('assets/images/constellations', exist_ok=True)
SIZE = 512

def create_base_canvas():
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    glow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw_glow = ImageDraw.Draw(glow)
    draw_glow.ellipse([48, 48, 464, 464], fill=(15, 38, 85, 140))
    draw_glow.ellipse([110, 110, 402, 402], fill=(0, 229, 255, 70))
    glow = glow.filter(ImageFilter.GaussianBlur(28))
    img.alpha_composite(glow)
    return img

def draw_star(draw, x, y, radius=5, color=(255, 255, 255, 255), glow_color=(0, 229, 255, 180)):
    draw.ellipse([x - radius*2.5, y - radius*2.5, x + radius*2.5, y + radius*2.5], fill=glow_color)
    draw.line([x - radius*3.5, y, x + radius*3.5, y], fill=(color[0], color[1], color[2], 190), width=1)
    draw.line([x, y - radius*3.5, x, y + radius*3.5], fill=(color[0], color[1], color[2], 190), width=1)
    draw.ellipse([x - radius, y - radius, x + radius, y + radius], fill=color)

def draw_constellation_lines(draw, points, connections, line_color=(100, 190, 255, 220), width=2):
    for i, j in connections:
        if i < len(points) and j < len(points):
            p1 = points[i]
            p2 = points[j]
            draw.line([p1[0], p1[1], p2[0], p2[1]], fill=line_color, width=width)

# 1. ORION (The Hunter)
def generate_orion():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (0, 229, 255, 140)
    
    # Warrior figure outline
    draw.ellipse([230, 60, 282, 112], outline=art_color, width=2) # head
    draw.line([256, 112, 256, 260], fill=art_color, width=2) # spine
    draw.line([160, 160, 350, 150], fill=art_color, width=2) # shoulders
    draw.line([160, 160, 110, 80], fill=art_color, width=2) # club arm
    draw.line([110, 80, 80, 50], fill=art_color, width=3) # club
    draw.arc([350, 120, 430, 250], start=270, end=90, fill=art_color, width=2) # lion skin shield
    draw.line([190, 410, 235, 275], fill=art_color, width=2) # left leg
    draw.line([330, 400, 275, 275], fill=art_color, width=2) # right leg
    draw.line([235, 275, 275, 275], fill=art_color, width=2) # belt waist
    
    stars = [
        (160, 160), # Betelgeuse
        (350, 150), # Bellatrix
        (230, 265), # Alnitak
        (256, 260), # Alnilam
        (282, 255), # Mintaka
        (190, 410), # Saiph
        (330, 400), # Rigel
        (256, 95),  # Meissa
    ]
    conns = [
        (7, 0), (7, 1),
        (0, 2), (1, 4),
        (2, 3), (3, 4),
        (2, 5), (4, 6),
        (5, 6)
    ]
    draw_constellation_lines(draw, stars, conns, line_color=(120, 210, 255, 240), width=3)
    
    for idx, (x, y) in enumerate(stars):
        if idx == 0:
            draw_star(draw, x, y, radius=7, color=(255, 130, 70, 255), glow_color=(255, 100, 50, 220)) # Betelgeuse
        elif idx == 6:
            draw_star(draw, x, y, radius=7.5, color=(220, 245, 255, 255), glow_color=(0, 229, 255, 240)) # Rigel
        else:
            draw_star(draw, x, y, radius=5)
            
    img.save('assets/images/constellations/orion.png')
    print("Saved orion.png")

# 2. URSA MAJOR (The Great Bear / Big Dipper)
def generate_ursa_major():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (0, 229, 255, 130)
    
    draw.arc([70, 130, 450, 380], start=180, end=360, fill=art_color, width=2) # back
    draw.line([70, 250, 40, 300], fill=art_color, width=2) # snout
    draw.line([40, 300, 110, 310], fill=art_color, width=2) # jaw
    draw.line([120, 310, 130, 430], fill=art_color, width=2) # front paw
    draw.line([370, 310, 380, 440], fill=art_color, width=2) # rear paw
    draw.arc([360, 130, 480, 240], start=220, end=330, fill=art_color, width=2) # tail
    
    stars = [
        (460, 160), # Alkaid
        (400, 190), # Mizar
        (340, 215), # Alioth
        (280, 230), # Megrez
        (270, 320), # Phecda
        (170, 315), # Merak
        (160, 220), # Dubhe
    ]
    conns = [
        (0, 1), (1, 2), (2, 3),
        (3, 4), (4, 5), (5, 6), (6, 3)
    ]
    draw_constellation_lines(draw, stars, conns, line_color=(120, 210, 255, 240), width=3)
    for x, y in stars:
        draw_star(draw, x, y, radius=5.5)
    img.save('assets/images/constellations/ursa_major.png')
    print("Saved ursa_major.png")

# 3. CASSIOPEIA (The Queen / 'W')
def generate_cassiopeia():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (190, 120, 255, 140)
    
    draw.line([100, 420, 100, 190], fill=art_color, width=2)
    draw.line([100, 190, 220, 110], fill=art_color, width=2)
    draw.line([220, 110, 400, 110], fill=art_color, width=2)
    draw.line([400, 110, 420, 420], fill=art_color, width=2)
    draw.line([100, 330, 420, 330], fill=art_color, width=2)
    draw.polygon([(230, 70), (245, 105), (260, 70), (275, 105), (290, 70), (290, 110), (230, 110)], outline=art_color)
    
    stars = [
        (90, 210),   # Caph
        (170, 310),  # Schedar
        (260, 230),  # Gamma Cas
        (350, 300),  # Ruchbah
        (430, 180),  # Segin
    ]
    conns = [(0, 1), (1, 2), (2, 3), (3, 4)]
    draw_constellation_lines(draw, stars, conns, line_color=(200, 160, 255, 240), width=3)
    for x, y in stars:
        draw_star(draw, x, y, radius=5.8, color=(255, 240, 200, 255))
    img.save('assets/images/constellations/cassiopeia.png')
    print("Saved cassiopeia.png")

# 4. CYGNUS (The Swan / Northern Cross)
def generate_cygnus():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (0, 229, 255, 140)
    
    draw.arc([40, 150, 472, 340], start=180, end=360, fill=art_color, width=2) # wings arc
    draw.line([256, 70, 256, 440], fill=art_color, width=2) # body / neck
    draw.ellipse([246, 50, 266, 70], outline=art_color, width=2) # head
    draw.line([256, 50, 256, 35], fill=art_color, width=2) # beak
    
    stars = [
        (256, 430), # Deneb
        (256, 260), # Sadr
        (256, 80),  # Albireo
        (100, 220), # Gienah
        (412, 220), # Fawaris
    ]
    conns = [
        (0, 1), (1, 2),
        (3, 1), (1, 4)
    ]
    draw_constellation_lines(draw, stars, conns, line_color=(120, 220, 255, 240), width=3)
    for idx, (x, y) in enumerate(stars):
        if idx == 0:
            draw_star(draw, x, y, radius=7.5, color=(255, 255, 255, 255), glow_color=(0, 229, 255, 240)) # Deneb
        elif idx == 2:
            draw_star(draw, x, y, radius=5.5, color=(255, 220, 130, 255)) # Albireo
        else:
            draw_star(draw, x, y, radius=5.2)
    img.save('assets/images/constellations/cygnus.png')
    print("Saved cygnus.png")

# 5. CANIS MAJOR (The Greater Dog)
def generate_canis_major():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (0, 229, 255, 140)
    
    draw.line([160, 120, 256, 230], fill=art_color, width=2)
    draw.line([256, 230, 390, 260], fill=art_color, width=2)
    draw.line([160, 120, 100, 150], fill=art_color, width=2) # snout
    draw.line([256, 230, 240, 390], fill=art_color, width=2) # front leg
    draw.line([390, 260, 400, 420], fill=art_color, width=2) # rear leg
    draw.arc([380, 210, 470, 290], start=240, end=350, fill=art_color, width=2) # tail
    
    stars = [
        (160, 120), # Sirius!
        (100, 190), # Murzim
        (256, 230), # Muliphein
        (320, 330), # Wezen
        (300, 410), # Adhara
        (400, 390), # Aludra
    ]
    conns = [(1, 0), (0, 2), (2, 3), (3, 4), (3, 5)]
    draw_constellation_lines(draw, stars, conns, line_color=(120, 210, 255, 240), width=3)
    for idx, (x, y) in enumerate(stars):
        if idx == 0:
            draw_star(draw, x, y, radius=8.5, color=(255, 255, 255, 255), glow_color=(0, 229, 255, 255))
        else:
            draw_star(draw, x, y, radius=5.0)
    img.save('assets/images/constellations/canis_major.png')
    print("Saved canis_major.png")

# 6. TAURUS (The Bull)
def generate_taurus():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (255, 150, 80, 130)
    
    draw.line([220, 240, 100, 80], fill=art_color, width=2)
    draw.line([220, 240, 380, 90], fill=art_color, width=2)
    draw.arc([160, 200, 300, 340], start=0, end=180, fill=art_color, width=2)
    
    stars = [
        (200, 270), # Aldebaran
        (230, 250), # Ain
        (210, 310), # Gamma Tau
        (100, 80),  # Elnath
        (380, 90),  # Tianguan
        (420, 180), # Pleiades cluster
    ]
    conns = [(2, 0), (2, 1), (0, 4), (1, 3)]
    draw_constellation_lines(draw, stars, conns, line_color=(255, 180, 110, 240), width=3)
    for idx, (x, y) in enumerate(stars):
        if idx == 0:
            draw_star(draw, x, y, radius=8.0, color=(255, 130, 60, 255), glow_color=(255, 100, 30, 220))
        elif idx == 5:
            draw.ellipse([x-14, y-14, x+14, y+14], fill=(0, 229, 255, 110))
            draw_star(draw, x, y, radius=4.0, color=(220, 245, 255, 255))
        else:
            draw_star(draw, x, y, radius=5.0)
    img.save('assets/images/constellations/taurus.png')
    print("Saved taurus.png")

# 7. SCORPIUS (The Scorpion)
def generate_scorpius():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (255, 70, 100, 130)
    
    draw.arc([100, 80, 230, 200], start=180, end=330, fill=art_color, width=2)
    draw.arc([280, 80, 410, 200], start=210, end=360, fill=art_color, width=2)
    draw.line([256, 170, 256, 320], fill=art_color, width=2)
    draw.arc([230, 300, 350, 440], start=40, end=240, fill=art_color, width=2)
    
    stars = [
        (256, 190), # Antares
        (190, 110), # Graffias
        (220, 130), # Dschubba
        (256, 250), # Wei
        (240, 320), # Larawag
        (270, 390), # Sargas
        (330, 410), # Shaula
        (350, 380), # Lesath
    ]
    conns = [(1, 2), (2, 0), (0, 3), (3, 4), (4, 5), (5, 6), (6, 7)]
    draw_constellation_lines(draw, stars, conns, line_color=(255, 110, 130, 240), width=3)
    for idx, (x, y) in enumerate(stars):
        if idx == 0:
            draw_star(draw, x, y, radius=8.0, color=(255, 80, 60, 255), glow_color=(255, 40, 30, 240))
        elif idx == 6:
            draw_star(draw, x, y, radius=6.0, color=(200, 230, 255, 255), glow_color=(0, 229, 255, 220))
        else:
            draw_star(draw, x, y, radius=5.0)
    img.save('assets/images/constellations/scorpius.png')
    print("Saved scorpius.png")

# 8. LEO (The Lion)
def generate_leo():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (255, 210, 70, 130)
    
    draw.arc([100, 100, 220, 260], start=150, end=360, fill=art_color, width=2)
    draw.line([160, 280, 380, 280], fill=art_color, width=2)
    draw.line([380, 280, 430, 220], fill=art_color, width=2)
    
    stars = [
        (150, 280), # Regulus
        (170, 200), # Algieba
        (130, 140), # Adhafera
        (180, 100), # Ras Elased
        (300, 250), # Chertan
        (330, 180), # Zosma
        (420, 220), # Denebola
    ]
    conns = [(0, 1), (1, 2), (2, 3), (1, 4), (4, 5), (5, 6), (4, 0)]
    draw_constellation_lines(draw, stars, conns, line_color=(255, 220, 120, 240), width=3)
    for idx, (x, y) in enumerate(stars):
        if idx == 0:
            draw_star(draw, x, y, radius=7.5, color=(210, 235, 255, 255), glow_color=(0, 229, 255, 220))
        else:
            draw_star(draw, x, y, radius=5.2)
    img.save('assets/images/constellations/leo.png')
    print("Saved leo.png")

# 9. URSA MINOR (Little Bear / Polaris)
def generate_ursa_minor():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (0, 229, 255, 130)
    
    draw.arc([120, 160, 420, 360], start=180, end=360, fill=art_color, width=2)
    
    stars = [
        (80, 120),  # Polaris
        (160, 170), # Yildun
        (220, 220), # Epsilon UMi
        (280, 250), # Anwar
        (360, 240), # Kochab
        (390, 310), # Pherkad
        (300, 330), # Urodelus
    ]
    conns = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 3)]
    draw_constellation_lines(draw, stars, conns, line_color=(120, 210, 255, 240), width=3)
    for idx, (x, y) in enumerate(stars):
        if idx == 0:
            draw_star(draw, x, y, radius=8.0, color=(255, 255, 240, 255), glow_color=(0, 229, 255, 255))
        else:
            draw_star(draw, x, y, radius=5.0)
    img.save('assets/images/constellations/ursa_minor.png')
    print("Saved ursa_minor.png")

# 10. GEMINI (The Twins: Castor & Pollux)
def generate_gemini():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (0, 229, 255, 140)
    
    # Twin heads & bodies
    draw.ellipse([160, 70, 210, 120], outline=art_color, width=2) # Castor head
    draw.ellipse([290, 70, 340, 120], outline=art_color, width=2) # Pollux head
    draw.line([185, 120, 150, 400], fill=art_color, width=2) # Castor body
    draw.line([315, 120, 350, 400], fill=art_color, width=2) # Pollux body
    draw.line([185, 200, 315, 200], fill=art_color, width=2) # embraced hands
    
    stars = [
        (185, 95),  # Castor
        (315, 95),  # Pollux
        (160, 210), # Wasat
        (330, 210), # Mebsuta
        (140, 380), # Alhena
        (360, 380), # Tejat
    ]
    conns = [(0, 2), (2, 4), (1, 3), (3, 5), (2, 3)]
    draw_constellation_lines(draw, stars, conns, line_color=(120, 220, 255, 240), width=3)
    for idx, (x, y) in enumerate(stars):
        draw_star(draw, x, y, radius=7.0 if idx <= 1 else 5.0)
    img.save('assets/images/constellations/gemini.png')
    print("Saved gemini.png")

# 11. PEGASUS (The Winged Horse / Great Square)
def generate_pegasus():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (0, 229, 255, 140)
    
    draw.arc([100, 80, 420, 300], start=180, end=330, fill=art_color, width=2) # wing
    draw.line([120, 250, 50, 320], fill=art_color, width=2) # neck
    draw.line([50, 320, 30, 360], fill=art_color, width=2) # muzzle
    
    stars = [
        (140, 170), # Scheat
        (340, 170), # Alpheratz
        (140, 330), # Markab
        (340, 330), # Algenib
        (50, 350),  # Enif
    ]
    conns = [(0, 1), (1, 3), (3, 2), (2, 0), (2, 4)]
    draw_constellation_lines(draw, stars, conns, line_color=(130, 215, 255, 240), width=3)
    for x, y in stars:
        draw_star(draw, x, y, radius=6.0)
    img.save('assets/images/constellations/pegasus.png')
    print("Saved pegasus.png")

# 12. ANDROMEDA (The Chained Maiden)
def generate_andromeda():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (190, 140, 255, 140)
    
    draw.ellipse([230, 80, 280, 130], outline=art_color, width=2)
    draw.line([256, 130, 256, 320], fill=art_color, width=2)
    draw.line([120, 190, 390, 190], fill=art_color, width=2)
    draw.arc([100, 170, 130, 210], start=0, end=360, fill=art_color, width=2) # left cuff
    draw.arc([380, 170, 410, 210], start=0, end=360, fill=art_color, width=2) # right cuff
    
    stars = [
        (130, 330), # Alpheratz
        (230, 240), # Mirach
        (370, 150), # Almach
    ]
    conns = [(0, 1), (1, 2)]
    draw_constellation_lines(draw, stars, conns, line_color=(210, 170, 255, 240), width=3)
    for x, y in stars:
        draw_star(draw, x, y, radius=6.2, color=(255, 240, 220, 255))
    img.save('assets/images/constellations/andromeda.png')
    print("Saved andromeda.png")

# 13. SAGITTARIUS (The Archer / Teapot)
def generate_sagittarius():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (0, 229, 255, 140)
    
    draw.arc([80, 100, 240, 340], start=270, end=90, fill=art_color, width=3) # bow
    draw.line([60, 220, 250, 220], fill=art_color, width=2) # arrow
    draw.ellipse([270, 100, 320, 150], outline=art_color, width=2) # head
    
    stars = [
        (180, 220), # Kaus Media
        (190, 320), # Kaus Australis
        (250, 330), # Ascella
        (290, 230), # Nunki
        (230, 160), # Kaus Borealis
        (350, 210), # Tau Sgr
        (120, 260), # Alnasl
    ]
    conns = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 4), (3, 4), (3, 5), (0, 6), (1, 6)]
    draw_constellation_lines(draw, stars, conns, line_color=(120, 215, 255, 240), width=3)
    for x, y in stars:
        draw_star(draw, x, y, radius=5.8)
    img.save('assets/images/constellations/sagittarius.png')
    print("Saved sagittarius.png")

# 14. CRUX (The Southern Cross)
def generate_crux():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (0, 229, 255, 150)
    
    draw.polygon([(256, 50), (430, 256), (256, 460), (80, 256)], outline=art_color)
    
    stars = [
        (256, 420), # Acrux
        (256, 100), # Gacrux
        (120, 256), # Mimosa
        (380, 256), # Delta Crucis
    ]
    conns = [(0, 1), (2, 3)]
    draw_constellation_lines(draw, stars, conns, line_color=(140, 220, 255, 255), width=3)
    for idx, (x, y) in enumerate(stars):
        if idx == 1:
            draw_star(draw, x, y, radius=7.0, color=(255, 120, 90, 255), glow_color=(255, 80, 60, 220)) # Gacrux
        else:
            draw_star(draw, x, y, radius=7.5, color=(255, 255, 255, 255), glow_color=(0, 229, 255, 240))
    img.save('assets/images/constellations/crux.png')
    print("Saved crux.png")

# 15. AQUILA (The Flying Eagle)
def generate_aquila():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (0, 229, 255, 140)
    
    draw.arc([40, 100, 472, 320], start=180, end=360, fill=art_color, width=2) # wings
    draw.line([256, 120, 256, 420], fill=art_color, width=2) # body & tail
    draw.polygon([(256, 80), (240, 120), (272, 120)], outline=art_color)
    
    stars = [
        (256, 210), # Altair
        (210, 180), # Tarazed
        (300, 240), # Alshain
    ]
    conns = [(1, 0), (0, 2)]
    draw_constellation_lines(draw, stars, conns, line_color=(130, 220, 255, 240), width=3)
    for idx, (x, y) in enumerate(stars):
        if idx == 0:
            draw_star(draw, x, y, radius=8.0, color=(255, 255, 255, 255), glow_color=(0, 229, 255, 240))
        else:
            draw_star(draw, x, y, radius=5.5)
    img.save('assets/images/constellations/aquila.png')
    print("Saved aquila.png")

# 16. LYRA (The Celestial Lyre & Vega)
def generate_lyra():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (0, 229, 255, 140)
    
    draw.arc([130, 80, 380, 420], start=210, end=330, fill=art_color, width=2)
    draw.line([160, 230, 350, 230], fill=art_color, width=2)
    draw.line([180, 230, 180, 390], fill=art_color, width=1)
    draw.line([230, 230, 230, 390], fill=art_color, width=1)
    draw.line([280, 230, 280, 390], fill=art_color, width=1)
    
    stars = [
        (170, 120), # Vega
        (220, 170), # Epsilon Lyrae
        (180, 270), # Zeta Lyrae
        (310, 270), # Delta Lyrae
        (330, 390), # Sulafat
        (190, 390), # Sheliak
    ]
    conns = [(0, 1), (0, 2), (2, 3), (3, 4), (4, 5), (5, 2)]
    draw_constellation_lines(draw, stars, conns, line_color=(130, 215, 255, 240), width=3)
    for idx, (x, y) in enumerate(stars):
        if idx == 0:
            draw_star(draw, x, y, radius=8.5, color=(240, 250, 255, 255), glow_color=(0, 229, 255, 255))
        else:
            draw_star(draw, x, y, radius=5.0)
    img.save('assets/images/constellations/lyra.png')
    print("Saved lyra.png")

# 17. BOOTES (The Herdsman & Arcturus)
def generate_bootes():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (255, 170, 70, 140)
    
    draw.line([256, 80, 150, 200], fill=art_color, width=2)
    draw.line([256, 80, 360, 200], fill=art_color, width=2)
    draw.line([150, 200, 256, 380], fill=art_color, width=2)
    draw.line([360, 200, 256, 380], fill=art_color, width=2)
    
    stars = [
        (256, 380), # Arcturus
        (150, 200), # Izar
        (360, 200), # Muphrid
        (256, 80),  # Nekkar
        (190, 120), # Seginus
    ]
    conns = [(0, 1), (0, 2), (1, 4), (4, 3), (3, 2)]
    draw_constellation_lines(draw, stars, conns, line_color=(255, 190, 110, 240), width=3)
    for idx, (x, y) in enumerate(stars):
        if idx == 0:
            draw_star(draw, x, y, radius=8.5, color=(255, 160, 70, 255), glow_color=(255, 120, 40, 240))
        else:
            draw_star(draw, x, y, radius=5.2)
    img.save('assets/images/constellations/bootes.png')
    print("Saved bootes.png")

# 18. DEFAULT / UNIVERSAL CONSTELLATION ARTWORK
def generate_default():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    art_color = (0, 229, 255, 130)
    
    draw.ellipse([64, 64, 448, 448], outline=art_color, width=2)
    draw.ellipse([128, 128, 384, 384], outline=art_color, width=1)
    draw.line([256, 40, 256, 472], fill=art_color, width=1)
    draw.line([40, 256, 472, 256], fill=art_color, width=1)
    
    stars = [
        (256, 120),
        (380, 256),
        (256, 392),
        (132, 256),
        (256, 256),
    ]
    conns = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 4), (2, 4)]
    draw_constellation_lines(draw, stars, conns, line_color=(120, 215, 255, 240), width=3)
    for idx, (x, y) in enumerate(stars):
        draw_star(draw, x, y, radius=6.0 if idx == 4 else 5.0)
        
    img.save('assets/images/constellations/default_constellation.png')
    print("Saved default_constellation.png")

generate_orion()
generate_ursa_major()
generate_cassiopeia()
generate_cygnus()
generate_canis_major()
generate_taurus()
generate_scorpius()
generate_leo()
generate_ursa_minor()
generate_gemini()
generate_pegasus()
generate_andromeda()
generate_sagittarius()
generate_crux()
generate_aquila()
generate_lyra()
generate_bootes()
generate_default()
print("ALL CONSTELLATION ARTWORKS GENERATED WITH VIBRANT ETHEREAL GLOW!")
