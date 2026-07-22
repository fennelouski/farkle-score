#!/usr/bin/env python3
"""Compose App Store marketing images for Farkle Score.

Canvas: 1320x2868 (iPhone 6.9" portrait). Each image: caption text above a framed
screenshot on a branded gradient background. TV/AirPlay composites show the external
scoreboard in a TV mockup with a phone in front.
"""

import os
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

import pathlib
REPO = pathlib.Path(__file__).resolve().parent.parent
IPAD = "ipad" in sys.argv[1:]
if IPAD:
    # Landscape iPad set (raw captures are taken in landscape).
    RAW = str(REPO / "screenshots/en-US/iPad Pro 13-inch (M5)")
    OUT = str(REPO / "screenshots/marketing-ipad")
    W, H = 2752, 2064  # App Store iPad Pro 13" landscape
    S = 1.5  # hand-picked: W-proportional type is too big for the short canvas
else:
    RAW = str(REPO / "screenshots/en-US/iPhone 17 Pro Max")
    OUT = str(REPO / "screenshots/marketing")
    W, H = 1284, 2778  # App Store 6.5" — ASC rejects 1320×2868 for this listing
    S = W / 1320  # layout constants below were tuned on the 1320×2868 canvas


def s(v):
    return int(v * S)

# App palette
NAVY_TOP = (14, 21, 32)
NAVY_BOT = (26, 36, 52)
LIGHT_TOP = (243, 245, 249)
LIGHT_BOT = (222, 229, 240)
BLUE = (38, 97, 217)
BLUE_BRIGHT = (115, 166, 255)
YELLOW = (255, 217, 51)
GREEN = (51, 199, 115)
DARK_TEXT = (18, 24, 33)
WHITE = (255, 255, 255)
MUTED_LIGHT = (86, 95, 110)
MUTED_DARK = (176, 186, 200)


def font(size, bold=True):
    try:
        f = ImageFont.truetype("/System/Library/Fonts/SFNSRounded.ttf", size)
        f.set_variation_by_name("Bold" if bold else "Regular")
        return f
    except Exception:
        name = "Arial Rounded Bold.ttf" if bold else "Arial.ttf"
        return ImageFont.truetype(f"/System/Library/Fonts/Supplemental/{name}", size)


def gradient(size, top, bottom):
    w, h = size
    col = Image.new("RGB", (1, h))
    px = []
    for y in range(h):
        t = y / max(1, h - 1)
        px.append(tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    col.putdata(px)
    return col.resize((w, h))


def add_glow(img, center, radius, color, alpha=70):
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(glow)
    x, y = center
    d.ellipse([x - radius, y - radius, x + radius, y + radius], fill=color + (alpha,))
    glow = glow.filter(ImageFilter.GaussianBlur(radius * 0.55))
    img.alpha_composite(glow)


def background(dark=False, glows=None):
    base = gradient((W, H), NAVY_TOP if dark else LIGHT_TOP,
                    NAVY_BOT if dark else LIGHT_BOT).convert("RGBA")
    for (cx, cy, r, color, a) in (glows or []):
        # glow coordinates were tuned on the 1320x2868 canvas
        add_glow(base, (int(cx * W / 1320), int(cy * H / 2868)), s(r), color, a)
    return base


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1], radius=radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def drop_shadow(canvas, box, radius, blur=60, alpha=110, offset=(0, 36)):
    x0, y0, x1, y1 = box
    sh = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(sh)
    d.rounded_rectangle([x0 + offset[0], y0 + offset[1], x1 + offset[0], y1 + offset[1]],
                        radius=radius, fill=(0, 0, 0, alpha))
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    canvas.alpha_composite(sh)


def phone_framed(shot, target_w, corner=150, bezel=None, top_crop=0):
    """Return an RGBA phone mockup image of width target_w."""
    bezel = bezel if bezel is not None else s(24)
    img = shot.convert("RGB")
    if top_crop:
        img = img.crop((0, top_crop, img.width, img.height))
    scale = (target_w - 2 * bezel) / img.width
    inner_w = target_w - 2 * bezel
    inner_h = int(img.height * scale)
    img = img.resize((inner_w, inner_h), Image.LANCZOS)
    img = rounded(img, int(corner * scale))
    frame_w = target_w
    frame_h = inner_h + 2 * bezel
    frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    d = ImageDraw.Draw(frame)
    d.rounded_rectangle([0, 0, frame_w - 1, frame_h - 1],
                        radius=int(corner * scale) + bezel,
                        fill=(10, 12, 16, 255))
    d.rounded_rectangle([6, 6, frame_w - 7, frame_h - 7],
                        radius=int(corner * scale) + bezel - 6,
                        outline=(70, 76, 88, 255), width=3)
    frame.alpha_composite(img, (bezel, bezel))
    return frame


