// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery

import android.R
import android.app.Activity
import android.app.WallpaperManager
import android.content.ContentUris
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import android.util.Log
import android.util.TypedValue
import android.view.ContextThemeWrapper
import android.view.WindowManager
import androidx.lifecycle.lifecycleScope
import com.bumptech.glide.Glide
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex

data class RenameOp(val uri: Uri, val newName: String, val notify: Boolean)

data class MoveInternalOp(val dest: String, val uris: List<Uri>, val callback: (Boolean) -> Unit)

class EngineBindings(
    activity: FlutterFragmentActivity,
    engineId: String,
    val connectivityManager: ConnectivityManager
) {
    private val channel: MethodChannel
    private val context: FlutterFragmentActivity
    internal val mover: Mover
    private val galleryApi: GalleryApi
    val netStatus: Manager

    val engine: FlutterEngine

    val callbackMux = Mutex()
    var callback: ((Pair<String, String>?) -> Unit)? = null
    val manageMediaMux = Mutex()
    var manageMediaCallback: ((Boolean) -> Unit)? = null
    val copyFilesMux = Mutex()
    var copyFiles: FilesDest? = null
    val renameMux = Mutex()
    var rename: RenameOp? = null
    val moveInternalMux = Mutex()
    var moveInternal: MoveInternalOp? = null

    init {
        engine = FlutterEngineCache.getInstance()[engineId]!!
        context = activity
        channel = MethodChannel(
            engine.dartExecutor.binaryMessenger,
            "lol.bruh19.azari.gallery",
            StandardMethodCodec.INSTANCE,
            engine.dartExecutor.makeBackgroundTaskQueue()
        )
        galleryApi = GalleryApi(engine.dartExecutor.binaryMessenger)
        netStatus = Manager(galleryApi, context)
        mover = Mover(context.lifecycleScope.coroutineContext, context, galleryApi)
    }


    fun attach() {
        channel.setMethodCallHandler { call, result ->
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
                    CoroutineScope(Dispatchers.IO).launch {
                        callbackMux.lock()
                        val temporary = call.arguments as Boolean

                        val i = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)

                        callback = {
                            if (it == null) {
                                callbackMux.unlock()
                                result.error("", "", "")
                            } else {
                                if (!temporary) {
                                    context.contentResolver.takePersistableUriPermission(
                                        Uri.parse(it.first),
                                        (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                                    )
                                }

                                callbackMux.unlock()
                                result.success(
                                    mapOf<String, String>(
                                        Pair("path", it.first),
                                        Pair("pathDisplay", it.second),
                                    )
                                )
                            }
                        }

                        if (temporary) {
                            i.addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                            )
                        } else {
                            i.addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                                        Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
                            )
                        }

                        context.startActivityForResult(i, 1)
                    }
                }

                "pickFileAndCopy" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        callbackMux.lock()
                        val outputDir = call.arguments as String
                        callback = {
                            if (it == null) {
                                callbackMux.unlock()
                                result.error("", "", "")
                            } else {
                                try {
                                    val uri = Uri.parse(it.first)
                                    var outputFile: String? = null

                                    val file =
                                        java.io.File(outputDir, uri.toString().split("/").last())

                                    if (file.exists()) {
                                        file.delete()
                                    }

                                    if (!file.createNewFile()) {
                                        throw Exception("exist")
                                    }

                                    context.contentResolver.openInputStream(uri)?.use { input ->
                                        file.outputStream().use { output ->
                                            input.transferTo(output)
                                            output.flush()
                                            output.fd.sync()
                                        }

                                        outputFile = file.absolutePath
                                    }

                                    if (outputFile == null) {
                                        throw Exception("file haven't been moved")
                                    }

                                    result.success(outputFile)
                                } catch (e: Exception) {
                                    Log.e("pickFileAndCopy", e.toString())
                                    result.error(e.toString(), null, null)
                                }

                                callbackMux.unlock()
                            }
                        }

                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
                        intent.addCategory(Intent.CATEGORY_OPENABLE)
                        intent.type = "*/*"

                        context.startActivityForResult(intent, 1)
                    }
                }

                "manageMediaSupported" -> {
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
                }

                "manageMediaStatus" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        result.success(MediaStore.canManageMedia(context))
                    } else {
                        result.success(false)
                    }
                }

                "requestManageMedia" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        manageMediaMux.lock()

                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                if (!MediaStore.canManageMedia(context)) {
                                    val intent =
                                        Intent(Settings.ACTION_REQUEST_MANAGE_MEDIA)
                                    intent.data = Uri.parse("package:${context.packageName}")

                                    manageMediaCallback = {
                                        result.success(it)
                                    }

                                    context.startActivityForResult(intent, 99)
                                }
                            }
                        } catch (e: Exception) {
                            Log.e("requestManageMedia", e.toString())
                            result.success(false)
                            manageMediaMux.unlock()
                        }
                    }
                }

                "rename" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        renameMux.lock()
                        try {
                            val uri = call.argument<String>("uri") ?: throw Exception("empty uri")
                            val newName =
                                call.argument<String>("newName") ?: throw Exception("empty name")
                            val notify =
                                call.argument<Boolean>("notify") ?: throw Exception("empty notify")

                            val parsedUri = Uri.parse(uri)

                            val intent = MediaStore.createWriteRequest(
                                context.contentResolver,
                                listOf(parsedUri)
                            )

                            rename = RenameOp(parsedUri, newName, notify)

                            context.startIntentSenderForResult(
                                intent.intentSender,
                                11,
                                null,
                                0,
                                0,
                                0
                            )

                            result.success(null)
                        } catch (e: java.lang.Exception) {
                            renameMux.unlock()
                            Log.e("rename", e.toString())
                        }
                    }
                }

                "refreshFavorites" -> {
                    context.runOnUiThread {
                        mover.refreshFavorites(
                            call.argument<List<Long>>("ids")!!,
                            FilesSortingMode.fromDartInt(call.argument<Int>("sort")!!)
                        ) {
                            result.success(null)
                        }
                    }
                }

                "refreshTrashed" -> {
                    context.runOnUiThread {
                        mover.refreshFiles(
                            "trash",
                            inRefreshAtEnd = true,
                            isTrashed = true,
                            sortingMode = FilesSortingMode.fromDartInt(call.arguments<Int>()!!)
                        )
                    }

                    result.success(null)
                }

                "addToTrash" -> {
                    val uris = (call.arguments as List<String>).map { Uri.parse(it) }

                    val intent =
                        MediaStore.createTrashRequest(context.contentResolver, uris, true)

                    context.startIntentSenderForResult(intent.intentSender, 13, null, 0, 0, 0)

                    result.success(null)
                }

                "removeFromTrash" -> {
                    val uri = (call.arguments as List<String>).map { Uri.parse(it) }

                    val intent =
                        MediaStore.createTrashRequest(context.contentResolver, uri, false)

                    context.startIntentSenderForResult(intent.intentSender, 14, null, 0, 0, 0)

                    result.success(null)
                }

                "currentMediastoreVersion" -> {
                    result.success(MediaStore.getGeneration(context, MediaStore.VOLUME_EXTERNAL))
                }

                "moveInternal" -> {
                    val dir = call.argument<String>("dir") ?: throw Exception("dir is empty")
                    val uris =
                        call.argument<List<String>>("uris") ?: throw Exception("uris is empty")

                    val urisParsed = uris.map { Uri.parse(it) }

                    CoroutineScope(Dispatchers.IO).launch {
                        moveInternalMux.lock()

                        try {
                            val intent = MediaStore.createWriteRequest(
                                context.contentResolver,
                                urisParsed
                            )

                            moveInternal = MoveInternalOp(dir, urisParsed) {
                                result.success(it)
                            }

                            context.startIntentSenderForResult(
                                intent.intentSender,
                                12,
                                null,
                                0,
                                0,
                                0
                            )
                        } catch (e: Exception) {
                            result.error(e.toString(), "", "")
                            moveInternalMux.unlock()
                        }
                    }
                }

                "deleteCachedThumbs" -> {
                    mover.deleteCachedThumbs(
                        call.argument<List<Long>>("ids")!!,
                        call.argument<Boolean>("fromPinned")!!
                    )
                }

                "preloadImage" -> {
                    Log.i("preload", "s")
                    Glide.with(context).load(Uri.parse(call.arguments as String)).preload()
                }

                "clearCachedThumbs" -> {
                    mover.clearCachedThumbs(call.arguments as Boolean)
                }

                "setWallpaper" -> {
                    val idv = call.arguments
                    val id =
                        if (idv is Int) idv.toLong() else idv as Long

                    val intent = WallpaperManager.getInstance(context).getCropAndSetWallpaperIntent(
                        MediaStore.Images.Media.getContentUri(
                            MediaStore.VOLUME_EXTERNAL,
                            id
                        )
                    )

                    context.startActivity(intent)

                    result.success(null)
                }

                "thumbCacheSize" -> {
                    mover.thumbCacheSize(result, call.arguments as Boolean)
                }

                "emptyTrash" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        mover.trashDeleteMux.lock()
                        val (images, videos) = mover.trashThumbIds(
                            context,
                            lastOnly = false,
                            separate = true
                        )
                        if (images.isNotEmpty() || videos.isNotEmpty()) {
                            val images = images.map {
                                ContentUris.withAppendedId(
                                    MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL),
                                    it
                                )
                            }

                            val videos = videos.map {
                                ContentUris.withAppendedId(
                                    MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL),
                                    it
                                )
                            }


                            val intent = MediaStore.createDeleteRequest(
                                context.contentResolver, images.plus(videos)
                            )

                            try {
                                context.startIntentSenderForResult(
                                    intent.intentSender,
                                    13,
                                    null,
                                    0,
                                    0,
                                    0
                                )
                            } catch (e: Exception) {
                                Log.e("emptyTrash", e.toString())
                            }
                        }

                        mover.trashDeleteMux.unlock()
                    }
                }

                "getCachedThumb" -> {
                    val id: Long = when (call.arguments) {
                        is Long -> {
                            call.arguments as Long
                        }

                        is Int -> {
                            (call.arguments as Int).toLong()
                        }

                        else -> {
                            throw Exception("id is invalid")
                        }
                    }

                    mover.getCachedThumbnail(id, result)
                }

                "saveThumbNetwork" -> {
                    val id = (call.arguments as Map<String, Any>)["id"]

                    val url =
                        call.argument<String>("url") ?: throw Exception("url should be String")

                    mover.saveThumbnailNetwork(
                        url,
                        if (id is Int) id.toLong() else if (id is Long) id else throw Exception("id should be Long"),
                        result
                    )
                }

                "currentNetworkStatus" -> {
                    val currentNetwork = connectivityManager.activeNetwork
                    val caps = connectivityManager.getNetworkCapabilities(currentNetwork)
                    if (caps == null) {
                        result.success(false)
                    } else {
                        result.success(
                            caps.hasCapability(
                                NetworkCapabilities.NET_CAPABILITY_INTERNET
                            ) and caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
                        )
                    }
                }

                "hideRecents" -> {
                    val hide = call.arguments as Boolean;

                    context.runOnUiThread {
                        if (hide) {
                            context.window.addFlags(
                                WindowManager.LayoutParams.FLAG_SECURE
                            );
                        } else {
                            context.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                    }
                }

                "copyMoveFiles" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        copyFilesMux.lock()
                        val dest = call.argument<String>("dest")
                        val images = call.argument<List<Long>>("images")
                        val videos = call.argument<List<Long>>("videos")
                        val move = call.argument<Boolean>("move")
                        val newDir = call.argument<Boolean>("newDir")
                        val volumeName = call.argument<String?>("volumeName")

                        if (dest == null) {
                            copyFilesMux.unlock()
                            result.error("dest is empty", "", "")
                        } else if (images == null || videos == null || move == null || newDir == null) {
                            copyFilesMux.unlock()
                            result.error("media or move or newDir or videos is empty", "", "")
                        } else if (newDir == false && volumeName == null) {
                            copyFilesMux.unlock()
                            result.error(
                                "if newDir is false, volumeName should be supplied",
                                "",
                                ""
                            )
                        } else {
                            try {
                                val imageUris = images.map {
                                    ContentUris.withAppendedId(
                                        MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL),
                                        it
                                    )
                                }
                                val videoUris = videos.map {
                                    ContentUris.withAppendedId(
                                        MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL),
                                        it
                                    )
                                }

                                val intent = MediaStore.createWriteRequest(
                                    context.contentResolver,
                                    imageUris + videoUris
                                )

                                copyFiles = FilesDest(
                                    dest,
                                    images = imageUris,
                                    videos = videoUris,
                                    move = move,
                                    volumeName = volumeName,
                                    newDir = newDir
                                )

                                context.startIntentSenderForResult(
                                    intent.intentSender,
                                    10,
                                    null,
                                    0,
                                    0,
                                    0
                                )

                                result.success(null)
                            } catch (e: java.lang.Exception) {
                                copyFilesMux.unlock()
                            }
                        }
                    }
                }

                "deleteFiles" -> {
                    try {
                        val deleteItems = (call.arguments as List<String>).map { Uri.parse(it) }
                        val status =
                            MediaStore.createDeleteRequest(
                                context.contentResolver,
                                deleteItems
                            )
                        context.startIntentSenderForResult(status.intentSender, 9, null, 0, 0, 0)
                    } catch (e: java.lang.Exception) {
                        Log.e("deleteFiles", e.toString())
                    }
                    result.success(null)
                }

                "shareMedia" -> {
                    val media = call.argument<String>("uri")!!
                    val isUrl = call.argument<Boolean>("isUrl")!!

                    val intent = Intent().apply {
                        action = Intent.ACTION_SEND
                        if (isUrl) putExtra(Intent.EXTRA_TEXT, media) else putExtra(
                            Intent.EXTRA_STREAM,
                            Uri.parse(media)
                        )
                        type = if (isUrl) "text/plain" else context.contentResolver.getType(
                            Uri.parse(media)
                        )
                    }
                    context.startActivity(Intent.createChooser(intent, null))
                    result.success(null)
                }

                "refreshFiles" -> {
                    context.runOnUiThread {
                        mover.refreshFiles(
                            call.argument<String>("bucketId")!!,
                            inRefreshAtEnd = true,
                            sortingMode = FilesSortingMode.fromDartInt(call.argument<Int>("sort")!!),
                        )
                    }

                    result.success(null)
                }

                "refreshFilesMultiple" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        mover.refreshFilesMultiple(
                            call.argument<List<String>>("ids")!!,
                            FilesSortingMode.fromDartInt(call.argument<Int>("sort")!!),
                        )
                    }

                    result.success(null)
                }

                "refreshGallery" -> {
                    mover.refreshGallery()

                    result.success(null)
                }

                "trashThumbId" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        val res = mover.trashThumbIds(context, true)

                        result.success(res.first.firstOrNull())
                    }
                }

                "returnUri" -> {
                    val uri = call.arguments as String
                    result.success(null)
                    val intent = Intent()
                    intent.setData(Uri.parse(uri))
                    intent.setFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

                    context.setResult(Activity.RESULT_OK, intent)
                    context.finish()
                }

                "accentColor" -> {
                    try {
                        val value = TypedValue()
                        ContextThemeWrapper(
                            context,
                            R.style.Theme_DeviceDefault
                        ).theme.resolveAttribute(R.attr.colorAccent, value, true)


                        result.success(value.data)
                    } catch (e: Exception) {
                        result.success(0xFF448AFF)
                        Log.i("accent", e.toString())
                    }

                }

                else -> result.notImplemented()
            }
        }
    }

    fun detach() {
        channel.setMethodCallHandler(null)
    }
}