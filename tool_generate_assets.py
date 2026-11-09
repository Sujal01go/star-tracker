import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import math
import os

os.makedirs('assets/planets', exist_ok=True)
os.makedirs('assets/images', exist_ok=True)

SIZE = 512
HALF = SIZE / 2.0

# Light direction vector (normalized, from top-left front)
LIGHT = np.array([-0.55, 0.45, 0.70])
LIGHT /= np.linalg.norm(LIGHT)

def create_sphere_grid(size=SIZE):
    y, x = np.mgrid[-1:1:complex(0, size), -1:1:complex(0, size)]
    r2 = x*x + y*y
    mask = r2 <= 1.0
    z = np.zeros_like(r2)
    z[mask] = np.sqrt(1.0 - r2[mask])
    
    # Normal vectors
    nx = np.zeros_like(x)
    ny = np.zeros_like(y)
    nz = np.zeros_like(z)
    nx[mask] = x[mask]
    ny[mask] = y[mask]
    nz[mask] = z[mask]
    
    # Diffuse lighting
    dot = nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2]
    diffuse = np.maximum(0.0, dot)
    # Ambient
    diffuse = diffuse * 0.88 + 0.12
    
    # Latitude and longitude for texture mapping
    lat = np.arcsin(np.clip(y, -1.0, 1.0))
    lon = np.arctan2(x, np.where(mask, z, 1.0))
    
    # Limb darkening / Fresnel
    fresnel = np.zeros_like(r2)
    fresnel[mask] = (1.0 - z[mask]) ** 2.2
    
    return x, y, z, r2, mask, diffuse, lat, lon, fresnel

def save_image(arr, path):
    arr = np.clip(arr, 0, 255).astype(np.uint8)
    img = Image.fromarray(arr, mode='RGBA')
    img.save(path, optimize=True)
    print(f"Saved: {path}")

def perlin_noise_2d(width, height, freq=4.0, octaves=4, seed=42):
    np.random.seed(seed)
    noise = np.zeros((height, width))
    for o in range(octaves):
        f = freq * (2 ** o)
        w = 1.0 / (2 ** o)
        grid_w = max(2, int(f))
        grid_h = max(2, int(f))
        g = np.random.randn(grid_h + 1, grid_w + 1)
        # Bilinear interpolation
        y_idx = np.linspace(0, grid_h, height, endpoint=False)
        x_idx = np.linspace(0, grid_w, width, endpoint=False)
        y0 = y_idx.astype(int)
        x0 = x_idx.astype(int)
        y1 = np.minimum(y0 + 1, grid_h)
        x1 = np.minimum(x0 + 1, grid_w)
        wy = (y_idx - y0)[:, None]
        wx = (x_idx - x0)[None, :]
        
        top = g[y0, :][:, x0] * (1 - wx) + g[y0, :][:, x1] * wx
        bottom = g[y1, :][:, x0] * (1 - wx) + g[y1, :][:, x1] * wx
        layer = top * (1 - wy) + bottom * wy
        noise += layer * w
    return (noise - noise.min()) / (noise.max() - noise.min() + 1e-6)

print("Precomputing sphere geometry...")
X, Y, Z, R2, MASK, DIFFUSE, LAT, LON, FRESNEL = create_sphere_grid(SIZE)

