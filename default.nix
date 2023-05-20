# this file is outdated, not expected to work...

{ pkgs ? import <nixpkgs> { config.android_sdk.accept_license = true; config.allowUnfree = true; } }:

let
  android-sdk = pkgs.androidenv.composeAndroidPackages {
    #accept_license = true;

    toolsVersion = "26.1.1";
    #platformToolsVersion = "31.0.0";
    buildToolsVersions = [ "30.0.3" ];
    platformVersions = [ "31" "32" ];
    abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
    #includeNDK = true;  
    #ndkVersions = [ "25.1.8937393" ];
  };

in
pkgs.mkShell {
  ANDROID_HOME = "${android-sdk.androidsdk}/libexec/android-sdk";
  ANDROID_SDK_ROOT = "${android-sdk.androidsdk}/libexec/android-sdk";
  JAVA_ROOT = "${pkgs.jdk11.home}";

  nativeBuildInputs = with pkgs; [
    # dependencies you want available in your shell
    #gcc
    #ffmpeg
    grpc-tools
    #protoc-gen-dart
    clang
    kotlin
    gtk3
    gtk3-x11
    android-sdk.androidsdk
    pkg-config
    cmake
    zip
    unzip
    ninja
    xz
    jdk11
    flutter
  ];
}
