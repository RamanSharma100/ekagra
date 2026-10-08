import os
import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont

def create_ekagra_logo(size, is_maskable=False):
    """
    Renders the Ekagra zen focus aperture icon.
    Deep dark background (#0B0D10), luminous concentric focus rings,
    inner gradient aperture (#7C8CFF to #9AA7FF), and central focus point.
    """
    # Render at 4x for smooth supersampling anti-aliasing
    scale = 4
    canvas_size = size * scale
    img = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    center = canvas_size / 2
    r_max = (canvas_size / 2) * 0.88

    # Rounded squircle / background
    bg_margin = canvas_size * 0.04 if not is_maskable else 0
    bg_radius = canvas_size * 0.22 if not is_maskable else 0

    if not is_maskable:
        # Subtle outer glow on dark canvas
        draw.rounded_rectangle(
            [bg_margin, bg_margin, canvas_size - bg_margin, canvas_size - bg_margin],
            radius=bg_radius,
            fill=(11, 13, 16, 255),
            outline=(37, 43, 52, 255),
            width=int(2 * scale),
        )
    else:
        draw.rectangle([0, 0, canvas_size, canvas_size], fill=(11, 13, 16, 255))

    # Ambient subtle radial glow behind center
    glow_radius = r_max * 0.7
    for step in range(int(glow_radius), 0, -int(4 * scale)):
        alpha = int(18 * (1.0 - (step / glow_radius)))
        draw.ellipse(
            [center - step, center - step, center + step, center + step],
            fill=(124, 140, 255, alpha),
        )

    # Outer faint focus track ring
    track_r = r_max * 0.72
    track_width = int(3.5 * scale)
    draw.ellipse(
        [center - track_r, center - track_r, center + track_r, center + track_r],
        outline=(40, 48, 62, 255),
        width=track_width,
    )

    # Secondary focus arc (dynamic focus segment)
    arc_r = r_max * 0.72
    draw.arc(
        [center - arc_r, center - arc_r, center + arc_r, center + arc_r],
        start=-70,
        end=140,
        fill=(124, 140, 255, 255),
        width=int(5 * scale),
    )

    # Primary focus ring (smooth luminous ring)
    ring_r = r_max * 0.52
    ring_width = int(6.5 * scale)
    draw.ellipse(
        [center - ring_r, center - ring_r, center + ring_r, center + ring_r],
        outline=(124, 140, 255, 230),
        width=ring_width,
    )

    # Inner concentration aperture circle
    inner_r = r_max * 0.32
    draw.ellipse(
        [center - inner_r, center - inner_r, center + inner_r, center + inner_r],
        fill=(26, 30, 36, 255),
        outline=(154, 167, 255, 255),
        width=int(3 * scale),
    )

    # Central Bindu / Focus Spark (One-pointed attention)
    point_r = r_max * 0.14
    draw.ellipse(
        [center - point_r, center - point_r, center + point_r, center + point_r],
        fill=(255, 255, 255, 255),
    )

    # Inner core pinpoint
    pin_r = r_max * 0.07
    draw.ellipse(
        [center - pin_r, center - pin_r, center + pin_r, center + pin_r],
        fill=(124, 140, 255, 255),
    )

    # Downsample with Lanczos filter for crisp anti-aliasing
    resampled = img.resize((size, size), Image.Resampling.LANCZOS)
    return resampled