# 1. EARTH
def render_earth():
    # Continents vs Oceans using noise
    noise1 = perlin_noise_2d(SIZE, SIZE, freq=3.2, octaves=5, seed=101)
    noise_clouds = perlin_noise_2d(SIZE, SIZE, freq=5.5, octaves=5, seed=202)
    
    # Base ocean deep blue: (15, 60, 150)
    # Shallow ocean cyan: (20, 110, 190)
    # Land green/tan: (45, 125, 55) to (160, 140, 90)
    # Clouds: white (255, 255, 255)
    ocean_mask = (noise1 < 0.52)
    land_mask = ~ocean_mask
    
    r = np.zeros((SIZE, SIZE))
    g = np.zeros((SIZE, SIZE))
    b = np.zeros((SIZE, SIZE))
    
    # Ocean colors
    depth = noise1 / 0.52
    r[ocean_mask] = 12 + 15 * depth[ocean_mask]
    g[ocean_mask] = 45 + 55 * depth[ocean_mask]
    b[ocean_mask] = 120 + 70 * depth[ocean_mask]
    
    # Land colors
    elevation = (noise1 - 0.52) / 0.48
    r[land_mask] = 40 + 110 * elevation[land_mask]
    g[land_mask] = 110 + 30 * elevation[land_mask]
    b[land_mask] = 50 + 40 * elevation[land_mask]
    
    # Cloud overlay
    cloud_intensity = np.maximum(0.0, (noise_clouds - 0.45) / 0.55) ** 1.3
    r = r * (1 - cloud_intensity) + 250 * cloud_intensity
    g = g * (1 - cloud_intensity) + 252 * cloud_intensity
    b = b * (1 - cloud_intensity) + 255 * cloud_intensity
    
    # Apply 3D diffuse lighting
    r = r * DIFFUSE
    g = g * DIFFUSE
    b = b * DIFFUSE
    
    # Atmospheric cyan rim glow (Rayleigh scattering)
    atmo_cyan = FRESNEL * 180.0
    r += atmo_cyan * 0.2
    g += atmo_cyan * 0.7
    b += atmo_cyan * 1.0
    
    # Outer atmospheric halo
    alpha = np.zeros((SIZE, SIZE))
    alpha[MASK] = 255.0
    
    # Add subtle outer atmosphere
    outer = (R2 > 1.0) & (R2 < 1.08)
    outer_falloff = np.maximum(0.0, (1.08 - R2[outer]) / 0.08) ** 2.0
    r[outer] = 30 * outer_falloff
    g[outer] = 140 * outer_falloff
    b[outer] = 255 * outer_falloff
    alpha[outer] = 200 * outer_falloff
    
    arr = np.dstack([r, g, b, alpha])
    save_image(arr, 'assets/planets/earth.png')

# 2. MARS
def render_mars():
    noise = perlin_noise_2d(SIZE, SIZE, freq=4.5, octaves=5, seed=303)
    # Rust reddish-orange terrain
    # Dark basaltic maria
    maria = np.maximum(0.0, (0.45 - noise) / 0.45)
    
    r = (215 - 80 * maria) * DIFFUSE
    g = (95 - 45 * maria) * DIFFUSE
    b = (50 - 30 * maria) * DIFFUSE
    
    # Polar ice cap at top (Y < -0.78)
    polar = np.maximum(0.0, (-Y - 0.76) / 0.24) ** 2.5
    r = r * (1 - polar) + 245 * polar * DIFFUSE
    g = g * (1 - polar) + 245 * polar * DIFFUSE
    b = b * (1 - polar) + 255 * polar * DIFFUSE
    
    # Dusty reddish atmospheric rim
    atmo = FRESNEL * 110.0
    r += atmo * 0.95
    g += atmo * 0.4
    b += atmo * 0.2
    
    alpha = np.zeros((SIZE, SIZE))
    alpha[MASK] = 255.0
    
    # Outer dust haze
    outer = (R2 > 1.0) & (R2 < 1.06)
    falloff = np.maximum(0.0, (1.06 - R2[outer]) / 0.06) ** 2.0
    r[outer] = 190 * falloff
    g[outer] = 80 * falloff
    b[outer] = 40 * falloff
    alpha[outer] = 160 * falloff
    
    arr = np.dstack([r, g, b, alpha])
    save_image(arr, 'assets/planets/mars.png')

# 3. JUPITER
def render_jupiter():
    noise = perlin_noise_2d(SIZE, SIZE, freq=6.0, octaves=5, seed=404)
    # Latitudinal bands
    band_freq = np.sin(LAT * 16.0) * 0.5 + 0.5
    band_pattern = np.clip(band_freq + (noise - 0.5) * 0.4, 0.0, 1.0)
    
    # Great Red Spot near Lat = -0.38, Lon = 0.2
    dist_grs = np.sqrt(((LAT + 0.38) * 3.0)**2 + ((LON - 0.2) * 1.8)**2)
    grs_mask = np.maximum(0.0, (1.0 - dist_grs)) ** 2.0
    
    # Colors: Cream bands: (230, 215, 185), Rust/Brown bands: (175, 105, 55)
    r = (175 + 55 * band_pattern)
    g = (105 + 110 * band_pattern)
    b = (55 + 130 * band_pattern)
    
    # Blend Great Red Spot
    r = r * (1 - grs_mask) + 210 * grs_mask
    g = g * (1 - grs_mask) + 75 * grs_mask
    b = b * (1 - grs_mask) + 50 * grs_mask
    
    r = r * DIFFUSE
    g = g * DIFFUSE
    b = b * DIFFUSE
    
    # Limb darkening
    atmo = FRESNEL * 60.0
    r += atmo * 0.8
    g += atmo * 0.7
    b += atmo * 0.5
    
    alpha = np.zeros((SIZE, SIZE))
    alpha[MASK] = 255.0
    
    outer = (R2 > 1.0) & (R2 < 1.05)
    falloff = np.maximum(0.0, (1.05 - R2[outer]) / 0.05) ** 2.0
    r[outer] = 200 * falloff
    g[outer] = 160 * falloff
    b[outer] = 110 * falloff
    alpha[outer] = 140 * falloff
    
    arr = np.dstack([r, g, b, alpha])
    save_image(arr, 'assets/planets/jupiter.png')

