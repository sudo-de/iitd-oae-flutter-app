# 📸 Screenshot Capture Guide

## How to Capture App Screenshots

### For Android
```bash
# Run the app
flutter run

# Take screenshots using ADB
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png assets/images/
```

### For iOS Simulator
```bash
# Run the app
flutter run

# Take screenshots using Simulator
# Press Cmd+S in the simulator to save screenshot
# Or use: xcrun simctl io booted screenshot assets/images/screenshot.png
```

### For Web
```bash
# Run the app
flutter run -d chrome

# Use browser dev tools or extensions to capture screenshots
```

## Required Screenshots

1. **login_screen.png** - Login/authentication screen
2. **student_dashboard.png** - Student's main dashboard
3. **book_ride.png** - Ride booking interface
4. **class_schedule.png** - Class schedule management
5. **driver_dashboard.png** - Driver's dashboard
6. **admin_panel.png** - Admin management panel

## Screenshot Guidelines

- **Resolution**: 1080x1920 (portrait) or 1920x1080 (landscape)
- **Format**: PNG with transparent background
- **Quality**: High resolution, clear text
- **Content**: Show key features and UI elements
- **Style**: Consistent with app's design theme

## Video Recording

### For Demo Video
1. Use screen recording software (OBS, QuickTime, etc.)
2. Record key user flows:
   - Login process
   - Booking a ride
   - Managing class schedule
   - Admin functions
3. Keep video under 2 minutes
4. Add captions/annotations
5. Upload to YouTube and update README link

### For GIFs
1. Use tools like ScreenToGif or LICEcap
2. Focus on interactive elements
3. Keep file size under 5MB
4. Show smooth animations

## File Naming Convention
- Use descriptive names: `feature_name_screen.png`
- Use lowercase with underscores
- Include screen size if multiple: `login_screen_mobile.png`, `login_screen_tablet.png`

## Optimization
- Compress images for web: Use tools like TinyPNG
- Maintain aspect ratios
- Test on different devices
- Ensure accessibility (good contrast, readable text) 