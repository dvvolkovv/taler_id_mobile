#!/usr/bin/env python3
"""Generate notification and CallKit icons from the main app icon silhouette."""

import os
import json
from PIL import Image, ImageFilter

PROJECT = os.path.dirname(os.path.abspath(__file__))
ANDROID_RES = os.path.join(PROJECT, 'android', 'app', 'src', 'main', 'res')
IOS_ASSETS = os.path.join(PROJECT, 'ios', 'Runner', 'Assets.xcassets')
SOURCE_ICON = os.path.join(PROJECT, 'app_icon_1024.png')

# Brightness threshold to separate star from black background
THRESHOLD = 40


def make_silhouette(size):
    """Extract the star shape from app_icon_1024.png as white silhouette on transparent bg.

    The source icon has a bright star on a black background (no alpha channel).
    We threshold by brightness to extract the star shape, then render it as
    white pixels with the brightness mapped to alpha.
    """
    src = Image.open(SOURCE_ICON).convert('RGBA')
    w, h = src.size

    # Add padding to make it square if needed, then crop to star area
    # Work at source resolution for quality
    pixels = src.load()

    # Create output at source resolution
    out = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    out_px = out.load()

    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            brightness = max(r, g, b)
            if brightness > THRESHOLD:
                # Map brightness to alpha, make pixel white
                alpha = min(255, int(brightness * 255 / 255))
                out_px[x, y] = (255, 255, 255, alpha)

    # Resize to target
    out = out.resize((size, size), Image.LANCZOS)
    return out


def make_notification_icons():
    """Generate Android notification icons for all densities."""
    densities = {
        'mdpi': 24, 'hdpi': 36, 'xhdpi': 48,
        'xxhdpi': 72, 'xxxhdpi': 96,
    }
    for density, px in densities.items():
        folder = os.path.join(ANDROID_RES, f'drawable-{density}')
        os.makedirs(folder, exist_ok=True)
        icon = make_silhouette(px)
        path = os.path.join(folder, 'ic_notification.png')
        icon.save(path, 'PNG')
        print(f'  Saved: {path} ({px}x{px})')


def make_callkit_icons():
    """Generate iOS CallKit icon set."""
    imageset_dir = os.path.join(IOS_ASSETS, 'CallKitLogo.imageset')
    os.makedirs(imageset_dir, exist_ok=True)

    scales = {
        'CallKitLogo.png': 40,
        'CallKitLogo@2x.png': 80,
        'CallKitLogo@3x.png': 120,
    }
    for filename, px in scales.items():
        icon = make_silhouette(px)
        path = os.path.join(imageset_dir, filename)
        icon.save(path, 'PNG')
        print(f'  Saved: {path} ({px}x{px})')

    contents = {
        "images": [
            {"idiom": "universal", "filename": "CallKitLogo.png", "scale": "1x"},
            {"idiom": "universal", "filename": "CallKitLogo@2x.png", "scale": "2x"},
            {"idiom": "universal", "filename": "CallKitLogo@3x.png", "scale": "3x"},
        ],
        "info": {"version": 1, "author": "xcode"},
        "properties": {"template-rendering-intent": "template"}
    }
    contents_path = os.path.join(imageset_dir, 'Contents.json')
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    print(f'  Saved: {contents_path}')


if __name__ == '__main__':
    print('=== TalerID Icon Generator ===\n')

    print('1. Generating Android notification icons (star silhouette)...')
    make_notification_icons()

    print('\n2. Generating iOS CallKit icons (star silhouette)...')
    make_callkit_icons()

    print('\n=== Done! ===')
