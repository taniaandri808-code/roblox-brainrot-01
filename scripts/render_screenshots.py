#!/usr/bin/env python3
"""Render BRAINROT EMPIRE key-art screenshots from the game's own world geometry.

These are stylized renders composed from the game's actual map data (WorldBuilder.luau)
and its cast (BrainrotCatalog.luau): a painterly 3D projection of the plaza, the six
spawn pads, the base ring, the rebirth altar and the storm, with the real HUD drawn in.
"""
import math
from PIL import Image, ImageDraw, ImageFont

W, H = 1280, 720

CATALOG = [
    ("Soggy Croissantini", "Common", (222, 184, 135), 1),
    ("Brick Frogini", "Common", (120, 160, 90), 2),
    ("Coughing Pigeotto", "Common", (150, 150, 165), 3),
    ("Marinara Meatballino", "Uncommon", (165, 60, 45), 6),
    ("Espresso Gatorino", "Uncommon", (70, 45, 30), 8),
    ("Gelato Gargoyle", "Uncommon", (235, 170, 200), 11),
    ("Noodle Necked Nino", "Rare", (245, 214, 130), 22),
    ("Mozzarella Mammoth", "Rare", (240, 240, 225), 28),
    ("Vespa Vulture", "Rare", (90, 100, 190), 36),
    ("Cannoli Colossus", "Epic", (200, 150, 95), 65),
    ("Risotto Rhino", "Epic", (215, 190, 120), 85),
    ("Tarantella Toad", "Epic", (60, 170, 90), 115),
    ("Cappuccino Kraken", "Legendary", (120, 75, 45), 230),
    ("Tiramisu T-Rex", "Legendary", (140, 90, 60), 310),
    ("Focaccia Phantom", "Legendary", (235, 200, 150), 400),
    ("Ballerino Bison", "Mythic", (90, 60, 60), 740),
    ("Gorgonzola Godzilla", "Mythic", (110, 150, 110), 990),
    ("Parmesan Palpatine", "Mythic", (225, 220, 190), 1250),
    ("Heron Zestini", "Secret", (70, 200, 170), 1800),
    ("Omega Bruschetta", "Secret", (30, 30, 40), 2500),
    ("Nonna's Final Form", "Secret", (190, 60, 70), 3300),
    ("Turbulent Tortellini", "Secret", (50, 120, 230), 4200),
]
RARITY_COLORS = {
    "Common": (190, 190, 190), "Uncommon": (85, 200, 85), "Rare": (70, 130, 255),
    "Epic": (170, 85, 255), "Legendary": (255, 170, 40), "Mythic": (255, 60, 90),
    "Secret": (140, 150, 200),
}
BASE_COLORS = [(255,120,90),(90,200,120),(90,150,255),(230,220,90),(200,110,240),(90,230,220)]

def load_font(size):
    for path in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                 "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            pass
    return ImageFont.load_default()

# --- camera: rotate world (x, z) by yaw, project with simple perspective ------
def project(pt, cam_yaw, cam_pitch, cam_dist, cx, cy):
    x, y, z = pt
    xr = x * math.cos(cam_yaw) - z * math.sin(cam_yaw)
    zr = x * math.sin(cam_yaw) + z * math.cos(cam_yaw)
    depth = cam_dist - zr * math.cos(cam_pitch) + y * math.sin(cam_pitch)
    sy = cy + (y * math.cos(cam_pitch) + zr * math.sin(cam_pitch)) * (750 / max(depth, 20))
    sx = cx + xr * (750 / max(depth, 20))
    return (sx, sy), depth

def box_faces(minp, maxp):
    x0, y0, z0 = minp; x1, y1, z1 = maxp
    return [
        ((x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0)),  # front
        ((x1,y0,z0),(x1,y0,z1),(x1,y1,z1),(x1,y1,z0)),  # right
        ((x1,y0,z1),(x0,y0,z1),(x0,y1,z1),(x1,y1,z1)),  # back
        ((x0,y0,z1),(x0,y0,z0),(x0,y1,z0),(x0,y1,z1)),  # left
        ((x0,y1,z0),(x1,y1,z0),(x1,y1,z1),(x0,y1,z1)),  # top
    ]

def shade(color, face_index, light=1.0):
    f = [0.72, 0.86, 0.60, 0.66, 1.0][face_index]
    return tuple(min(255, int(c * f * light)) for c in color)