# 4. SATURN (Planet + Magnificent Tilted Rings)
def render_saturn():
    # Planet body (scaled down to 0.46 radius so rings fit in 512x512)
    scale = 0.46
    x_pl = X / scale
    y_pl = Y / scale
    r2_pl = x_pl**2 + y_pl**2
    mask_pl = r2_pl <= 1.0
    
    z_pl = np.zeros_like(r2_pl)
    z_pl[mask_pl] = np.sqrt(1.0 - r2_pl[mask_pl])
    
    nx = np.zeros_like(x_pl)
    ny = np.zeros_like(y_pl)
    nz = np.zeros_like(z_pl)
    nx[mask_pl] = x_pl[mask_pl]
    ny[mask_pl] = y_pl[mask_pl]
    nz[mask_pl] = z_pl[mask_pl]
    
    dot = nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2]
    diff = np.maximum(0.0, dot) * 0.88 + 0.12
    lat_pl = np.arcsin(np.clip(y_pl, -1.0, 1.0))
    
    # Saturn bands: golden ochre and pale amber
    bands = np.sin(lat_pl * 14.0) * 0.5 + 0.5
    r_body = (210 + 35 * bands) * diff
    g_body = (185 + 25 * bands) * diff
    b_body = (130 + 30 * bands) * diff
    
    # Ring plane calculation:
    # Saturn ring tilt angle ~ 27 deg (0.47 rad)
    # Ring coordinates in planet space:
    tilt = 0.44
    cos_t = np.cos(tilt)
    sin_t = np.sin(tilt)
    
    # Camera ray: from (X, Y, -3.0) along (0, 0, 1)
    # Ring plane equation: y_rot = 0 => (Y/scale)*cos_t - (Z_cam/scale)*sin_t = 0
    # Z_ring = (Y/scale) * cos_t / sin_t = (Y/scale) / tan(tilt)
    z_ring = (Y / scale) / np.tan(tilt)
    x_ring = X / scale
    dist_ring = np.sqrt(x_ring**2 + z_ring**2)
    
    # Rings span from radius 1.25 to 2.25
    r_inner = 1.22
    r_outer = 2.22
    cassini_min = 1.88
    cassini_max = 1.98
    
    ring_mask = (dist_ring >= r_inner) & (dist_ring <= r_outer)
    # Cassini division
    cassini = (dist_ring >= cassini_min) & (dist_ring <= cassini_max)
    
    # Ring transparency & concentric ringlets texture
    ring_tex = np.sin(dist_ring * 65.0) * 0.25 + 0.75
    ring_alpha = np.zeros((SIZE, SIZE))
    ring_alpha[ring_mask] = 210 * ring_tex[ring_mask]
    ring_alpha[cassini] = 25.0
    
    # Ring shading based on light
    # Normal to ring is (0, cos_t, -sin_t)
    ring_dot = abs(LIGHT[1] * cos_t - LIGHT[2] * sin_t)
    ring_light = ring_dot * 0.85 + 0.25
    
    r_ring = (220 * ring_tex * ring_light)
    g_ring = (195 * ring_tex * ring_light)
    b_ring = (145 * ring_tex * ring_light)
    
    # Planet shadow cast on back rings (when z_ring > 0 and inside planet shadow cylinder)
    shadow_on_rings = (z_ring > 0) & (x_ring**2 + (Y/scale)**2 < 0.98)
    r_ring[shadow_on_rings] *= 0.15
    g_ring[shadow_on_rings] *= 0.15
    b_ring[shadow_on_rings] *= 0.15
    
    # Shadow cast by rings onto planet body
    # Ray from sun towards planet hits ring if x_shadow, y_shadow in ring
    # Approximate front ring shadow on planet surface
    ring_shadow_on_body = mask_pl & (y_pl > 0.05) & (y_pl < 0.32)
    r_body[ring_shadow_on_body] *= 0.3
    g_body[ring_shadow_on_body] *= 0.3
    b_body[ring_shadow_on_body] *= 0.3
    
    # Combine back rings, planet body, front rings
    # Rings in front of planet have z_ring < z_pl
    front_rings = ring_mask & ((z_ring < z_pl) | (~mask_pl))
    back_rings = ring_mask & (z_ring >= z_pl) & (~mask_pl)
    
    out_r = np.zeros((SIZE, SIZE))
    out_g = np.zeros((SIZE, SIZE))
    out_b = np.zeros((SIZE, SIZE))
    out_a = np.zeros((SIZE, SIZE))
    
    # 1. Back rings
    out_r[back_rings] = r_ring[back_rings]
    out_g[back_rings] = g_ring[back_rings]
    out_b[back_rings] = b_ring[back_rings]
    out_a[back_rings] = ring_alpha[back_rings]
    
    # 2. Planet body
    out_r[mask_pl] = r_body[mask_pl]
    out_g[mask_pl] = g_body[mask_pl]
    out_b[mask_pl] = b_body[mask_pl]
    out_a[mask_pl] = 255.0
    
    # 3. Front rings (alpha blend over body)
    fa = ring_alpha[front_rings] / 255.0
    out_r[front_rings] = out_r[front_rings] * (1 - fa) + r_ring[front_rings] * fa
    out_g[front_rings] = out_g[front_rings] * (1 - fa) + g_ring[front_rings] * fa
    out_b[front_rings] = out_b[front_rings] * (1 - fa) + b_ring[front_rings] * fa
    out_a[front_rings] = np.maximum(out_a[front_rings], ring_alpha[front_rings])
    
    arr = np.dstack([out_r, out_g, out_b, out_a])
    save_image(arr, 'assets/planets/saturn.png')

