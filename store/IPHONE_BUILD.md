# Testing PulsIQ on your iPhone

Two paths. Web is instant and needs nothing from you; native gives you
HealthKit, the real camera, and on-device speech but requires a full Xcode
install and your Apple ID.

## A. Right now — open it in iPhone Safari (no build)

The dev machine serves a release web build on the LAN. On your iPhone,
**connected to the same Wi-Fi**, open:

```
http://192.168.86.38:8087
```

(That IP is this Mac's current LAN address — re-check with
`ipconfig getifaddr en0` if the network changes.)

What works in Safari: the whole UI, **Snap-a-meal via the photo picker**
(tap "Pick from gallery" or use the camera — iOS Safari supports both through
the file input), manual + voice-style logging, the nutrition analytics, the
cut-down advice, Order Hack, and (via Settings → Demo biometrics) the Pulse
card and score. What doesn't: HealthKit and on-device speech-to-text — those
are native-only. The meal-vision model runs through the backend proxy once
its URL is set; until then the on-device estimate uses your text hint.

Add it to your Home Screen (Share → Add to Home Screen) for a full-screen,
app-like shell.

## B. Native app on your iPhone (HealthKit + camera + STT)

This needs three things only you can provide:

1. **Full Xcode** — install from the Mac App Store (several GB; uses your
   Apple ID), then:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```
2. **CocoaPods**:
   ```bash
   sudo gem install cocoapods
   ```
3. **An Apple ID for signing.** A free Apple ID works for a 7-day on-device
   install; a paid Apple Developer account ($99/yr) is needed for TestFlight.

Once those exist, from `pulsiq/`:

```bash
flutter pub get
cd ios && pod install && cd ..

# Plug in your iPhone, trust the Mac, then:
flutter devices                 # confirm the iPhone is listed
open ios/Runner.xcworkspace     # set your Team under Signing & Capabilities
flutter run --release           # installs to the connected device
```

For a shareable build:

```bash
flutter build ipa               # produces build/ios/ipa/pulsiq.ipa
# Upload to App Store Connect → TestFlight (needs the paid account)
```

Point the app at the real LLM/vision backend with
`--dart-define=PULSIQ_PROXY_URL=https://<your-supabase-proxy>` on any
`flutter run`/`flutter build` command.

I can run steps once Xcode + CocoaPods are installed and your iPhone is
connected — I just can't install Xcode under your Apple ID or handle signing
credentials for you.
