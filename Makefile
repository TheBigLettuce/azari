GIT_REV = $(shell git rev-parse --short HEAD)

release:
	flutter build apk --split-per-abi --no-tree-shake-icons
	git archive --format=tar.gz -o source.tar.gz HEAD 
	zip app_source_${GIT_REV} build/app/outputs/flutter-apk/app-arm64-v8a-release.apk source.tar.gz
	rm source.tar.gz
	adb push app_source_${GIT_REV}.zip /sdcard
	rm app_source_${GIT_REV}.zip
	