# 5. VENUS
def render_venus():
    noise = perlin_noise_2d(SIZE, SIZE, freq=5.0, octaves=4, seed=505)
    # Dense sulfuric acid swirling clouds: warm cream / pale gold / amber
    bands = np.sin(LAT * 10.0 + noise * 3.0) * 0.5 + 0.5
    
    r = (245 - 25 * bands) * DIFFUSE
    g = (220 - 40 * bands) * DIFFUSE
    b = (170 - 60 * bands) * DIFFUSE
    
    # Dense atmospheric halo
    atmo = FRESNEL * 140.0
    r += atmo * 0.95
    g += atmo * 0.85
    b += atmo * 0.60
    
    alpha = np.zeros((SIZE, SIZE))
    alpha[MASK] = 255.0
    
    outer = (R2 > 1.0) & (R2 < 1.07)
    falloff = np.maximum(0.0, (1.07 - R2[outer]) / 0.07) ** 2.0
    r[outer] = 240 * falloff
    g[outer] = 210 * falloff
    b[outer] = 150 * falloff
    alpha[outer] = 180 * falloff
    
    arr = np.dstack([r, g, b, alpha])
    save_image(arr, 'assets/planets/venus.png')

# 6. MERCURY
def render_mercury():
    noise = perlin_noise_2d(SIZE, SIZE, freq=8.0, octaves=5, seed=606)
    craters = perlin_noise_2d(SIZE, SIZE, freq=16.0, octaves=3, seed=707)
    surf = noise * 0.65 + craters * 0.35
    
    # Grey brownish rocky terrain
    r = (165 + 60 * surf) * DIFFUSE
    g = (155 + 50 * surf) * DIFFUSE
    b = (145 + 45 * surf) * DIFFUSE
    
    alpha = np.zeros((SIZE, SIZE))
    alpha[MASK] = 255.0
    
    arr = np.dstack([r, g, b, alpha])
    save_image(arr, 'assets/planets/mercury.png')

# 7. URANUS
def render_uranus():
    # Cyan-aquamarine ice giant with smooth subtle haze
    r = 135 * DIFFUSE
    g = 215 * DIFFUSE
    b = 225 * DIFFUSE
    
    atmo = FRESNEL * 150.0
    r += atmo * 0.3
    g += atmo * 0.8
    b += atmo * 1.0
    
    alpha = np.zeros((SIZE, SIZE))
    alpha[MASK] = 255.0
    
    outer = (R2 > 1.0) & (R2 < 1.08)
    falloff = np.maximum(0.0, (1.08 - R2[outer]) / 0.08) ** 2.0
    r[outer] = 80 * falloff
    g[outer] = 210 * falloff
    b[outer] = 230 * falloff
    alpha[outer] = 190 * falloff
    
    arr = np.dstack([r, g, b, alpha])
    save_image(arr, 'assets/planets/uranus.png')

