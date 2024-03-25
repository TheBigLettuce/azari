GIT_REV = $(shell git rev-parse --short HEAD)

.PHONY: release android_install regenerate generate_dbus
release:
	flutter build apk --split-per-abi --no-tree-shake-icons
	git archive --format=tar.gz -o source.tar.gz HEAD
	zip app_source_${GIT_REV} build/app/outputs/flutter-apk/app-arm64-v8a-release.apk source.tar.gz
	rm source.tar.gz
	adb push app_source_${GIT_REV}.zip /sdcard
	rm app_source_${GIT_REV}.zip

android_install:
	flutter build apk --split-per-abi --no-tree-shake-icons
	adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

regenerate:
	flutter gen-l10n
	mkdir -p test
	flutter pub run pigeon --input pigeons/gallery.dart
	dart run build_runner build

generate_dbus:
	dart-dbus generate-remote-object /usr/share/dbus-1/interfaces/kf5_org.kde.JobViewServer.xml -o lib/dbus/job_view_server.g.dart
	dart-dbus generate-remote-object /usr/share/dbus-1/interfaces/kf5_org.kde.JobView.xml -o lib/dbus/job_view.g.dart
