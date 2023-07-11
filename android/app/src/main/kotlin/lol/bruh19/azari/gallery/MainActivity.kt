// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery

import android.app.Activity
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.StrictMode
import android.provider.MediaStore
import android.util.Log
import android.util.Size
import android.util.TypedValue
import android.view.ContextThemeWrapper
import android.view.View
import android.webkit.MimeTypeMap
import androidx.annotation.NonNull
import androidx.documentfile.provider.DocumentFile
import androidx.lifecycle.lifecycleScope
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.common.StandardMethodCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import okio.FileSystem
import okio.Path.Companion.toPath
import okio.buffer
import okio.sink
import okio.use
import pl.droidsonroids.gif.GifDrawable
import pl.droidsonroids.gif.GifImageView
import java.io.ByteArrayOutputStream
import java.util.Calendar
import kotlin.coroutines.CoroutineContext
import kotlin.io.path.Path
import kotlin.io.path.deleteIfExists
import kotlin.io.path.extension

class MainActivity : FlutterActivity() {
    private val CHANNEL = "lol.bruh19.azari.gallery"
    private lateinit var mover: Mover
    private var callback: ((String) -> Unit)? = null

    //    private val deleteMutex = Mutex()
//    private var deleteItems: List<Uri>? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        var appFlags = context.applicationInfo.flags
        if ((appFlags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            StrictMode.setThreadPolicy(
                StrictMode.ThreadPolicy.Builder().detectAll().build()
            )
            StrictMode.setVmPolicy(
                StrictMode.VmPolicy.Builder().detectAll().build()
            )
        }

        super.onCreate(savedInstanceState)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1 && resultCode == Activity.RESULT_OK) {
            callback?.invoke(data!!.data.toString())
            callback = null
        }

        if (requestCode == 9 && resultCode == Activity.RESULT_OK) {
            mover.notifyGallery()
        } else {
            Log.e("delete files", "failed")
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        mover = Mover(
            lifecycleScope.coroutineContext,
            context,
            GalleryApi(flutterEngine.dartExecutor.binaryMessenger)
        )

        flutterEngine.platformViewsController.registry.registerViewFactory(
            "imageview",
            NativeViewFactory()
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
            StandardMethodCodec.INSTANCE,
            flutterEngine.dartExecutor.binaryMessenger.makeBackgroundTaskQueue()
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "move" -> {
                    val map = call.arguments as HashMap<String, String>
                    val source = map["source"]
                    val rootUri = map["rootUri"]
                    val dir = map["dir"]
                    if (source == null) {
                        result.error("source is empty", null, null)
                    } else if (rootUri == null) {
                        result.error("dest is empty", null, null)
                    } else if (dir == null) {
                        result.error("directory is empty", null, null)
                    } else {
                        mover.add(MoveOp(source, Uri.parse(rootUri), dir))
                        result.success(null)
                    }
                }

                "chooseDirectory" -> {
                    startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE), 1)
                    callback = {
                        contentResolver.takePersistableUriPermission(
                            Uri.parse(it),
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                        )

                        result.success(it)
                    }
                }

                "loadThumbnails" -> {
                    val list = call.arguments as List<Long>
                    if (list.isEmpty()) {
                        result.success(null)
                    } else {
                        mover.thumbnailsCallback(list) {
                            result.success(null)
                        }
                    }
                }

                "requestManageMedia" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            if (!MediaStore.canManageMedia(context)) {
                                val intent =
                                    Intent(android.provider.Settings.ACTION_REQUEST_MANAGE_MEDIA)
                                intent.data = Uri.parse("package:${context.packageName}")
                                context.startActivity(intent)
                            }
                        }
                    } catch (e: Exception) {
                        Log.e("requestManageMedia", e.toString())
                    }
                    result.success(null)
                }

                "deleteFiles" -> {
                    try {
                        val deleteItems = (call.arguments as List<String>).map { Uri.parse(it) }
                        val status =
                            MediaStore.createDeleteRequest(
                                context.contentResolver,
                                deleteItems
                            )

                        this.startIntentSenderForResult(status.intentSender, 9, null, 0, 0, 0)
                    } catch (e: java.lang.Exception) {
                        Log.e("deleteFiles", e.toString())
                    }

                }

