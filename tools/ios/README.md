# iOS build notes

## Always install a Release build, never Debug

A Debug Flutter build installed with `devicectl` launches and then dies with
signal 11:

```
Cannot create a FlutterEngine instance in debug mode without Flutter tooling
or Xcode.
```

iOS 14+ refuses to start a Flutter debug engine outside `flutter run` / Xcode.
On the phone this looks exactly like an app crash — it opens and closes
instantly — but nothing is wrong with the code. Build Release:

```bash
flutter build ios --release
```

Then install and confirm it stays alive:

```bash
xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app
```

## `build/` must live outside iCloud Drive

The repo sits under `~/Documents`, which is synced by iCloud Drive. The sync
client stamps `com.apple.FinderInfo` and `com.apple.fileprovider.fpfs#P`
extended attributes onto directories it touches, including Flutter's build
output. Codesigning then fails:

```
Failed to codesign build/ios/Release-iphoneos/Flutter.framework/Flutter
  with identity -.
... resource fork, Finder information, or similar detritus not allowed
```

Flutter tries to strip these itself (`xattr -r -d com.apple.FinderInfo`), but
the attributes land on the framework *directory*, not the binary, and the sync
client re-applies them on the next copy — so a clean build fails every time.
`com.apple.provenance` is system-protected and cannot be deleted at all.

The fix is to keep build output off the synced volume entirely:

```bash
rm -rf build
mkdir -p ~/.pulsiq-build/build
ln -s ~/.pulsiq-build/build build
```

`build` is therefore a symlink on this machine and is gitignored (both `/build`
and `/build/`). Recreate it with the commands above on a fresh clone if you hit
the codesign error.

## `flutter build ios` reporting status code 255

Flutter's wrapper has historically reported a bogus `Uncategorized (Xcode):
Exited with status code 255` on success. Before assuming it's false, check the
real error:

```bash
flutter build ios --release --verbose > /tmp/build.log 2>&1
grep -n "Target .* failed\|Failed to codesign\|Failed to package" /tmp/build.log
```

If a target genuinely failed, that grep shows it. Falling back to a direct
`xcodebuild` run can report `** BUILD SUCCEEDED **` while producing an
**incomplete** `Runner.app` — no `Info.plist`, no executable, empty
`Frameworks/` — which then fails to install with:

```
The item at Runner.app is not a valid bundle. ... Ensure that your bundle's
Info.plist contains a value for the CFBundleIdentifier key.
```

Always sanity-check the product before installing:

```bash
plutil -p build/ios/iphoneos/Runner.app/Info.plist | grep CFBundleIdentifier
ls build/ios/iphoneos/Runner.app/Runner
ls build/ios/iphoneos/Runner.app/Frameworks
```
