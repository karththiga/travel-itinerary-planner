# ExploreLanka mobile

Run `flutter pub get` from this directory after installing Flutter.

## Android

Start an Android emulator and run `flutter run`. The default debug API address is `http://10.0.2.2:3000`, which reaches a backend running on the development machine.

## iOS

Set up [Xcode and an iOS simulator runtime](https://docs.flutter.dev/platform-integration/ios/setup). Run `open -a Simulator`, use `flutter devices` to get the simulator ID, then run `flutter run -d <simulator-id>`. Start the backend on port 3000 for the default debug URL, `http://localhost:3000`.

For an iPhone, select a development team under Signing & Capabilities in Xcode and configure a bundle identifier available to that team. The project uses `com.example.explorelanka` for local development. Keep the Runner entitlements configured for Keychain access.

For a physical device or a different backend, use a reachable API URL with no trailing slash.

```sh
flutter run -d <device-id> --dart-define=API_BASE_URL=https://your-api.example.com
```

Profile and release authentication require an HTTPS URL.
