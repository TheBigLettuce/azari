package lol.bruh19.azari.gallery

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import androidx.annotation.NonNull
import io.flutter.plugin.common.MethodChannel
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMethodCodec

class MainActivity : FlutterActivity() {
    private val CHANNEL = "org.gallery"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL, StandardMethodCodec.INSTANCE, flutterEngine.dartExecutor.binaryMessenger.makeBackgroundTaskQueue()).setMethodCallHandler { call, result ->
            when (call.method) {
                else -> result.notImplemented()
            }
        }
    }


}


/*private fun populateAlbums(context: Context) {

}

private fun getAlbums(context: Context, binaryMessenger: BinaryMessenger): List<Album> {
    val projection = arrayOf(
            MediaStore.Images.Media.BUCKET_ID,
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME,
            MediaStore.Images.Media._ID,
            //MediaStore.Images.Media.ALBUM,
            MediaStore.Images.Media.DISPLAY_NAME
    )

    var galleryApi = GalleryApi(binaryMessenger)

    context.contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection,
            null,
            null,
            null,
    )?.use { cursor ->
        val bucketIdCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_ID)
        val bucketNameCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_DISPLAY_NAME)
        val id = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
        val displayName = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)


        while (cursor.moveToNext()) {
            val id = cursor.getLong(bucketIdCol)
            val displayName: String = cursor.getString(bucketNameCol)

            galleryApi.add(cursor.getLong())
        }
    }

    return albums
}*/

/*private fun getFiles(context: Context, albumId: Long): List<File> {
    val projection = arrayOf(
            MediaStore.Images.Media._ID,
            //MediaStore.Images.Media.ALBUM,
            MediaStore.Images.Media.DISPLAY_NAME
    )

    val selection = "${MediaStore.Images.Media.BUCKET_ID} = ?"

    val selectionArgs = arrayOf(albumId.toString())

    val files = mutableListOf<File>()

    context.contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            "${MediaStore.Video.Media.DISPLAY_NAME} ASC"
    )?.use { cursor ->
        val idCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
        val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)

        while (cursor.moveToNext()) {
            val id = cursor.getLong(idCol)
            val name: String = cursor.getString(nameCol)

            files.add(File(id = id, name = name))
            //files.add(File(id = id, name = name))
        }

    }

    return files
}*/