//                "copyFromMediaStore" -> {
//                    val map = call.arguments as HashMap<String, String>
//                    val from = map["from"]
//                    val to = map["to"]
//                    if (to == null) {
//                        result.error("to is empty", null, null)
//                    } else if (from == null) {
//                        result.error("from is empty", null, null)
//                    } else {
//                        mover.copyMediastoreTo(to, from, result)
//                    }
//                }

//                "copyFromMediaStore" -> {
//                    val map = call.arguments as HashMap<String, String>
//                    val from = map["from"]
//                    val to = map["to"]
//                    if (to == null) {
//                        result.error("to is empty", null, null)
//                    } else if (from == null) {
//                        result.error("from is empty", null, null)
//                    } else {
//                        mover.copyMediastoreTo(to, from, result)
//                    }
//                }

                "refreshFiles" -> {
                    runOnUiThread {
                        mover.refreshFiles(call.arguments as String)
                    }

                    result.success(null)
                }

                "refreshGallery" -> {
                    runOnUiThread {
                        mover.refreshGallery()
                    }

                    result.success(null)
                }

                "accentColor" -> {
                    try {
                        var value = TypedValue()
                        ContextThemeWrapper(
                            this,
                            android.R.style.Theme_DeviceDefault
                        ).theme.resolveAttribute(android.R.attr.colorAccent, value, true)


                        result.success(value.data)
                    } catch (_: Exception) {
                        result.success(0xFF448AFF)
                    }

                }

                else -> result.notImplemented()
            }
        }
    }
}

data class MoveOp(val source: String, val rootUri: Uri, val dir: String)
data class ThumbOp(val thumbs: List<Long>, val callback: (() -> Unit)?)
class Mover(
    private val coContext: CoroutineContext,
    private val context: Context,
    private val galleryApi: GalleryApi
) {
    private val channel = Channel<MoveOp>()
    private val thumbnailsChannel = Channel<ThumbOp>(capacity = 2)
    private val scope = CoroutineScope(coContext + Dispatchers.IO)

    private val isLockedDirMux = Mutex()
    private val isLockedFilesMux = Mutex()
//    private val copyFileLock = Mutex()

    init {
        scope.launch {
            for (uris in thumbnailsChannel) {
                val newScope = CoroutineScope(Dispatchers.IO)

                try {
                    for (u in uris.thumbs.chunked(8)) {
                        newScope.launch(SupervisorJob()) {
                            val thumbs = mutableListOf<ThumbnailId>()
                            val mutex = Mutex()
                            val jobs = mutableListOf<Job>()

                            u.forEach {
                                val copy = it

                                jobs.add(launch {
                                    var res: ByteArray
                                    try {
                                        val uri = ContentUris.withAppendedId(
                                            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
                                            it
                                        )

                                        res = getThumb(uri)


                                    } catch (e: Exception) {
                                        res = transparentImage
                                        Log.e("thumbnail coro", e.toString())
                                    }

                                    mutex.lock()
                                    thumbs.add(ThumbnailId(it, res))
                                    mutex.unlock()
                                })
                            }

                            jobs.forEach {
                                it.join()
                            }

                            Handler(Looper.getMainLooper()).post {
                                galleryApi.addThumbnails(
                                    thumbs
                                ) {}
                            }
                        }.join()
                    }

                    uris.callback?.invoke()
                } catch (e: java.lang.Exception) {
                    Log.e("thumbnails", e.toString())
                }
            }
        }

        scope.launch {
            for (op in channel) {
                launch {
                    try {
                        val ext = Path(op.source).extension

                        val mimeType =
                            MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext.lowercase())
                                ?: throw Exception("could not find mimetype")

                        val docFile = DocumentFile.fromTreeUri(context, op.rootUri)!!

                        if (!docFile.exists()) throw Exception("root uri does not exist")

                        if (!docFile.canWrite()) throw Exception("cannot write to the root uri")

                        var dir = docFile.findFile(op.dir)
                        if (dir == null) {
                            dir = docFile.createDirectory(op.dir)
                                ?: throw Exception("could not create a directory for a file")
                        } else if (!dir.isDirectory) throw Exception("needs to be directory: ${op.dir}")

                        val docDest =
                            dir.createFile(mimeType, Path(op.source).fileName!!.toString())
                                ?: throw Exception("could not create the destination file")


                        val docStream = context.contentResolver.openOutputStream(docDest.uri, "w")
                            ?: throw Exception("could not get an output stream")
                        val fileSrc = FileSystem.SYSTEM.openReadOnly(op.source.toPath())


                        val buffer = docStream.sink().buffer()
                        val src = fileSrc.source()
                        buffer.writeAll(src)
                        buffer.flush()
                        docStream.flush()

                        src.close()
                        buffer.close()
                        fileSrc.close()
                        docStream.close()
                    } catch (e: Exception) {
                        Log.e("downloader", e.toString())
                    }

                    CoroutineScope(Dispatchers.Main).launch {
                        galleryApi.notify { }
                    }

                    Path(op.source).deleteIfExists()
                }
            }
        }
    }

    fun thumbnailsCallback(thumbs: List<Long>, callback: () -> Unit) {
        scope.launch {
            thumbnailsChannel.send(ThumbOp(thumbs, callback))
        }
    }

    fun notifyGallery() {
        galleryApi.notify {

        }
    }