# 8. NEPTUNE
def render_neptune():
    noise = perlin_noise_2d(SIZE, SIZE, freq=6.5, octaves=4, seed=808)
    # Deep azure blue with white methane cirrus storm bands
    bands = np.sin(LAT * 12.0 + noise * 2.0) * 0.5 + 0.5
    storm = np.maximum(0.0, (noise - 0.6) / 0.4) ** 2.0
    
    r = (30 + 35 * bands) * (1 - storm) + 210 * storm
    g = (85 + 60 * bands) * (1 - storm) + 230 * storm
    b = (210 + 45 * bands) * (1 - storm) + 255 * storm
    
    r = r * DIFFUSE
    g = g * DIFFUSE
    b = b * DIFFUSE
    
    atmo = FRESNEL * 170.0
    r += atmo * 0.1
    g += atmo * 0.5
    b += atmo * 1.0
    
    alpha = np.zeros((SIZE, SIZE))
    alpha[MASK] = 255.0
    
    outer = (R2 > 1.0) & (R2 < 1.08)
    falloff = np.maximum(0.0, (1.08 - R2[outer]) / 0.08) ** 2.0
    r[outer] = 40 * falloff
    g[outer] = 110 * falloff
    b[outer] = 255 * falloff
    alpha[outer] = 200 * falloff
    
    arr = np.dstack([r, g, b, alpha])
    save_image(arr, 'assets/planets/neptune.png')

# 9. MOON
def render_moon():
    noise = perlin_noise_2d(SIZE, SIZE, freq=5.0, octaves=5, seed=909)
    craters = perlin_noise_2d(SIZE, SIZE, freq=14.0, octaves=4, seed=910)
    # Maria (dark basaltic plains) vs Highlands
    maria = noise < 0.46
    
    base = np.zeros((SIZE, SIZE))
    base[maria] = 85 + 40 * (noise[maria] / 0.46)
    base[~maria] = 150 + 60 * ((noise[~maria] - 0.46) / 0.54)
    base += (craters - 0.5) * 35.0
    
    r = base * DIFFUSE
    g = base * DIFFUSE * 0.98
    b = base * DIFFUSE * 0.96
    
    alpha = np.zeros((SIZE, SIZE))
    alpha[MASK] = 255.0
    
    arr = np.dstack([r, g, b, alpha])
    save_image(arr, 'assets/planets/moon.png')

# 10. SUN
def render_sun():
    noise1 = perlin_noise_2d(SIZE, SIZE, freq=7.0, octaves=5, seed=111)
    noise2 = perlin_noise_2d(SIZE, SIZE, freq=12.0, octaves=4, seed=222)
    granulation = noise1 * 0.6 + noise2 * 0.4
    
    # Blazing solar corona (radiating outwards up to R=1.28)
    r = np.zeros((SIZE, SIZE))
    g = np.zeros((SIZE, SIZE))
    b = np.zeros((SIZE, SIZE))
    alpha = np.zeros((SIZE, SIZE))
    
    # Disk
    disk_r = 255.0
    disk_g = 215.0 + 35.0 * granulation
    disk_b = 80.0 + 70.0 * granulation
    # Center is white hot, edge is orange-yellow
    center_heat = np.maximum(0.0, 1.0 - R2) ** 1.8
    disk_r = disk_r * (1 - center_heat) + 255 * center_heat
    disk_g = disk_g * (1 - center_heat) + 250 * center_heat
    disk_b = disk_b * (1 - center_heat) + 220 * center_heat
    
    r[MASK] = disk_r[MASK]
    g[MASK] = disk_g[MASK]
    b[MASK] = disk_b[MASK]
    alpha[MASK] = 255.0
    
    # Brilliant radiant corona
    corona = (R2 > 1.0) & (R2 < 1.45)
    falloff = np.maximum(0.0, (1.45 - np.sqrt(R2[corona])) / 0.45) ** 1.8
    r[corona] = 255 * falloff
    g[corona] = (160 + 80 * falloff) * falloff
    b[corona] = 40 * (falloff ** 2.0)
    alpha[corona] = 230 * falloff
    
    arr = np.dstack([r, g, b, alpha])
    save_image(arr, 'assets/planets/sun.png')

