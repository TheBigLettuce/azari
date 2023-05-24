GIT_REV = $(shell git rev-parse --short HEAD)

.PHONY: release run linux-appimage mpv_compile
release:
	flutter build apk --split-per-abi --no-tree-shake-icons
	git archive --format=tar.gz -o source.tar.gz HEAD 
	zip app_source_${GIT_REV} build/app/outputs/flutter-apk/app-arm64-v8a-release.apk source.tar.gz
	rm source.tar.gz
	adb push app_source_${GIT_REV}.zip /sdcard
	rm app_source_${GIT_REV}.zip

linux-appimage: linuxdeploy-x86_64.AppImage
	mkdir -p AppDir && cd AppDir && rm -r -f *
	flutter build linux --release
	./linuxdeploy-x86_64.AppImage --appdir AppDir -e build/linux/x64/release/bundle/gallery -d azari.desktop -i linux/icon/icon.png 
	cp -r build/linux/x64/release/bundle/lib AppDir/usr/bin/lib
	cp -r build/linux/x64/release/bundle/data AppDir/usr/bin/data
	cp linux/icon/icon.png AppDir/usr/bin/icon.png
	./linuxdeploy-x86_64.AppImage --appdir AppDir --output appimage

app:
	flutter build linux --release
	mkdir -p app
	cp -r build/linux/x64/release/bundle/* app

linuxdeploy-x86_64.AppImage:
	wget -O linuxdeploy-x86_64.AppImage https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20220822-1/linuxdeploy-x86_64.AppImage
	chmod +x linuxdeploy-x86_64.AppImage

run: app
	./app/gallery