//    fun deleteFiles(files: List<Uri>) {
//        scope.launch {
//            try {
//                context.contentResolver.delete()
//                MediaStore.createDeleteRequest()
//            } catch (e: java.lang.Exception) {
//
//            }
//        }
//    }

//    fun moveMediastoreTo(to: String, from: String, result: MethodChannel.Result) {
//        scope.launch {
//            val uri = Uri.parse(from)
//            if (uri.lastPathSegment == null) {
//                result.error("from is invalid", null, null)
//                return@launch
//            }
//
//            val filePath = to.toPath().resolve(uri.lastPathSegment!!)
//            try {
//                if (FileSystem.SYSTEM.exists(filePath)) {
//                    result.success(filePath.toString())
//                    return@launch
//                }
//
//                context.contentResolver.openInputStream(Uri.parse(from))?.use { stream ->
//                    java.nio.file.Files.copy(stream, filePath.toNioPath())
//
////                    FileSystem.SYSTEM.openReadWrite(
////                        filePath
////                    ).use { handle ->
////                        val buf = handle.sink().buffer()
////                        val source = stream.source()
////
////                        try {
////                            buf.writeAll(source)
////                            buf.flush()
////                            handle.flush()
////
////                            buf.close()
////                            source.close()
////                        } catch (e: Exception) {
////                            buf.close()
////                            source.close()
////                            throw e
////                        }
////                    }
//
//                }
//            } catch (e: Exception) {
//                result.error(e.toString(), null, null)
//                return@launch
//            }
//
//            result.success(filePath.toString())
//        }
//    }

    fun refreshFiles(dirId: String) {
        if (isLockedFilesMux.isLocked) {
            return
        }

        val time = Calendar.getInstance().time.time

        scope.launch {
            if (!isLockedFilesMux.tryLock()) {
                return@launch
            }

            refreshDirectoryFiles(dirId, context, time)

            isLockedFilesMux.unlock()
        }
    }

    fun refreshGallery() {
        if (isLockedDirMux.isLocked) {
            return
        }

        scope.launch {
            if (!isLockedDirMux.tryLock()) {
                return@launch
            }

            refreshMediastore(context)

            isLockedDirMux.unlock()
        }
    }

    private suspend fun refreshDirectoryFiles(dir: String, context: Context, time: Long) {
        val projection = arrayOf(
            MediaStore.Files.FileColumns.BUCKET_ID,
            MediaStore.Files.FileColumns.DISPLAY_NAME,
            MediaStore.Files.FileColumns.DATE_MODIFIED,
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.MEDIA_TYPE,
            MediaStore.Files.FileColumns.MIME_TYPE,
            MediaStore.Files.FileColumns.HEIGHT,
            MediaStore.Files.FileColumns.WIDTH
        )

        context.contentResolver.query(
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
            projection,
            "(${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} OR ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}) AND ${MediaStore.Files.FileColumns.BUCKET_ID} = ? AND ${MediaStore.Files.FileColumns.MIME_TYPE} != ?",
            arrayOf(dir, "image/vnd.djvu"),
            "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC"
        )?.use { cursor ->
            val id = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
            val bucket_id = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.BUCKET_ID)
            val b_display_name =
                cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
            val date_modified =
                cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_MODIFIED)
            val media_type = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MEDIA_TYPE)

            val media_height = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.HEIGHT)
            val media_width = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.WIDTH)
            val media_mime = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MIME_TYPE)

            if (!cursor.moveToFirst()) {
                CoroutineScope(Dispatchers.Main).launch {
                    galleryApi.updatePictures(
                        listOf(),
                        dir,
                        time,
                        inRefreshArg = false,
                        emptyArg = true
                    ) {}
                }.join()
                return@use
            }

            try {
                val list = mutableListOf<DirectoryFile>()

                do {
                    val uri =
                        if (cursor.getInt(media_type) == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO) {
                            ContentUris.withAppendedId(
                                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                                cursor.getLong(id)
                            )
                        } else {
                            ContentUris.withAppendedId(
                                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                                cursor.getLong(id)
                            )
                        }

                    val idval = cursor.getLong(id)
                    val lastmodifval = cursor.getLong(date_modified)
                    val nameval = cursor.getString(b_display_name)
                    val directoryidval = cursor.getString(bucket_id)
                    val heightval = cursor.getLong(media_height)
                    val widthval = cursor.getLong(media_width)

                    list.add(
                        DirectoryFile(
                            id = idval,
                            bucketId = directoryidval,
                            name = nameval,
                            originalUri = uri.toString(),
                            lastModified = lastmodifval,
                            isVideo = cursor.getInt(media_type) == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO,
                            isGif = cursor.getString(media_mime) == "image/gif",
                            height = heightval,
                            width = widthval
                        )
                    )

                    if (list.count() == 40) {
                        val copy = list.toList()
                        list.clear()
                        //filterAndSendThumbs(copy.map { it.id })

                        CoroutineScope(Dispatchers.Main).launch {
                            galleryApi.updatePictures(
                                copy,
                                dir,
                                time,
                                inRefreshArg = !cursor.isLast,
                                emptyArg = false
                            ) {}
                        }.join()
                    }
                } while (
                    cursor.moveToNext()
                )

                if (list.isNotEmpty()) {
                    //filterAndSendThumbs(list.map { it.id })

                    CoroutineScope(Dispatchers.Main).launch {
                        galleryApi.updatePictures(
                            list,
                            dir,
                            time,
                            inRefreshArg = false,
                            emptyArg = false
                        ) {}
                    }.join()
                }
            } catch (e: java.lang.Exception) {
                Log.e("refreshDirectoryFiles", "cursor block fail", e)
            }
        }
    }

    private fun getThumb(uri: Uri): ByteArray {
        val thumb = context.contentResolver.loadThumbnail(uri, Size(320, 320), null)
        val stream = ByteArrayOutputStream()

        thumb.compress(Bitmap.CompressFormat.JPEG, 80, stream)

        val bytes = stream.toByteArray()

        stream.reset()
        thumb.recycle()

        return bytes
    }

    private suspend fun refreshMediastore(context: Context) {
        val projection = arrayOf(
            MediaStore.Files.FileColumns.BUCKET_ID,
            MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME,
            MediaStore.Files.FileColumns.DATE_MODIFIED,
            MediaStore.Files.FileColumns._ID
        )

        context.contentResolver.query(
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
            projection,
            "(${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} OR ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}) AND ${MediaStore.Files.FileColumns.MIME_TYPE} != ?",
            arrayOf("image/vnd.djvu"),
            "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC"
        )?.use { cursor ->
            val id = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
            val bucket_id = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.BUCKET_ID)
            val b_display_name =
                cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME)
            val date_modified =
                cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_MODIFIED)

            val map = HashMap<String, Unit>()
            val list = mutableListOf<Directory>()

            if (!cursor.moveToFirst()) {
                return@use
            }

            try {
                do {
                    val bucketId = cursor.getString(bucket_id)
                    if (bucketId == null || map.containsKey(bucketId)) {
                        continue
                    }

                    map[bucketId] = Unit

                    val idval = cursor.getLong(id)
                    val lastmodifval = cursor.getLong(date_modified)
                    val nameval = cursor.getString(b_display_name) ?: "Internal"

                    list.add(
                        Directory(
                            thumbFileId = idval,
                            lastModified = lastmodifval,
                            bucketId = bucketId,
                            name = nameval
                        )
                    )

                    if (list.count() == 40) {
                        val copy = list.toList()
                        list.clear()

                        CoroutineScope(Dispatchers.Main).launch {
                            galleryApi.updateDirectories(
                                copy,
                                !cursor.isLast
                            ) {}
                        }.join()
                    }
                } while (
                    cursor.moveToNext()
                )

                //map.values.
                if (list.isNotEmpty()) {
                    CoroutineScope(Dispatchers.Main).launch {
                        galleryApi.updateDirectories(
                            list,
                            false
                        ) {}
                    }.join()
                }
            } catch (e: java.lang.Exception) {
                Log.e("refreshMediastore", "cursor block fail", e)
            }
        }

        val version = MediaStore.getVersion(
            context,
            MediaStore.getVolumeName(MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
        )

        Handler(Looper.getMainLooper()).post {
            galleryApi.finish(
                version
            ) {}
        }
    }

    private fun filterAndSendThumbs(thumbs: List<Long>) {
        CoroutineScope(Dispatchers.Main).launch {
            galleryApi.thumbsExist(thumbs) {
                if (it.isEmpty()) {
                    return@thumbsExist
                }
                scope.launch {
                    thumbnailsChannel.send(ThumbOp(it, null))
                }
            }
        }
    }

    fun add(op: MoveOp) {
        scope.launch {
            channel.send(op)
        }
    }
}