def create_feature_graphic(width=1024, height=500):
    """
    Renders Google Play Store Feature Graphic (1024x500)
    Sleek dark gradient, illuminated zen focus symbol, typography & slogan.
    """
    scale = 2
    cw = width * scale
    ch = height * scale
    img = Image.new("RGBA", (cw, ch), (11, 13, 16, 255))
    draw = ImageDraw.Draw(img)

    # Gradient background / soft glow
    center_x = cw * 0.72
    center_y = ch * 0.5
    for r in range(int(cw * 0.55), 0, -int(8 * scale)):
        alpha = int(24 * (1.0 - (r / (cw * 0.55))))
        draw.ellipse(
            [center_x - r, center_y - r, center_x + r, center_y + r],
            fill=(124, 140, 255, alpha),
        )

    # Left accent glow
    for r in range(int(ch * 0.5), 0, -int(6 * scale)):
        alpha = int(12 * (1.0 - (r / (ch * 0.5))))
        draw.ellipse(
            [cw * 0.15 - r, ch * 0.3 - r, cw * 0.15 + r, ch * 0.3 + r],
            fill=(79, 209, 139, alpha),
        )

    # Render prominent Ekagra Symbol on right side
    logo_size = int(320 * scale)
    logo_img = create_ekagra_logo(logo_size, is_maskable=False)
    img.paste(logo_img, (int(cw * 0.65 - logo_size / 2), int(center_y - logo_size / 2)), logo_img)

    # Downscale to 1024x500
    resampled = img.resize((width, height), Image.Resampling.LANCZOS)
    draw_final = ImageDraw.Draw(resampled)

    # Text rendering on left side using default or fallback font
    try:
        font_title = ImageFont.truetype("arialbd.ttf", 64)
        font_sub = ImageFont.truetype("arial.ttf", 26)
        font_tag = ImageFont.truetype("arialbd.ttf", 18)
    except:
        font_title = ImageFont.load_default()
        font_sub = ImageFont.load_default()
        font_tag = ImageFont.load_default()

    # Tag chip
    draw_final.rounded_rectangle(
        [64, 96, 270, 132],
        radius=18,
        fill=(26, 30, 36),
        outline=(37, 43, 52),
        width=1,
    )
    draw_final.text((82, 104), "AI FOCUS COMPANION", fill=(124, 140, 255), font=font_tag)

    # App title
    draw_final.text((64, 150), "Ekagra", fill=(243, 244, 246), font=font_title)

    # Subtitle
    sub_text = "Protect your attention.\nUnderstand where your time goes.\nCalm voice-first productivity."
    draw_final.text((64, 244), sub_text, fill=(156, 163, 175), font=font_sub, spacing=10)

    # Small indicators
    draw_final.ellipse([64, 380, 72, 388], fill=(79, 209, 139))
    draw_final.text((80, 375), "Dark-First  •  On-Device Privacy  •  Natural Voice", fill=(107, 114, 128), font=font_tag)

    return resampled

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    icons_dir = os.path.join(base_dir, "assets", "icons")
    logos_dir = os.path.join(base_dir, "assets", "logos")
    os.makedirs(icons_dir, exist_ok=True)
    os.makedirs(logos_dir, exist_ok=True)

    sizes = [16, 32, 48, 72, 96, 128, 144, 192, 256, 384, 512, 1024]
    print("Generating Ekagra App Icons...")
    for sz in sizes:
        icon = create_ekagra_logo(sz)
        out_path = os.path.join(icons_dir, f"icon_{sz}x{sz}.png")
        icon.save(out_path, "PNG")
        print(f"  Created: {out_path}")

    # Standard named aliases
    create_ekagra_logo(512).save(os.path.join(logos_dir, "app_logo_512.png"), "PNG")
    create_ekagra_logo(1024).save(os.path.join(logos_dir, "app_logo_1024.png"), "PNG")

    # Feature Graphic (1024x500)
    fg = create_feature_graphic(1024, 500)
    fg_path = os.path.join(logos_dir, "feature_graphic_1024x500.png")
    fg.save(fg_path, "PNG")
    print(f"  Created: {fg_path}")

    # Copy to web icons
    web_icons_dir = os.path.join(base_dir, "web", "icons")
    if os.path.exists(web_icons_dir):
        create_ekagra_logo(192).save(os.path.join(web_icons_dir, "Icon-192.png"), "PNG")
        create_ekagra_logo(512).save(os.path.join(web_icons_dir, "Icon-512.png"), "PNG")
        create_ekagra_logo(192, is_maskable=True).save(os.path.join(web_icons_dir, "Icon-maskable-192.png"), "PNG")
        create_ekagra_logo(512, is_maskable=True).save(os.path.join(web_icons_dir, "Icon-maskable-512.png"), "PNG")
        create_ekagra_logo(32).save(os.path.join(base_dir, "web", "favicon.png"), "PNG")
        print("  Updated web/icons assets.")

    # Copy to Android mipmaps
    res_dir = os.path.join(base_dir, "android", "app", "src", "main", "res")
    mipmap_map = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, px in mipmap_map.items():
        folder_path = os.path.join(res_dir, folder)
        if os.path.exists(folder_path):
            create_ekagra_logo(px).save(os.path.join(folder_path, "ic_launcher.png"), "PNG")
            print(f"  Updated Android {folder}/ic_launcher.png ({px}x{px})")

    print("Logo & icon asset generation completed successfully!")

if __name__ == "__main__":
    main()
