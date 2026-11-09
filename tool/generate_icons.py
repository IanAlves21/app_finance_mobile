import os
import math
from PIL import Image, ImageDraw, ImageFilter

def create_super_resolution_assets():
    os.makedirs('assets/icon', exist_ok=True)

    # We render at 4096 x 4096 (4x supersampling) for vector-crisp lines and smooth anti-aliasing
    scale = 4
    canvas_size = 1024 * scale # 4096
    cx = canvas_size // 2
    cy = canvas_size // 2

    # -------------------------------------------------------------
    # 1. Background (Slate Gradient + Soft Ambient Light)
    # -------------------------------------------------------------
    bg = Image.new('RGBA', (canvas_size, canvas_size), (15, 23, 42, 255))
    draw_bg = ImageDraw.Draw(bg)

    # Smooth Radial Gradient (#0F172A -> #1E293B)
    steps = 400
    max_radius = int(canvas_size * 0.75)
    for i in range(steps, 0, -1):
        ratio = (steps - i) / steps
        # Slate 900 (15, 23, 42) to Slate 800 (30, 41, 59)
        r = int(15 + (30 - 15) * ratio)
        g = int(23 + (41 - 23) * ratio)
        b = int(42 + (59 - 42) * ratio)
        cur_radius = int(max_radius * (i / steps))
        draw_bg.ellipse(
            [cx - cur_radius, cy - cur_radius, cx + cur_radius, cy + cur_radius],
            fill=(r, g, b, 255)
        )

    # Warm subtle orange ambient light from top-right
    light_glow = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    draw_glow = ImageDraw.Draw(light_glow)
    glow_x, glow_y = int(canvas_size * 0.65), int(canvas_size * 0.35)
    glow_steps = 250
    glow_max_r = int(canvas_size * 0.45)
    for i in range(glow_steps, 0, -1):
        ratio = 1.0 - (i / glow_steps)
        alpha = int(40 * ratio * ratio)
        cur_r = int(glow_max_r * (i / glow_steps))
        draw_glow.ellipse(
            [glow_x - cur_r, glow_y - cur_r, glow_x + cur_r, glow_y + cur_r],
            fill=(249, 115, 22, alpha)
        )
    bg = Image.alpha_composite(bg, light_glow)

    # -------------------------------------------------------------
    # 2. Foreground Graphic (Card Container + Finance Glyph)
    # -------------------------------------------------------------
    fg = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))

    card_w = int(580 * scale)
    card_h = int(580 * scale)
    card_x0 = cx - card_w // 2
    card_y0 = cy - card_h // 2
    card_x1 = cx + card_w // 2
    card_y1 = cy + card_h // 2
    card_radius = int(160 * scale)

    # High quality Gaussian drop shadow for the card
    card_shadow = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    draw_shadow = ImageDraw.Draw(card_shadow)
    shadow_offset_y = int(32 * scale)
    draw_shadow.rounded_rectangle(
        [card_x0, card_y0 + shadow_offset_y, card_x1, card_y1 + shadow_offset_y],
        radius=card_radius,
        fill=(0, 0, 0, 150)
    )
    card_shadow = card_shadow.filter(ImageFilter.GaussianBlur(int(40 * scale)))
    fg = Image.alpha_composite(fg, card_shadow)

    # Draw Card Surface with inner gradient
    card_layer = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    draw_card = ImageDraw.Draw(card_layer)
    draw_card.rounded_rectangle(
        [card_x0, card_y0, card_x1, card_y1],
        radius=card_radius,
        fill=(30, 41, 59, 252) # #1E293B
    )

    # Card border with subtle accent glow
    draw_card.rounded_rectangle(
        [card_x0, card_y0, card_x1, card_y1],
        radius=card_radius,
        outline=(249, 115, 22, 190),
        width=int(7 * scale)
    )

    fg = Image.alpha_composite(fg, card_layer)
    draw_fg = ImageDraw.Draw(fg)

    # Financial Emblem: 3 Ascending Rounded Pillars with vibrant colors
    baseline_y = cy + int(140 * scale)

    # Pillar 1 (Left - navy slate)
    p1_w = int(76 * scale)
    p1_h = int(180 * scale)
    p1_x = cx - int(160 * scale)
    p1_y = baseline_y - p1_h
    p_radius = int(24 * scale)
    draw_fg.rounded_rectangle([p1_x, p1_y, p1_x + p1_w, baseline_y], radius=p_radius, fill=(71, 85, 105, 240))

    # Pillar 2 (Middle - vibrant deep orange)
    p2_w = int(76 * scale)
    p2_h = int(270 * scale)
    p2_x = cx - int(48 * scale)
    p2_y = baseline_y - p2_h
    draw_fg.rounded_rectangle([p2_x, p2_y, p2_x + p2_w, baseline_y], radius=p_radius, fill=(234, 88, 12, 250))

    # Pillar 3 (Right - brilliant light accent orange)
    p3_w = int(76 * scale)
    p3_h = int(360 * scale)
    p3_x = cx + int(64 * scale)
    p3_y = baseline_y - p3_h
    draw_fg.rounded_rectangle([p3_x, p3_y, p3_x + p3_w, baseline_y], radius=p_radius, fill=(249, 115, 22, 255))

    # Dynamic Sweeping Growth Trendline
    # We define dense points along a cubic bezier or smooth parabolic curve for a continuous solid ribbon
    curve_points = []
    # From (cx - 180, cy + 90) through (cx - 10, cy - 20) to (cx + 175, cy - 145)
    p_start = (cx - int(180 * scale), cy + int(90 * scale))
    p_ctrl1 = (cx - int(60 * scale), cy + int(40 * scale))
    p_ctrl2 = (cx + int(60 * scale), cy - int(60 * scale))
    p_end   = (cx + int(175 * scale), cy - int(140 * scale))

    num_samples = 200
    for step in range(num_samples + 1):
        t = step / num_samples
        u = 1.0 - t
        # Cubic Bezier formulation
        x = (u**3 * p_start[0] +
             3 * u**2 * t * p_ctrl1[0] +
             3 * u * t**2 * p_ctrl2[0] +
             t**3 * p_end[0])
        y = (u**3 * p_start[1] +
             3 * u**2 * t * p_ctrl1[1] +
             3 * u * t**2 * p_ctrl2[1] +
             t**3 * p_end[1])
        curve_points.append((x, y))

    line_w = int(20 * scale)
    half_w = line_w // 2

    # Draw smooth trendline ribbon
    for i in range(len(curve_points) - 1):
        pt1 = curve_points[i]
        pt2 = curve_points[i + 1]
        draw_fg.line([pt1, pt2], fill=(255, 255, 255, 250), width=line_w)
        draw_fg.ellipse([pt1[0] - half_w, pt1[1] - half_w, pt1[0] + half_w, pt1[1] + half_w], fill=(255, 255, 255, 250))

    # Arrow Head at the peak of the curve
    arrow_tip = (cx + int(200 * scale), cy - int(160 * scale))
    arrow_wing1 = (arrow_tip[0] - int(48 * scale), arrow_tip[1] - int(6 * scale))
    arrow_wing2 = (arrow_tip[0] + int(6 * scale), arrow_tip[1] + int(48 * scale))
    draw_fg.polygon([arrow_tip, arrow_wing1, arrow_wing2], fill=(255, 255, 255, 255))

    # Sparkling Financial Node / Coin Badge at top-right
    spark_x = cx + int(120 * scale)
    spark_y = cy - int(180 * scale)
    outer_r = int(32 * scale)
    inner_r = int(14 * scale)

    # Subtle spark halo
    halo = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    draw_halo = ImageDraw.Draw(halo)
    draw_halo.ellipse(
        [spark_x - outer_r * 2, spark_y - outer_r * 2, spark_x + outer_r * 2, spark_y + outer_r * 2],
        fill=(249, 115, 22, 100)
    )
    halo = halo.filter(ImageFilter.GaussianBlur(int(15 * scale)))
    fg = Image.alpha_composite(fg, halo)
    draw_fg = ImageDraw.Draw(fg)

    # Golden / Orange Spark Coin
    draw_fg.ellipse(
        [spark_x - outer_r, spark_y - outer_r, spark_x + outer_r, spark_y + outer_r],
        fill=(255, 255, 255, 255),
        outline=(249, 115, 22, 255),
        width=int(7 * scale)
    )
    draw_fg.ellipse(
        [spark_x - inner_r, spark_y - inner_r, spark_x + inner_r, spark_y + inner_r],
        fill=(249, 115, 22, 255)
    )

    # -------------------------------------------------------------
    # 3. Downscale with Lanczos for Razor-Sharp Anti-Aliasing (1024x1024)
    # -------------------------------------------------------------
    final_bg = bg.resize((1024, 1024), Image.Resampling.LANCZOS)
    final_fg = fg.resize((1024, 1024), Image.Resampling.LANCZOS)
    final_bg.save('assets/icon/app_icon_background.png')
    final_fg.save('assets/icon/app_icon_foreground.png')

    # Composite full 1024x1024 app icon
    full_icon = Image.alpha_composite(final_bg, final_fg)
    full_icon.save('assets/icon/app_icon.png')

    # -------------------------------------------------------------
    # 4. Generate Master Splash Logo (Ultra High Res 1024x1024)
    # -------------------------------------------------------------
    # Crop around the card emblem from the 4096 canvas with padding
    crop_padding = int(50 * scale)
    splash_cropped = fg.crop((
        card_x0 - crop_padding,
        card_y0 - crop_padding,
        card_x1 + crop_padding,
        card_y1 + crop_padding + int(30 * scale)
    ))
    # Resize to high resolution master splash logo (1024x1024)
    splash_master = splash_cropped.resize((1024, 1024), Image.Resampling.LANCZOS)
    splash_master.save('assets/icon/splash_logo.png')

    print("Ultra-resolution assets (4096->1024 Lanczos) successfully generated!")

if __name__ == '__main__':
    create_super_resolution_assets()
