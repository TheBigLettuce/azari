import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
    dartOut: 'lib/src/gallery.g.dart',
    dartTestOut: 'test/test_api.dart',
    kotlinOut: 'android/app/src/main/kotlin/lol/bruh19/azari/gallery/Api.kt',
    kotlinOptions: KotlinOptions(package: 'lol.bruh19.azari.gallery')))
@FlutterApi()
abstract class GalleryApi {
  Result add(String bucketId, String albumName, String path, List<int> thumb);
}

class Result {
  bool? ok;
  String? message;
}
