# Sakhi Safety (Flutter prototype)

Women's safety app prototype: SOS with a cancel countdown, offline BLE relay, auto-detect,
and a safety heat map. All map data is synthetic (zones only, no names or addresses).

**Status: written without a compiler. Expect a few small compile errors on first run**
(mostly package API differences). Paste any error into Claude and it will be a quick fix.

## Setup (10 minutes)
1. Install Flutter (https://docs.flutter.dev/get-started/install) and Android Studio (for the SDK).
2. Create a shell project, then drop these files in:
   ```
   flutter create --org in.sakhi --project-name sakhi_safety sakhi_safety_app
   cd sakhi_safety_app
   ```
   Replace its `pubspec.yaml` and the whole `lib/` folder with the ones from this folder.
3. Add permissions to `android/app/src/main/AndroidManifest.xml`, inside `<manifest>` and above `<application>`:
   ```xml
   <uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation"/>
   <uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE"/>
   <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
   <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30"/>
   <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30"/>
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.VIBRATE"/>
   <uses-feature android:name="android.hardware.bluetooth_le" android:required="true"/>
   ```
   In `android/app/build.gradle` (or `build.gradle.kts`) set `minSdk = 23`.
   Also add inside `<manifest>` (for `tel:` links): `<queries><intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent></queries>`
4. Plug in an Android phone (USB debugging on) and run `flutter pub get && flutter run`.

## Demo script
- Home: hold SOS for 1 second, then the 10 second "Are you OK?" countdown, then delivery steps.
- Safety map: drag the time slider, tap zones, toggle CCTV, lights and police booths.
- Auto-detect: turn on "Network drops" and "Sudden impact" together to trigger the countdown.
  Real signals: shaking the phone hard triggers impact, and airplane mode triggers network loss.
- Offline relay on real hardware: install on 2 or 3 Android phones. Put phone A in airplane mode
  then turn Bluetooth back on, press SOS on A. Phone B (with internet) shows "Relayed distress packet".

## What is real vs stubbed
| Part | State |
|---|---|
| SOS countdown, delivery flow, map, signals | Working UI logic |
| BLE advertise and scan relay | Real code (`services/ble_mesh.dart`), needs testing on devices |
| Network-loss and impact detection | Real (connectivity_plus, sensors_plus) |
| Route deviation, long stop, missed check-in | Simulated toggles |
| Alerts to contacts, police console | `services/backend.dart` is a stub. The HTML prototype shows the police console |
| Heat map data | Synthetic, generated in `data/zones.dart` |

## Known limits to be upfront about
- Android only for BLE advertising. iOS limits background BLE a lot.
- BLE relay needs other app users within ~10-50 m. It is a supplement to SMS, not a replacement.
- Background operation needs an Android foreground service (not included).
- Silent SMS to contacts needs SEND_SMS permission and Play Store review. Prototype opens no SMS yet.
- 112 integration: no documented private-app route. The app only offers a "Call 112" button.