def tv_framed(shot, target_w, bezel=None):
    """TV mockup: dark bezel around the landscape scoreboard + stand."""
    bezel = bezel if bezel is not None else s(20)
    img = shot.convert("RGB")
    inner_w = target_w - 2 * bezel
    inner_h = int(img.height * inner_w / img.width)
    img = img.resize((inner_w, inner_h), Image.LANCZOS)
    frame_w = target_w
    screen_h = inner_h + 2 * bezel
    stand_h = s(110)
    frame = Image.new("RGBA", (frame_w, screen_h + stand_h), (0, 0, 0, 0))
    d = ImageDraw.Draw(frame)
    # panel
    d.rounded_rectangle([0, 0, frame_w - 1, screen_h - 1], radius=s(26), fill=(6, 8, 12, 255))
    d.rounded_rectangle([3, 3, frame_w - 4, screen_h - 4], radius=s(24),
                        outline=(66, 72, 84, 255), width=3)
    frame.paste(img, (bezel, bezel))
    # stand: neck + base
    cx = frame_w // 2
    d.rectangle([cx - s(70), screen_h, cx + s(70), screen_h + stand_h - s(34)],
                fill=(38, 44, 54, 255))
    d.rounded_rectangle([cx - s(330), screen_h + stand_h - s(40), cx + s(330),
                         screen_h + stand_h - s(6)],
                        radius=s(18), fill=(52, 59, 71, 255))
    return frame, screen_h


