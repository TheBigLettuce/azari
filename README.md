# Azari

A *booru client app, built Dart/Flutter.

## Building for Android

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

## Building for GNU/Linux

All the build requirements are listed on [this](https://docs.flutter.dev/get-started/install/linux) page. 
Together with the build requirements above, needs `libmpv` to build and run. `video_player` does not work on GNU/Linux yet, so it uses `media_kit` for video playback, it depends on mpv.
You must have to install the `libmpv` on your system before building this app. If you wont do so, the .AppImage will work incorrectly. 

To run this in the debug mode, just run `flutter run`. Don't forget to deattach the Android device.

To build this as .AppImage, run `make linux-appimage` . You should then get Azari-*git ref*-x86_64.AppImage.
When you build this app as an .AppImage, then your system's `libmpv` will be automatically included inside. 
You can build the release version, and then run it, without building .AppImage with `make run` . Delete `app/` folder when you want to rebuild it.  
To just build the release version, run `make app` .

## Regenerating generated code

You have to regenerate code before building, or working on it at all. Run `make regenerate` . Be wary that `dart-dbus` can output invalid Dart code, but it is a simple mistake. You would need then to fix it by hand.
