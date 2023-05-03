updategolib:
	cd go/api && gomobile bind -androidapi 19 .
	mv go/api/api.aar android/libs/api.aar
	mv go/api/api-sources.jar android/libs/api-sources.jar