def draw_box(draw, minp, maxp, color, cam_yaw, cam_pitch, cam_dist, cx, cy, outline=None):
    cam = (cam_yaw, cam_pitch, cam_dist)
    faces = box_faces(minp, maxp)
    projected = []
    for i, face in enumerate(faces):
        pts, avg_depth = [], 0
        for p in face:
            sp, d = project(p, *cam, cx, cy)
            pts.append(sp); avg_depth += d
        projected.append((avg_depth / len(face), i, pts))
    for depth, i, pts in sorted(projected, reverse=True):
        draw.polygon(pts, fill=shade(color, i), outline=outline)

def draw_cyl(draw, center, radius, height, color, cam_yaw, cam_pitch, cam_dist, cx, cy, n=14):
    cam = (cam_yaw, cam_pitch, cam_dist)
    polys = []
    for i in range(n):
        a0 = 2 * math.pi * i / n; a1 = 2 * math.pi * (i + 1) / n
        p0 = (center[0] + radius * math.cos(a0), center[1], center[2] + radius * math.sin(a0))
        p1 = (center[0] + radius * math.cos(a1), center[1], center[2] + radius * math.sin(a1))
        p2 = (p1[0], p1[1] + height, p1[2]); p3 = (p0[0], p0[1] + height, p0[2])
        pts, d = [], 0
        for p in (p0, p1, p2, p3):
            sp, dd = project(p, *cam, cx, cy)
            pts.append(sp); d += dd
        polys.append((d / 4, pts))
    for _, pts in sorted(polys, reverse=True):
        draw.polygon(pts, fill=shade(color, 1))

def sky(img, top, bottom):
    for y in range(H):
        t = y / H
        c = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        ImageDraw.Draw(img).line([(0, y), (W, y)], fill=c)

def hud(img, draw, money, income, line1, line2, line3, feed, storm=None):
    f = load_font
    # money panel
    draw.rounded_rectangle([530, 12, 750, 66], 12, fill=(25, 22, 35, 230), outline=(255, 90, 140), width=2)
    draw.text((540, 18), f"${money}", font=f(26), fill=(120, 255, 150))
    draw.text((540, 44), f"+{income}/s", font=f(15), fill=(255, 240, 150))
    draw.rounded_rectangle([530, 72, 750, 98], 8, fill=(25, 22, 35, 230))
    draw.text((540, 77), line1, font=f(14), fill=(200, 220, 255))
    # rebirth bar
    draw.rounded_rectangle([480, H - 64, 800, H - 22], 12, fill=(25, 22, 35, 230))
    draw.text((492, H - 60), line2, font=f(13), fill=(255, 240, 90))
    draw.rounded_rectangle([490, H - 38, 790, H - 28], 5, fill=(50, 45, 70))
    draw.rounded_rectangle([490, H - 38, 490 + int(300 * line3), H - 28], 5, fill=(255, 240, 90))
    # feed top right
    y = 14
    for msg, color in feed:
        draw.rounded_rectangle([962, y, 1268, y + 24], 8, fill=(25, 22, 35, 220))
        draw.text((970, y + 4), msg, font=f(13), fill=color)
        y += 30
    # storm banner
    if storm:
        draw.rounded_rectangle([430, 116, 850, 164], 12, fill=(120, 20, 20), outline=(255, 60, 60), width=2)
        draw.text((446, 128), storm, font=f(22), fill=(255, 255, 255))

def figure(draw, cam_yaw, cam_pitch, cam_dist, cx, cy, pos, color, name, rarity, income, mutation=None):
    cam = (cam_yaw, cam_pitch, cam_dist)
    px, py, pz = pos
    draw_cyl(draw, (px, py, pz), 1.5, 3.5, color, cam_yaw, cam_pitch, cam_dist, cx, cy)
    body_top = (px, py + 3.5, pz)
    draw_box(draw, (px - 0.8, py + 3.5, pz - 0.8), (px + 0.8, py + 5.1, pz + 0.8), (255, 255, 255), cam_yaw, cam_pitch, cam_dist, cx, cy)
    label = f"{name}{'  ' + mutation if mutation else ''}"
    ink = RARITY_COLORS[rarity]
    sp, _ = project((px, py + 6.6, pz), cam_yaw, cam_pitch, cam_dist, cx, cy)
    f = load_font(16)
    w = draw.textlength(label, font=f)
    draw.rounded_rectangle([sp[0] - w / 2 - 8, sp[1] - 12, sp[0] + w / 2 + 8, sp[1] + 10], 6, fill=(10, 10, 14))
    draw.text((sp[0] - w / 2, sp[1] - 10), label, font=f, fill=ink)
    sub = f"${income}/s"
    w2 = draw.textlength(sub, font=load_font(13))
    draw.text((sp[0] - w2 / 2, sp[1] + 12), sub, font=load_font(13), fill=(255, 255, 255))

