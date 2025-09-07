# Rakshak App Icon Update Guide

## Overview
This guide explains how to update the app icons for the Rakshak application across all platforms.

## New Logo Design
The new Rakshak logo features:
- **Background**: Orange-red gradient circle (#FF6B35 to #E55A2B)
- **Icon**: White shield with orange-red location pin inside
- **Text**: "Rakshak" in white, bold font
- **Style**: Modern, clean design with rounded corners

## Required Icon Sizes

### Android Icons
Replace the following files in `android/app/src/main/res/`:
- `mipmap-mdpi/ic_launcher.png` (48x48)
- `mipmap-hdpi/ic_launcher.png` (72x72)
- `mipmap-xhdpi/ic_launcher.png` (96x96)
- `mipmap-xxhdpi/ic_launcher.png` (144x144)
- `mipmap-xxxhdpi/ic_launcher.png` (192x192)

### iOS Icons
Replace the following files in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`:
- `Icon-App-20x20@1x.png` (20x20)
- `Icon-App-20x20@2x.png` (40x40)
- `Icon-App-20x20@3x.png` (60x60)
- `Icon-App-29x29@1x.png` (29x29)
- `Icon-App-29x29@2x.png` (58x58)
- `Icon-App-29x29@3x.png` (87x87)
- `Icon-App-40x40@2x.png` (80x80)
- `Icon-App-40x40@3x.png` (120x120)
- `Icon-App-60x60@2x.png` (120x120)
- `Icon-App-60x60@3x.png` (180x180)
- `Icon-App-76x76@1x.png` (76x76)
- `Icon-App-76x76@2x.png` (152x152)
- `Icon-App-83.5x83.5@2x.png` (167x167)
- `Icon-App-1024x1024@1x.png` (1024x1024)

### Web Icons
Replace the following files in `web/icons/`:
- `Icon-192.png` (192x192)
- `Icon-512.png` (512x512)
- `Icon-maskable-192.png` (192x192)
- `Icon-maskable-512.png` (512x512)

### macOS Icons
Replace the following files in `macos/Runner/Assets.xcassets/AppIcon.appiconset/`:
- `app_icon_16.png` (16x16)
- `app_icon_32.png` (32x32)
- `app_icon_64.png` (64x64)
- `app_icon_128.png` (128x128)
- `app_icon_256.png` (256x256)
- `app_icon_512.png` (512x512)
- `app_icon_1024.png` (1024x1024)

## Design Specifications

### Colors
- **Primary Orange-Red**: #FF6B35
- **Secondary Orange-Red**: #E55A2B
- **White**: #FFFFFF
- **Light Gray**: #E0E0E0

### Logo Elements
1. **Background Circle**: Orange-red gradient with subtle border
2. **Shield Shape**: White shield with rounded corners
3. **Location Pin**: Orange-red location pin icon inside shield
4. **App Name**: "Rakshak" in white, bold, sans-serif font

### Design Guidelines
- Maintain consistent proportions across all sizes
- Ensure good contrast for visibility
- Use high-quality, crisp images
- Follow platform-specific design guidelines

## Tools for Icon Generation
- **Online Tools**: App Icon Generator, Icon Kitchen
- **Design Software**: Figma, Adobe Illustrator, Sketch
- **Flutter Tools**: flutter_launcher_icons package

## Implementation Status
✅ Splash screen logo updated with new design
✅ "Powered by IMBLV services pvt ltd" branding added
⏳ App icons need to be manually replaced with new design
⏳ All platform-specific icon files need updating

## Next Steps
1. Create the new icon design using design software
2. Generate all required sizes for each platform
3. Replace the existing icon files
4. Test the app on all platforms to ensure icons display correctly