private val imagesMutex = Mutex()

internal class ImageView(
    context: Context,
    id: Int,
    params: Map<String, String>
) : PlatformView {
    private var imageView: View?
    private var gif: GifDrawable? = null
    private var image: Bitmap? = null

    override fun getView(): View? {
        return imageView
    }

    override fun dispose() {
        imageView?.invalidate()
        imageView = null
        gif?.recycle()
        image?.recycle()

        gif = null
        image = null
    }

    init {
        val isGif = params.containsKey("gif")

        imageView = if (isGif) {
            GifImageView(context)
        } else {
            android.widget.ImageView(context)
        }

        CoroutineScope(Dispatchers.IO).launch {
            imagesMutex.lock()
            try {
                if (isGif) {
                    val drawable = GifDrawable(context.contentResolver, Uri.parse(params["uri"]))

                    CoroutineScope(Dispatchers.Main).launch {
                        if (imageView == null) {
                            drawable.recycle()
                        } else {
                            gif = drawable
                            (imageView as GifImageView).setImageDrawable(drawable)
                        }
                    }.join()
                } else {
                    context.contentResolver.openInputStream(Uri.parse(params["uri"]))
                        ?.use { stream ->
                            val b = BitmapFactory.decodeStream(stream)
                            CoroutineScope(Dispatchers.Main).launch {
                                if (imageView == null) {
                                    b.recycle()
                                } else {
                                    image = b
                                    (imageView as android.widget.ImageView).setImageBitmap(b)
                                }
                            }.join()
                        }
                }
            } catch (e: java.lang.Exception) {
                Log.e("ImageView bitmap", e.toString())
            }

            imagesMutex.unlock()
        }
    }
}

class NativeViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return ImageView(context, viewId, args as Map<String, String>)
    }
}

@ExperimentalUnsignedTypes
val transparentImage = ubyteArrayOf(
    0x89u,
    0x50u,
    0x4Eu,
    0x47u,
    0x0Du,
    0x0Au,
    0x1Au,
    0x0Au,
    0x00u,
    0x00u,
    0x00u,
    0x0Du,
    0x49u,
    0x48u,
    0x44u,
    0x52u,
    0x00u,
    0x00u,
    0x00u,
    0x01u,
    0x00u,
    0x00u,
    0x00u,
    0x01u,
    0x08u,
    0x06u,
    0x00u,
    0x00u,
    0x00u,
    0x1Fu,
    0x15u,
    0xC4u,
    0x89u,
    0x00u,
    0x00u,
    0x00u,
    0x0Au,
    0x49u,
    0x44u,
    0x41u,
    0x54u,
    0x78u,
    0x9Cu,
    0x63u,
    0x00u,
    0x01u,
    0x00u,
    0x00u,
    0x05u,
    0x00u,
    0x01u,
    0x0Du,
    0x0Au,
    0x2Du,
    0xB4u,
    0x00u,
    0x00u,
    0x00u,
    0x00u,
    0x49u,
    0x45u,
    0x4Eu,
    0x44u,
    0xAEu,
    0x42u,
    0x60u,
    0x82u,
).toByteArray()