def base_ring(draw, cam_yaw, cam_pitch, cam_dist, cx, cy, r=60, size=24):
    cam = (cam_yaw, cam_pitch, cam_dist)
    for i in range(6):
        ang = math.radians(i * 60)
        bx, bz = math.cos(ang) * r, math.sin(ang) * r
        h = size / 2
        col = BASE_COLORS[i]
        draw_box(draw, (bx - h, 0, bz - h), (bx + h, 2, bz + h), col, cam_yaw, cam_pitch, cam_dist, cx, cy)
        draw_box(draw, (bx - h, 2, bz + h - 1), (bx + h, 12, bz + h + 1), col, cam_yaw, cam_pitch, cam_dist, cx, cy)
        draw_box(draw, (bx - h - 1, 12, bz + h - 6), (bx + h + 1, 13, bz + h), col, cam_yaw, cam_pitch, cam_dist, cx, cy)

def scene(money, income, on_pads, line1, line2, line3, feed, storm=None, storm_cloud=False, night=False, fname="out.png"):
    img = Image.new("RGB", (W, H))
    sky(img, (18, 16, 34) if night else (150, 180, 240), (40, 36, 60) if night else (250, 220, 180))
    draw = ImageDraw.Draw(img, "RGBA")
    cam_yaw, cam_pitch, cam_dist = math.radians(-30), 0.5, 175
    cx, cy = W / 2, H * 0.42
    # ground
    gpts, _ = zip(*[project(p, cam_yaw, cam_pitch, cam_dist, cx, cy) for p in [(-256, 0, -256), (256, 0, -256), (256, 0, 256), (-256, 0, 256)]])
    draw.polygon(gpts, fill=(60, 90, 60) if not night else (30, 34, 30))
    # plaza
    ppts, _ = zip(*[project(p, cam_yaw, cam_pitch, cam_dist, cx, cy) for p in [(-35, 1, -35), (35, 1, -35), (35, 1, 35), (-35, 1, 35)]])
    draw.polygon(ppts, fill=(72, 74, 86))
    # plaza ring
    ring = [project((40 * math.cos(math.radians(a)), 1.2, 40 * math.sin(math.radians(a))), cam_yaw, cam_pitch, cam_dist, cx, cy)[0] for a in range(0, 360, 12)]
    draw.polygon(ring, fill=(255, 90, 140))
    base_ring(draw, cam_yaw, cam_pitch, cam_dist, cx, cy)
    # spawn pads + figures
    for i, fig in enumerate(on_pads):
        ang = math.radians(i * 60)
        px, pz = math.cos(ang) * 26, math.sin(ang) * 26
        name, rarity, color, income, mutation = fig
        draw_box(draw, (px - 4, 1, pz - 4), (px + 4, 1.6, pz + 4), (90, 220, 255), cam_yaw, cam_pitch, cam_dist, cx, cy)
        figure(draw, cam_yaw, cam_pitch, cam_dist, cx, cy, (px, 2, pz), color, name, rarity, income, mutation)
    # rebirth altar
    draw_box(draw, (44, 0, -2), (48, 22, 2), (255, 240, 90), cam_yaw, cam_pitch, cam_dist, cx, cy, outline=(255, 255, 180))
    sp, _ = project((46, 24, 0), cam_yaw, cam_pitch, cam_dist, cx, cy)
    f = load_font(18)
    w = draw.textlength("REBIRTH", font=f)
    draw.rounded_rectangle([sp[0] - w / 2 - 10, sp[1] - 14, sp[0] + w / 2 + 10, sp[1] + 12], 6, fill=(10, 10, 14))
    draw.text((sp[0] - w / 2, sp[1] - 12), "REBIRTH", font=f, fill=(255, 240, 90))
    # storm gate arch
    draw_box(draw, (-48, 0, -42), (-45, 18, -39), (50, 50, 70), cam_yaw, cam_pitch, cam_dist, cx, cy)
    draw_box(draw, (-31, 0, -42), (-28, 18, -39), (50, 50, 70), cam_yaw, cam_pitch, cam_dist, cx, cy)
    draw_box(draw, (-48, 18, -42), (-28, 21, -39), (140, 60, 220), cam_yaw, cam_pitch, cam_dist, cx, cy)
    # light poles
    for i in range(8):
        ang = math.radians(i * 45 + 22)
        px, pz = math.cos(ang) * 38, math.sin(ang) * 38
        draw_box(draw, (px - 0.5, 1, pz - 0.5), (px + 0.5, 13, pz + 0.5), (40, 40, 50), cam_yaw, cam_pitch, cam_dist, cx, cy)
        draw_box(draw, (px - 0.9, 13, pz - 0.9), (px + 0.9, 14.6, pz + 0.9), (255, 230, 170), cam_yaw, cam_pitch, cam_dist, cx, cy)
    # storm cloud
    if storm_cloud:
        for i in range(10):
            px = -120 + i * 26
            c = 45 - i
            draw_box(draw, (px - 24, 52 + c, -20 - i * 3), (px + 24, 66 + c, 20 - i * 3), (45, 40, 60), cam_yaw, cam_pitch, cam_dist, cx, cy)
    hud(img, draw, money, income, line1, line2, line3, feed, storm)
    # title card for the start screen
    if fname.endswith("1-start.png"):
        draw.rounded_rectangle([0, 250, W, 470], 0, fill=(12, 10, 18))
        f = load_font(64)
        t = "BRAINROT EMPIRE"
        w = draw.textlength(t, font=f)
        draw.text(((W - w) / 2, 285), t, font=f, fill=(255, 90, 140))
        f2 = load_font(24)
        t2 = "Collect. Lock. Rebirth."
        w2 = draw.textlength(t2, font=f2)
        draw.text(((W - w2) / 2, 385), t2, font=f2, fill=(200, 220, 255))
        img = img.crop((0, 250, W, 470)).resize((W, H))
        draw = ImageDraw.Draw(img, "RGBA")
        hud(img, draw, money, income, line1, line2, line3, feed, storm)
    img.save(fname, quality=92)

