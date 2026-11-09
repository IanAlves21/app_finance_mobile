import os
from PIL import Image

def generate_high_quality_splash():
    src_logo = Image.open('assets/icon/splash_logo.png')

    # Precise density-based resolutions (160dp baseline):
    # mdpi: 160x160
    # hdpi: 240x240
    # xhdpi: 320x320
    # xxhdpi: 480x480
    # xxxhdpi: 640x640
    densities = {
        'mdpi': (160, 160),
        'hdpi': (240, 240),
        'xhdpi': (320, 320),
        'xxhdpi': (480, 480),
        'xxxhdpi': (640, 640),
    }

    # Generate in mipmap-* folders
    for density, (w, h) in densities.items():
        dir_path = f'android/app/src/main/res/mipmap-{density}'
        os.makedirs(dir_path, exist_ok=True)
        out_file = os.path.join(dir_path, 'splash_logo.png')
        resized = src_logo.resize((w, h), Image.Resampling.LANCZOS)
        resized.save(out_file, quality=100)
        print(f"Generated {out_file} ({w}x{h})")

    # Generate in drawable-* folders as well for complete fallback coverage
    for density, (w, h) in densities.items():
        dir_path = f'android/app/src/main/res/drawable-{density}'
        os.makedirs(dir_path, exist_ok=True)
        out_file = os.path.join(dir_path, 'splash_logo.png')
        resized = src_logo.resize((w, h), Image.Resampling.LANCZOS)
        resized.save(out_file, quality=100)
        print(f"Generated {out_file} ({w}x{h})")

    # Generate drawable-nodpi (exact 1:1, 512x512)
    os.makedirs('android/app/src/main/res/drawable-nodpi', exist_ok=True)
    nodpi_file = 'android/app/src/main/res/drawable-nodpi/splash_logo.png'
    src_logo.resize((512, 512), Image.Resampling.LANCZOS).save(nodpi_file, quality=100)
    print(f"Generated {nodpi_file} (512x512)")

    # Clean up any stale un-density-qualified drawable/splash_logo.png
    stale_drawable = 'android/app/src/main/res/drawable/splash_logo.png'
    if os.path.exists(stale_drawable):
        os.remove(stale_drawable)
        print(f"Removed stale {stale_drawable}")

    # iOS LaunchImage in LaunchImage.imageset
    ios_res = {
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png': (160, 160),
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png': (320, 320),
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png': (480, 480),
    }

    for path, (w, h) in ios_res.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        resized = src_logo.resize((w, h), Image.Resampling.LANCZOS)
        resized.save(path, quality=100)
        print(f"Generated iOS {path} ({w}x{h})")

if __name__ == '__main__':
    generate_high_quality_splash()
