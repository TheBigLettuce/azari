// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery

import android.R
import android.app.Activity
import android.content.ContentUris
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import android.util.Log
import android.util.TypedValue
import android.view.ContextThemeWrapper
import androidx.lifecycle.lifecycleScope
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex

data class RenameOp(val uri: Uri, val newName: String)

data class MoveInternalOp(val dest: String, val uris: List<Uri>, val callback: (Boolean) -> Unit)

class EngineBindings(activity: FlutterActivity, entrypoint: String) {
    private val channel: MethodChannel
    private val context: FlutterActivity
    internal val mover: Mover
    private val galleryApi: GalleryApi

    val engine: FlutterEngine

    val callbackMux = Mutex()
    var callback: ((String?) -> Unit)? = null
    val copyFilesMux = Mutex()
    var copyFiles: FilesDest? = null
    val renameMux = Mutex()
    var rename: List<RenameOp>? = null
    val moveInternalMux = Mutex()
    var moveInternal: MoveInternalOp? = null


    init {
        val app = activity.applicationContext as App
        // This has to be lazy to avoid creation before the FlutterEngineGroup.
        val dartEntrypoint =
            DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(), entrypoint
            )
        engine = app.engines.createAndRunEngine(activity, dartEntrypoint)
        context = activity
        channel = MethodChannel(
            engine.dartExecutor.binaryMessenger,
            "lol.bruh19.azari.gallery",
            StandardMethodCodec.INSTANCE,
            engine.dartExecutor.makeBackgroundTaskQueue()
        )
        galleryApi = GalleryApi(engine.dartExecutor.binaryMessenger)
        mover = Mover(context.lifecycleScope.coroutineContext, context, galleryApi)
        engine.platformViewsController.registry.registerViewFactory(
            "imageview",
            NativeViewFactory()
        )
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
                        callback = {
                            if (it == null) {
                                callbackMux.unlock()
                                result.error("empty result", "", "")
                            } else {
                                if (!temporary) {
                                    context.contentResolver.takePersistableUriPermission(
                                        Uri.parse(it),
                                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                                    )
                                }

                                callbackMux.unlock()
                                result.success(it)
                            }
                        }

                        context.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE), 1)
                    }
                }

                "pickFileAndCopy" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        callbackMux.lock()
                        val outputDir = call.arguments as String
                        callback = {
                            if (it == null) {
                                callbackMux.unlock()
                                result.error("empty result", "", "")
                            } else {
                                try {
                                    val uri = Uri.parse(it)
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

                "loadThumbnail" -> {
                    var thumb = call.arguments
                    if (thumb is Int) {
                        thumb = thumb.toLong()
                    }
                    mover.loadThumb(thumb as Long)
                    result.success(null)
                }

                "requestManageMedia" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            if (!MediaStore.canManageMedia(context)) {
                                val intent =
                                    Intent(Settings.ACTION_REQUEST_MANAGE_MEDIA)
                                intent.data = Uri.parse("package:${context.packageName}")
                                context.startActivity(intent)
                            }
                        }
                    } catch (e: Exception) {
                        Log.e("requestManageMedia", e.toString())
                    }
                    result.success(null)
                }

                "rename" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        renameMux.lock()
                        try {
                            val uri = call.argument<String>("uri") ?: throw Exception("empty uri")
                            val newName =
                                call.argument<String>("newName") ?: throw Exception("empty name")

                            val parsedUri = Uri.parse(uri)

                            val intent = MediaStore.createWriteRequest(
                                context.contentResolver,
                                listOf(parsedUri)
                            )

                            rename = listOf(RenameOp(parsedUri, newName))

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

                "refreshTrashed" -> {
                    context.runOnUiThread {
                        mover.refreshFiles("trash", true)
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

                "getThumbDirectly" -> {
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

                    mover.getThumbnailCallback(id, result)
                }

                "getExpensiveHashDirectly" -> {
                    val id: Long = when (call.arguments) {
                        is Long -> {
                            call.arguments as Long
                        }

                        is Int -> {
                            (call.arguments as Int).toLong()
                        }

                        else -> {
                            throw java.lang.Exception("id is invalid")
                        }
                    }

                    mover.getExpensiveHashCallback(id, result)
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
                    val media = Uri.parse(call.arguments as String)
                    val intent = Intent().apply {
                        action = Intent.ACTION_SEND
                        putExtra(Intent.EXTRA_STREAM, media)
                        type = context.contentResolver.getType(media)
                    }
                    context.startActivity(Intent.createChooser(intent, null))
                    result.success(null)
                }

                "refreshFiles" -> {
                    context.runOnUiThread {
                        mover.refreshFiles(call.arguments as String)
                    }

                    result.success(null)
                }

                "refreshGallery" -> {
                    context.runOnUiThread {
                        mover.refreshGallery()
                    }

                    result.success(null)
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
                        var value = TypedValue()
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
        engine.destroy()
        channel.setMethodCallHandler(null)
    }
}