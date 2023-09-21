# Azari

A *booru client app, built Dart/Flutter.

## Building

To build this at all you need to have this installed on your computer:
- Android Studio Flamingo (by default Flutter uses Android Studio supplied Java version, if you don't have Android Studio then it will use your system's Java),
- Flutter,
- Android SDK.

The Flutter tool will do its best to download the right Android SDK packages for you when you start the build, you just need to be sure that the Android SDK is in your `path`.

To run the app in the debug mode, attach the device with ADB debugging enabled and just run `flutter run`.

To build the release version, you have to first generate a signing key.
You can use Android Studio to do this, refer to [here](https://developer.android.com/studio/publish/app-signing#generate-key).
Or you can generate it from the terminal, like this (the keytool is part of the Android SDK):
- `keytool -genkey -v -keystore *output path of the keystore.jks* -storepass *password of the store* -alias *key alias* -keypass *key password* -keyalg RSA -keysize 2048 -validity 10000`
Then you you need to create a file in `android/` directory, named `key.properties` and put this into it:
- storePassword=*store password*
- keyPassword=*key password*
- keyAlias=*key alias*
- storeFile=*path to the store*

After this the app should build fine. Use the `flutter build apk --split-per-abi --no-tree-shake-icons` command.

## Regenerating generated code

You have to regenerate code before building, or working on it at all. Run `make regenerate` .