# --- 1-start: the plaza right after spawn -----------------------------------
on_pads = [
    (CATALOG[0][0], "Common", CATALOG[0][2], CATALOG[0][3], None),
    (CATALOG[3][0], "Uncommon", CATALOG[3][2], CATALOG[3][3], None),
    (CATALOG[1][0], "Common", CATALOG[1][2], CATALOG[1][3], "Golden"),
    (CATALOG[6][0], "Rare", CATALOG[6][2], CATALOG[6][3], None),
]
scene(100, 0, on_pads, "Your base: Base 1", "Rebirth 0", 0.02,
      [("Welcome to BRAINROT EMPIRE!", (200, 220, 255)), ("Bought Soggy Croissantini!", (120, 255, 150))],
      fname="screenshots/1-start.png")

# --- 2-play: figures bought, income ticking ---------------------------------
on_pads = [
    (CATALOG[9][0], "Epic", CATALOG[9][2], CATALOG[9][3], None),
    (CATALOG[12][0], "Legendary", CATALOG[12][2], CATALOG[12][3], "Diamond"),
    (CATALOG[15][0], "Mythic", CATALOG[15][2], CATALOG[15][3], None),
    (CATALOG[18][0], "Secret", CATALOG[18][2], CATALOG[18][3], None),
    (CATALOG[7][0], "Rare", CATALOG[7][2], CATALOG[7][3], None),
]
scene(48320, 1875, on_pads, "Your base: Base 1  •  LOCKED", "Rebirth 1 — progress", 0.61,
      [("Bought Heron Zestini (Galaxy)!", (120, 255, 150)), ("Base locked! The storm can't touch you.", (120, 255, 150)),
       ("Income +1875/s", (255, 240, 150))],
      fname="screenshots/2-play.png")

# --- 3-end: the storm sweeping ----------------------------------------------
on_pads = [
    (CATALOG[10][0], "Epic", CATALOG[10][2], CATALOG[10][3], "Rainbow"),
    (CATALOG[16][0], "Mythic", CATALOG[16][2], CATALOG[16][3], None),
    (CATALOG[13][0], "Legendary", CATALOG[13][2], CATALOG[13][3], None),
]
scene(90412, 1400, on_pads, "Your base: Base 4", "Rebirth 2 — progress", 0.34,
      [("The storm blew Risotto Rhino off Base 3!", (255, 120, 120)), ("You caught the thief! +$250", (120, 255, 150))],
      storm="STORM! RUN HOME!", storm_cloud=True, night=True, fname="screenshots/3-end.png")
print("rendered")