# 11. PLUTO
def render_pluto():
    noise = perlin_noise_2d(SIZE, SIZE, freq=6.0, octaves=5, seed=333)
    # Bright heart-shaped Tombaugh Regio
    dist_heart = np.sqrt(((LAT + 0.15) * 2.2)**2 + ((LON - 0.1) * 2.0)**2)
    heart = np.maximum(0.0, 1.0 - dist_heart) ** 2.0
    
    r = (150 + 60 * noise) * (1 - heart) + 235 * heart
    g = (120 + 40 * noise) * (1 - heart) + 215 * heart
    b = (95 + 30 * noise) * (1 - heart) + 195 * heart
    
    r = r * DIFFUSE
    g = g * DIFFUSE
    b = b * DIFFUSE
    
    alpha = np.zeros((SIZE, SIZE))
    alpha[MASK] = 255.0
    
    arr = np.dstack([r, g, b, alpha])
    save_image(arr, 'assets/planets/pluto.png')

# 12. COSMIC NEBULA BACKGROUND (High resolution space background for UI)
def render_cosmic_background():
    w, h = 1080, 1920
    print("Generating cosmic background...")
    # Base deep dark void (#070A14)
    r = np.full((h, w), 8.0)
    g = np.full((h, w), 11.0)
    b = np.full((h, w), 22.0)
    
    # Layer 1: Deep purple / magenta swirling nebula clouds
    nebula1 = perlin_noise_2d(w, h, freq=2.5, octaves=5, seed=777)
    nebula1 = np.maximum(0.0, (nebula1 - 0.35) / 0.65) ** 1.6
    r += nebula1 * 95.0   # purple/magenta
    g += nebula1 * 25.0
    b += nebula1 * 125.0
    
    # Layer 2: Glowing cyan / teal cosmic dust clouds
    nebula2 = perlin_noise_2d(w, h, freq=3.0, octaves=5, seed=888)
    nebula2 = np.maximum(0.0, (nebula2 - 0.42) / 0.58) ** 2.0
    r += nebula2 * 10.0
    g += nebula2 * 115.0  # teal
    b += nebula2 * 155.0
    
    # Layer 3: Starfield
    np.random.seed(999)
    star_mask = np.random.rand(h, w) > 0.9982
    star_brightness = np.random.rand(h, w)
    
    r[star_mask] = 200 + 55 * star_brightness[star_mask]
    g[star_mask] = 210 + 45 * star_brightness[star_mask]
    b[star_mask] = 235 + 20 * star_brightness[star_mask]
    
    alpha = np.full((h, w), 255.0)
    arr = np.dstack([r, g, b, alpha])
    save_image(arr, 'assets/images/cosmic_bg.png')

# 13. ARTHUR DENT SPACE ADVENTURER AVATAR
def render_avatar():
    im = Image.new('RGBA', (256, 256), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    
    # Glowing circular border
    draw.ellipse([4, 4, 252, 252], fill=(20, 28, 55, 255), outline=(0, 229, 255, 255), width=4)
    # Inner astronaut helmet / adventurer silhouette
    # Helmet visor gradient
    draw.ellipse([50, 45, 206, 175], fill=(35, 48, 88, 255), outline=(120, 100, 220, 255), width=3)
    draw.ellipse([70, 70, 186, 155], fill=(0, 195, 255, 180), outline=(0, 242, 254, 255), width=2)
    # Visor reflection
    draw.arc([80, 80, 150, 130], start=200, end=310, fill=(255, 255, 255, 220), width=4)
    # Suit shoulders
    draw.pieslice([20, 150, 236, 280], start=180, end=360, fill=(45, 60, 105, 255), outline=(0, 229, 255, 200), width=3)
    # Badge on suit
    draw.ellipse([116, 175, 140, 199], fill=(0, 229, 255, 255))
    
    im.save('assets/images/avatar.png')
    print("Saved: assets/images/avatar.png")

print("Rendering Earth...")
render_earth()
print("Rendering Mars...")
render_mars()
print("Rendering Jupiter...")
render_jupiter()
print("Rendering Saturn...")
render_saturn()
print("Rendering Venus...")
render_venus()
print("Rendering Mercury...")
render_mercury()
print("Rendering Uranus...")
render_uranus()
print("Rendering Neptune...")
render_neptune()
print("Rendering Moon...")
render_moon()
print("Rendering Sun...")
render_sun()
print("Rendering Pluto...")
render_pluto()
render_cosmic_background()
render_avatar()
print("ALL ASSETS GENERATED SUCCESSFULLY!")
