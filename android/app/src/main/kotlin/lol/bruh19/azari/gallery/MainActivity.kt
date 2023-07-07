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
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.StrictMode
import android.provider.MediaStore
import android.util.Log
import android.util.Size
import android.util.TypedValue
import android.view.ContextThemeWrapper
import android.webkit.MimeTypeMap
import androidx.annotation.NonNull
import androidx.documentfile.provider.DocumentFile
import androidx.lifecycle.lifecycleScope
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import okio.FileSystem
import okio.Path.Companion.toPath
import okio.buffer
import okio.sink
import java.io.ByteArrayOutputStream
import kotlin.coroutines.CoroutineContext
import kotlin.io.path.Path
import kotlin.io.path.deleteIfExists
import kotlin.io.path.extension

class MainActivity : FlutterActivity() {
    private val CHANNEL = "lol.bruh19.azari.gallery"
    private lateinit var mover: Mover
    private var callback: ((String) -> Unit)? = null
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
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        mover = Mover(
            lifecycleScope.coroutineContext,
            context,
            GalleryApi(flutterEngine.dartExecutor.binaryMessenger)
        )

        super.configureFlutterEngine(flutterEngine)
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

class Mover(
    private val coContext: CoroutineContext,
    private val context: android.content.Context,
    private val galleryApi: GalleryApi
) {
    private val channel = Channel<MoveOp>()
    private val scope = CoroutineScope(coContext + Dispatchers.IO)

    private var isLockedMux = Mutex()

    init {
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

                    Path(op.source).deleteIfExists()
                }
            }
        }
    }

    fun refreshFiles(dirId: String) {
        if (isLockedMux.isLocked) {
            return
        }

        galleryApi.start {
            scope.launch {
                if (!isLockedMux.tryLock()) {
                    return@launch
                }

                refreshDirectoryFiles(dirId, context)

                isLockedMux.unlock()
            }
        }
    }

    fun refreshGallery() {
        if (isLockedMux.isLocked) {
            return
        }

        galleryApi.start {
            scope.launch {
                if (!isLockedMux.tryLock()) {
                    return@launch
                }

                refreshMediastore(it, context)

                isLockedMux.unlock()
            }
        }
    }

    private fun refreshDirectoryFiles(dir: String, context: Context) {
        val projection = arrayOf(
            MediaStore.Images.Media.BUCKET_ID,
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME,
            MediaStore.Images.Media.DATE_MODIFIED,
            MediaStore.Images.Media._ID,
        )

        context.contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection,
            "${MediaStore.Images.Media.BUCKET_ID} = ?",
            arrayOf(dir),
            null
        )?.use { cursor ->
            val id = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
            val bucket_id = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_ID)
            val b_display_name =
                cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_DISPLAY_NAME)
            val date_modified = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_MODIFIED)

            if (!cursor.moveToFirst()) {
                return@use
            }

            try {
                do {
                    val uri = ContentUris.withAppendedId(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                        cursor.getLong(id)
                    )

                    val thumb = context.contentResolver.loadThumbnail(uri, Size(320, 320), null)
                    val stream = ByteArrayOutputStream()

                    thumb.compress(Bitmap.CompressFormat.PNG, 100, stream)

                    val idval = cursor.getLong(id).toString()
                    val lastmodifval = cursor.getLong(date_modified)
                    val nameval = cursor.getString(b_display_name)
                    val directoryidval = cursor.getString(bucket_id)

                    Handler(Looper.getMainLooper()).post {
                        galleryApi.updatePicture(
                            DirectoryFile(
                                id = idval,
                                lastModified = lastmodifval,
                                name = nameval,
                                thumbnail = stream.toByteArray(),
                                directoryId = directoryidval,
                                originalUri = uri.toString()
                            )
                        ) {}

                        stream.reset()
                    }

                    thumb.recycle()
                } while (
                    cursor.moveToNext()
                )
            } catch (e: java.lang.Exception) {
                Log.e("refreshDirectoryFiles", "cursor block fail", e)
            }
        }
    }

    private fun refreshMediastore(previous: String, context: Context) {
        /*if (MediaStore.getVersion(
                context,
                MediaStore.getVolumeName(MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
            ) == previous
        ) {
            return
        }*/

        val projection = arrayOf(
            MediaStore.Images.Media.BUCKET_ID,
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME,
            MediaStore.Images.Media.DATE_MODIFIED,
            MediaStore.Images.Media._ID
        )
        // val selection = ""

        context.contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection,
            "",
            null,
            null
        )?.use { cursor ->
            val id = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
            val bucket_id = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_ID)
            val b_display_name =
                cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_DISPLAY_NAME)
            val date_modified = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_MODIFIED)

            val map = HashMap<String, Unit>()

            if (!cursor.moveToFirst()) {
                return@use
            }

            try {
                do {
                    val bucketId = cursor.getString(bucket_id)
                    if (map[bucketId] != null) {
                        continue
                    }

                    map[bucketId] = Unit

                    val uri = ContentUris.withAppendedId(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                        cursor.getLong(id)
                    )

                    val thumb = context.contentResolver.loadThumbnail(uri, Size(320, 320), null)
                    val stream = ByteArrayOutputStream()

                    thumb.compress(Bitmap.CompressFormat.PNG, 50, stream)

                    val lastmodifval = cursor.getLong(date_modified)
                    val nameval = cursor.getString(b_display_name)
                    val directoryidval = cursor.getString(bucket_id)

                    Handler(Looper.getMainLooper()).post {
                        galleryApi.updateDirectory(
                            Directory(
                                id = directoryidval,
                                lastModified = lastmodifval,
                                name = nameval,
                                thumbnail = stream.toByteArray()
                            )
                        ) {}

                        stream.reset()
                    }

                    thumb.recycle()
                } while (
                    cursor.moveToNext()
                )
            } catch (e: java.lang.Exception) {
                Log.e("refreshMediastore", "cursor block fail", e)
            }
        }

        Handler(Looper.getMainLooper()).post {
            galleryApi.finish(
                MediaStore.getVersion(
                    context,
                    MediaStore.getVolumeName(MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
                )
            ) {}
        }
    }

    fun add(op: MoveOp) {
        scope.launch {
            channel.send(op)
        }
    }
}

class ThumbnailDispatcher(val coContext: CoroutineContext) {
    private val scope = CoroutineScope(coContext)

    fun launch() {
        scope.launch {
            launch { }
        }
    }

}