def airplay_pill(text="AirPlay"):
    f = font(s(44))
    pad_x, pad_y = s(34), s(22)
    glyph_w = s(64)
    tmp = ImageDraw.Draw(Image.new("RGBA", (10, 10)))
    tb = tmp.textbbox((0, 0), text, font=f)
    tw, th = tb[2] - tb[0], tb[3] - tb[1]
    w = pad_x * 2 + glyph_w + s(16) + tw
    h = pad_y * 2 + max(th, s(52))
    pill = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(pill)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=h // 2, fill=(12, 17, 26, 235))
    d.rounded_rectangle([2, 2, w - 3, h - 3], radius=h // 2 - 2,
                        outline=(BLUE_BRIGHT + (200,)), width=3)
    # AirPlay glyph: screen outline + triangle
    gx = pad_x
    gy = h // 2 - s(26)
    d.rounded_rectangle([gx, gy, gx + s(56), gy + s(38)], radius=s(8),
                        outline=(255, 255, 255, 255), width=s(5))
    d.polygon([(gx + s(28), gy + s(26)), (gx + s(6), gy + s(52)), (gx + s(50), gy + s(52))],
              fill=(255, 255, 255, 255))
    d.text((gx + glyph_w + s(16), h // 2 - th // 2 - tb[1]), text, font=f, fill=WHITE)
    return pill


def draw_caption(canvas, text, dark_bg, y=170, size=104, max_w=1140, sub=None):
    y, size, max_w = s(y), s(size), s(max_w)
    d = ImageDraw.Draw(canvas)
    color = WHITE if dark_bg else DARK_TEXT
    f = font(size)

    def wrap(fnt):
        # Explicit "\n" forces a line break; each paragraph wraps to max_w.
        out = []
        for para in text.split("\n"):
            cur = ""
            for wd in para.split():
                trial = (cur + " " + wd).strip()
                tb = d.textbbox((0, 0), trial, font=fnt)
                if tb[2] - tb[0] > max_w and cur:
                    out.append(cur)
                    cur = wd
                else:
                    cur = trial
            out.append(cur)
        return out

    lines = wrap(f)
    if len(lines) > 2:  # shrink once if needed
        f = font(int(size * 0.85))
        lines = wrap(f)
    line_h = int(size * 1.18)
    yy = y
    for line in lines:
        tb = d.textbbox((0, 0), line, font=f)
        d.text(((W - (tb[2] - tb[0])) // 2 - tb[0], yy), line, font=f, fill=color)
        yy += line_h
    # accent bar
    bar_w = s(220)
    d.rounded_rectangle([(W - bar_w) // 2, yy + s(26), (W + bar_w) // 2, yy + s(44)],
                        radius=s(9), fill=YELLOW)
    if sub:
        fs = font(s(46), bold=True)
        tb = d.textbbox((0, 0), sub, font=fs)
        d.text(((W - (tb[2] - tb[0])) // 2 - tb[0], yy + s(84)), sub, font=fs,
               fill=MUTED_DARK if dark_bg else MUTED_LIGHT)
        yy += s(84 + 56)
    return yy + s(70)  # content start y


def load(name):
    return Image.open(os.path.join(RAW, name))


def load_tv(name):
    # TV mockup content is device-independent; the iPhone landscape capture has the
    # widest, most TV-like aspect, so always use it.
    return Image.open(str(REPO / "screenshots/en-US/iPhone 17 Pro Max" / name))


def save(canvas, index, slug):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, f"{index:02d}_{slug}.png")
    canvas.convert("RGB").save(path, "PNG")
    print("wrote", path)


def phone_feature(index, slug, shot_name, caption, sub=None, dark=True, glows=None,
                  top_crop=0):
    glows = glows or [(240, 500, 420, BLUE, 40), (1120, 2500, 460, YELLOW, 34)]
    canvas = background(dark, glows)
    content_y = draw_caption(canvas, caption, dark, sub=sub)
    avail_h = H - content_y - s(90)
    phone = phone_framed(load(shot_name), s(1010), top_crop=top_crop)
    if phone.height > avail_h:
        scale = avail_h / phone.height
        phone = phone.resize((int(phone.width * scale), int(phone.height * scale)),
                             Image.LANCZOS)
    x = (W - phone.width) // 2
    y = content_y + (avail_h - phone.height) // 2 + s(20)
    drop_shadow(canvas, (x, y, x + phone.width, y + phone.height), s(170))
    canvas.alpha_composite(phone, (x, y))
    save(canvas, index, slug)


def tv_composite(index, slug, caption, sub=None, tv_shot="06_TVScoreboard.png",
                 phone_shot="01_ScoreKeypad.png", phone_side="right", show_pill=True):
    canvas = background(True, [(300, 480, 460, BLUE, 46), (1050, 1500, 420, GREEN, 26),
                               (700, 2600, 500, YELLOW, 30)])
    content_y = draw_caption(canvas, caption, True, sub=sub)
    tv, screen_h = tv_framed(load_tv(tv_shot), s(1240))
    tv_x = (W - tv.width) // 2
    tv_y = content_y + s(120)
    drop_shadow(canvas, (tv_x, tv_y, tv_x + tv.width, tv_y + screen_h), s(26), blur=70,
                alpha=130)
    canvas.alpha_composite(tv, (tv_x, tv_y))
    if show_pill:
        pill = airplay_pill()
        canvas.alpha_composite(pill, ((W - pill.width) // 2, tv_y - pill.height - s(36)))
    # a 4:3 tablet at phone width would bury the TV; keep the companion smaller on iPad
    phone = phone_framed(load(phone_shot), s(520) if IPAD else s(640))
    if phone.height > s(1620):
        sc = s(1620) / phone.height
        phone = phone.resize((int(phone.width * sc), int(phone.height * sc)), Image.LANCZOS)
    px = W - phone.width - s(90) if phone_side == "right" else s(90)
    py = H - phone.height - s(110)
    drop_shadow(canvas, (px, py, px + phone.width, py + phone.height), s(150), blur=70,
                alpha=150)
    canvas.alpha_composite(phone, (px, py))
    save(canvas, index, slug)


def tv_solo(index, slug, caption, sub=None, tv_shot="06_TVScoreboard.png"):
    canvas = background(True, [(280, 520, 480, BLUE, 48), (1080, 2350, 520, YELLOW, 34)])
    content_y = draw_caption(canvas, caption, True, sub=sub)
    tv, screen_h = tv_framed(load_tv(tv_shot), s(1250))
    tv_x = (W - tv.width) // 2
    tv_y = content_y + (H - content_y - tv.height) // 2 - s(60)
    drop_shadow(canvas, (tv_x, tv_y, tv_x + tv.width, tv_y + screen_h), s(26), blur=70,
                alpha=130)
    canvas.alpha_composite(tv, (tv_x, tv_y))
    pill = airplay_pill()
    canvas.alpha_composite(pill, ((W - pill.width) // 2, tv_y + tv.height + s(70)))
    save(canvas, index, slug)


def dual_phone(index, slug, caption, sub, left_shot, right_shot):
    canvas = background(True, [(260, 560, 440, BLUE, 42), (1100, 2450, 470, GREEN, 30)])
    content_y = draw_caption(canvas, caption, True, sub=sub)
    avail_h = H - content_y - s(120)
    ph_l = phone_framed(load(left_shot), s(760))
    ph_r = phone_framed(load(right_shot), s(760))
    scale = min(1.0, (avail_h - s(160)) / ph_l.height)
    ph_l = ph_l.resize((int(ph_l.width * scale), int(ph_l.height * scale)), Image.LANCZOS)
    ph_r = ph_r.resize((int(ph_r.width * scale), int(ph_r.height * scale)), Image.LANCZOS)
    ph_l = ph_l.rotate(4, expand=True, resample=Image.BICUBIC)
    ph_r = ph_r.rotate(-4, expand=True, resample=Image.BICUBIC)
    lx, ly = s(40), content_y + s(120)
    rx, ry = W - ph_r.width - s(40), content_y + s(240)
    for img, (x, y) in ((ph_l, (lx, ly)), (ph_r, (rx, ry))):
        sh = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        blurred = img.split()[3].point(lambda a: min(a, 120))
        tmp = Image.new("RGBA", img.size, (0, 0, 0, 0))
        tmp.putalpha(blurred)
        sh.alpha_composite(tmp, (x, y + 30))
        sh = sh.filter(ImageFilter.GaussianBlur(46))
        canvas.alpha_composite(sh)
    canvas.alpha_composite(ph_r, (rx, ry))
    canvas.alpha_composite(ph_l, (lx, ly))
    save(canvas, index, slug)


# ---- The 15 images ----

phone_feature(1, "keep_score_skip_math", "01_ScoreKeypad.png",
              "Keep score.\nSkip the math.",
              sub="The fast, friendly Farkle scorekeeper")
phone_feature(2, "game_night_effortless", "01_ScoreKeypad.png",
              "Game night scoring made effortless",
              glows=[(1080, 520, 430, GREEN, 40), (240, 2450, 470, BLUE, 40)])
phone_feature(3, "every_combo_one_tap", "02_CommonScores.png",
              "Every combo, one tap", top_crop=60,
              sub="Three pairs? Straight? It's already scored")
phone_feature(4, "point_values_built_in", "02_CommonScores.png",
              "Point values for every roll, built in", top_crop=60,
              glows=[(1080, 520, 430, YELLOW, 40), (240, 2450, 470, BLUE, 40)])
phone_feature(5, "six_players_rivalries", "03_Players.png",
              "Up to six players, endless rivalries",
              sub="Avatars, colors, and saved rosters")
phone_feature(6, "crown_the_leader", "03_Players.png",
              "Crown the leader as scores change",
              glows=[(240, 520, 430, YELLOW, 46), (1100, 2450, 460, GREEN, 32)])
phone_feature(7, "every_round_tracked", "08_History.png",
              "Every round, tracked automatically",
              sub="Round-by-round history with timestamps")
phone_feature(8, "fix_any_turn", "08_History.png",
              "Made a mistake? Fix any turn",
              glows=[(1080, 520, 430, BLUE, 42), (260, 2500, 450, YELLOW, 34)])
phone_feature(9, "make_rules_yours", "04_Settings.png",
              "Make the rules yours",
              sub="Rulesets, custom scoring, and more")
phone_feature(10, "rulesets_built_in", "05_RulesLibrary.png",
              "Classic rulesets, right in your pocket")

tv_composite(11, "airplay_live_scoreboard",
             "AirPlay a live scoreboard to your TV",
             sub="Phone in hand, scores on the big screen")
tv_composite(12, "score_phone_celebrate_tv",
             "Score on your phone. Celebrate on the TV.",
             phone_side="left", show_pill=True,
             phone_shot="02_CommonScores.png")
tv_composite(13, "game_night_front_center",
             "Game night, front and center",
             sub="A friendly welcome screen until the dice fly",
             tv_shot="07_TVScoreboardIdle.png")
tv_solo(14, "scoreboard_whole_room",
        "A live scoreboard for the whole room",
        sub="Standings, latest rolls, and the race to 10,000")

dual_phone(15, "everything_game_night",
           "Everything you need for game night",
           "Players, scores, history — all in one app",
           "03_Players.png", "01_ScoreKeypad.png")

print("done")
