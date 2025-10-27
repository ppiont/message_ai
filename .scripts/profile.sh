#!/bin/bash
# Flutter Performance Profiling Helper Script

set -e

echo "🔍 Flutter Performance Profiling Tool"
echo "======================================"
echo ""

# Check if app is running
if ! flutter devices | grep -q "sdk gphone64 arm64"; then
    echo "❌ No Android emulator detected. Starting emulator..."
    flutter emulators --launch Pixel_8_API_35
    sleep 10
fi

echo "📱 Available commands:"
echo ""
echo "1. Launch app in PROFILE mode (recommended for performance testing)"
echo "   flutter run --profile"
echo ""
echo "2. Launch app in DEBUG mode with DevTools"
echo "   flutter run --observatory-port=9999"
echo "   (Then open: http://localhost:9999)"
echo ""
echo "3. Launch DevTools manually"
echo "   flutter pub global activate devtools"
echo "   flutter pub global run devtools"
echo ""
echo "4. Enable performance overlay in running app"
echo "   Press 'P' in the terminal while app is running"
echo ""
echo "5. Take timeline trace"
echo "   flutter run --trace-startup --profile"
echo ""
echo "6. Analyze build times"
echo "   flutter build apk --analyze-size"
echo ""

read -p "Choose command to run (1-6): " choice

case $choice in
    1)
        echo "🚀 Launching in PROFILE mode..."
        flutter run --profile
        ;;
    2)
        echo "🚀 Launching in DEBUG mode with DevTools..."
        flutter run --observatory-port=9999
        ;;
    3)
        echo "🚀 Launching DevTools..."
        flutter pub global activate devtools
        flutter pub global run devtools
        ;;
    4)
        echo "ℹ️  Press 'P' in your running Flutter app terminal to toggle performance overlay"
        ;;
    5)
        echo "🚀 Taking startup timeline trace..."
        flutter run --trace-startup --profile
        ;;
    6)
        echo "📊 Analyzing build size..."
        flutter build apk --analyze-size
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac
