// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package com.github.thebiglettuce.azari.enginebindings

//noinspection SuspiciousImport
import android.R
import android.app.Activity
import android.app.WallpaperManager
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
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
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.IntentSenderRequest
import androidx.annotation.RequiresApi
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.github.thebiglettuce.azari.ActivityResultIntents
import com.github.thebiglettuce.azari.App
import com.github.thebiglettuce.azari.generated.GalleryHostApi
import com.github.thebiglettuce.azari.generated.PlatformGalleryApi
import com.github.thebiglettuce.azari.mover.FilesDest
import com.github.thebiglettuce.azari.mover.Thumbnailer
import com.github.thebiglettuce.azari.mover.MoveInternalOp
import com.github.thebiglettuce.azari.mover.MoveOp
import com.github.thebiglettuce.azari.mover.RenameOp
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import okio.use
import java.io.File
import java.nio.file.Path
import kotlin.io.path.name
import androidx.core.net.toUri

class AppContextChannel(
    val engine: FlutterEngine,
    private val galleryApi: PlatformGalleryApi,
) {
    private val channel = MethodChannel(
        engine.dartExecutor.binaryMessenger,
        CHANNEL_NAME,
        StandardMethodCodec.INSTANCE,
        engine.dartExecutor.makeBackgroundTaskQueue()
    )

    fun attach(
        app: App,
        thumbnailer: Thumbnailer,
        connectivityManager: ConnectivityManager,
    ) {
        setMethodHandler(app, thumbnailer, connectivityManager)
    }

    fun attachSecondary(
        context: FlutterFragmentActivity,
        thumbnailer: Thumbnailer,
        connectivityManager: ConnectivityManager,
    ) {
        setMethodHandler(context, thumbnailer, connectivityManager)
    }

    private fun setMethodHandler(
        context: Context,
        thumbnailer: Thumbnailer,
        connectivityManager: ConnectivityManager,
    ) {

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
                        thumbnailer.add(
                            MoveOp(
                                source,
                                rootUri.toUri(),
                                dir,
                                ::notifyGallery
                            ),
                        )
                        result.success(null)
                    }
                }

                "requiresStoragePermission" -> {
                    result.success(Build.VERSION.SDK_INT == Build.VERSION_CODES.Q)
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

                "currentMediastoreVersion" -> {
                    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.R) {
                        result.success(0L)
                        return@setMethodCallHandler
                    }

                    result.success(MediaStore.getGeneration(context, MediaStore.VOLUME_EXTERNAL))
                }

                "deleteCachedThumbs" -> {
                    thumbnailer.deleteCachedThumbs(
                        call.argument<List<Long>>("ids")!!,
                        call.argument<Boolean>("fromPinned")!!
                    )
                    result.success(Unit)
                }

                "preloadImage" -> {
//                    Glide.with(context).load(Uri.parse(call.arguments as String)).preload()
                }

                "clearCachedThumbs" -> {
                    thumbnailer.clearCachedThumbs(call.arguments as Boolean)
                    result.success(Unit)
                }

                "thumbCacheSize" -> {
                    thumbnailer.thumbCacheSize(result, call.arguments as Boolean)
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

                    thumbnailer.getCachedThumbnail(id, result)
                }

                "saveThumbNetwork" -> {
                    val id = (call.arguments as Map<String, Any>)["id"]

                    val url =
                        call.argument<String>("url") ?: throw Exception("url should be String")

                    thumbnailer.saveThumbnailNetwork(
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

                "trashThumbId" -> {
                    thumbnailer.scope.launch {
                        val res = thumbnailer.trashThumbIds(context, true)

                        result.success(res.first.firstOrNull())
                    }
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
                        result.success(0xffffdadb)
                        Log.i("accent", e.toString())
                    }

                }

                else -> result.notImplemented()
            }
        }
    }

    fun detach() {
        GalleryHostApi.setUp(engine.dartExecutor.binaryMessenger, null)
        channel.setMethodCallHandler(null)
    }

    fun notifyGallery(uiScope: CoroutineScope, target: String?) {
        uiScope.launch {
            galleryApi.notify(target) {
            }
        }
    }

    companion object {
        const val CHANNEL_NAME = "com.github.thebiglettuce.azari.app_context"
    }
}

class ActivityContextChannel(
    dartExecutor: DartExecutor,
    private val galleryApi: PlatformGalleryApi,
) {
    private val channel = MethodChannel(
        dartExecutor.binaryMessenger,
        CHANNEL_NAME,
        StandardMethodCodec.INSTANCE,
        dartExecutor.makeBackgroundTaskQueue()
    )

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

    fun attach(
        context: FlutterFragmentActivity,
        intents: ActivityResultIntents,
        thumbnailer: Thumbnailer,
    ) {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "closeActivity" -> {
                    context.finish()
                }

                "setWakelock" -> {
                    val lockWake = call.arguments as Boolean

                    thumbnailer.uiScope.launch {
                        if (lockWake) {
                            context.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } else {
                            context.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }

                        result.success(null)
                    }
                }

                "returnUri" -> {
                    returnUri(context, call, result)
                }

                "hideRecents" -> {
                    hideRecents(context, call)
                }

                "getQuickViewUris" -> {
                    val data = context.intent.data

                    result.success(listOf(data!!.toString()))
                }

                "setFullscreen" -> {
                    setFullscreen(thumbnailer, context, call)
                }

                "deleteFiles" -> {
                    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.R) {
                        androidQDeleteFiles(thumbnailer, context, call, result)
                    } else {
                        deleteFiles(context, call, result, intents)
                    }
                }

                "version" -> {
                    result.success(
                        context.packageManager!!.getPackageInfo(
                            context.packageName,
                            0
                        ).versionName ?: ""
                    )
                }

                "emptyTrash" -> {
                    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.R) {
                        result.success(null)
                    } else {
                        emptyTrash(thumbnailer, context, intents)
                    }
                }

                "moveInternal" -> {
                    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.R) {
                        oldAndroidMoveInternal(thumbnailer, context, call, result)
                    } else {
                        moveInternal(thumbnailer, context, call, result, intents)
                    }
                }

                "pickFileAndCopy" -> {
                    pickFileCopy(thumbnailer, context, call, result, intents)
                }

                "requestManageMedia" -> {
                    if (intents.manageMedia == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }

                    requestManageMedia(thumbnailer, context, result, intents.manageMedia)
                }

                "chooseDirectory" -> {
                    chooseDirectory(thumbnailer, context, call, result, intents)
                }

                "setWallpaper" -> {
                    setWallpaper(context, call, result)
                }

                "shareMedia" -> {
                    shareMedia(context, call, result)
                }

                "rename" -> {
                    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.R) {
                        oldAndroidRename(thumbnailer, context, call, result)
                    } else {
                        rename(thumbnailer, context, call, result, intents)
                    }
                }

                "addToTrash" -> {
                    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.R) {
                        androidQDeleteFiles(thumbnailer, context, call, result)
                    } else {
                        addToTrash(context, call, result, intents)
                    }
                }

                "removeFromTrash" -> {
                    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.R) {
                        result.success(null)
                    } else {
                        removeFromTrash(context, call, result, intents)
                    }
                }

                "copyMoveInternal" -> {
                    copyMoveInternal(thumbnailer, context, call, result)
                }

                "copyMoveFiles" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        copyMoveFiles(thumbnailer, context, call, result, intents)
                    } else {
                        copyMoveFilesDirect(thumbnailer, context, call, result)
                    }
                }
            }
        }
    }

    private fun returnUri(
        context: FlutterFragmentActivity,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val uri = call.arguments as String
        result.success(null)
        val intent = Intent()
        intent.setData(Uri.parse(uri))
        intent.setFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

        context.setResult(Activity.RESULT_OK, intent)
        context.finish()
    }

    private fun hideRecents(
        context: FlutterFragmentActivity,
        call: MethodCall,
    ) {
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

    private fun setFullscreen(
        thumbnailer: Thumbnailer,
        context: FlutterFragmentActivity,
        call: MethodCall,
    ) {
        val data = call.arguments as Boolean

        thumbnailer.uiScope.launch {
            val windowInsets = WindowCompat.getInsetsController(
                context.window,
                context.window.decorView
            )

            windowInsets.systemBarsBehavior =
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE

            if (data) {
                windowInsets.hide(WindowInsetsCompat.Type.systemBars())
            } else {
                windowInsets.show(WindowInsetsCompat.Type.systemBars())
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun deleteFiles(
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
        intents: ActivityResultIntents,
    ) {
        try {
            val deleteItems = (call.arguments as List<String>).map { Uri.parse(it) }
            intents.deleteRequest.launch(
                IntentSenderRequest.Builder(
                    MediaStore.createDeleteRequest(
                        context.contentResolver,
                        deleteItems
                    )
                ).build()
            )
        } catch (e: java.lang.Exception) {
            Log.e("deleteFiles", e.toString())
        }

        result.success(null)
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun emptyTrash(
        thumbnailer: Thumbnailer,
        context: Context,
        intents: ActivityResultIntents,
    ) {
        thumbnailer.scope.launch {
            thumbnailer.trashDeleteMux.lock()
            val (images, videos) = thumbnailer.trashThumbIds(
                context,
                lastOnly = false,
                separate = true
            )
            if (images.isNotEmpty() || videos.isNotEmpty()) {
                val imagesUris = images.map {
                    ContentUris.withAppendedId(
                        MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL),
                        it
                    )
                }

                val videosUris = videos.map {
                    ContentUris.withAppendedId(
                        MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL),
                        it
                    )
                }

                try {
                    intents.deleteRequest.launch(
                        IntentSenderRequest.Builder(
                            MediaStore.createDeleteRequest(
                                context.contentResolver, imagesUris.plus(videosUris)
                            )
                        ).build()
                    )
                } catch (e: Exception) {
                    Log.e("emptyTrash", e.toString())
                }
            }

            thumbnailer.trashDeleteMux.unlock()
        }
    }

    private fun oldAndroidMoveInternal(
        thumbnailer: Thumbnailer,
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val dir = call.argument<String>("dir") ?: throw Exception("dir is empty")
        val uris =
            call.argument<List<String>>("uris") ?: throw Exception("uris is empty")

        val urisParsed = uris.map { Uri.parse(it) }

        val contentResolver = context.contentResolver;

        thumbnailer.scope.launch {
            try {
                for (e in urisParsed) {
                    val mimeType = contentResolver.getType(e)!!

                    contentResolver.openInputStream(e)?.use { stream ->
                        contentResolver.query(
                            e,
                            arrayOf(
                                MediaStore.MediaColumns.DISPLAY_NAME,
                            ),
                            null,
                            null,
                            null
                        )?.use {
                            if (!it.moveToFirst()) {
                                return@use
                            }

                            newDirCopyFile(
                                context,
                                e,
                                newDirIsLocal = true,
                                deleteAfter = true,
                                stream = stream,
                                displayName = it.getString(0),
                                dateModified = it.getLong(1),
                                mimeType = mimeType,
                                dest = dir
                            )
                        }
                    }
                }

                result.success(null)
            } catch (e: Exception) {
                result.error(e.toString(), "", "")
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun moveInternal(
        thumbnailer: Thumbnailer,
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
        intents: ActivityResultIntents,
    ) {
        val dir = call.argument<String>("dir") ?: throw Exception("dir is empty")
        val uris =
            call.argument<List<String>>("uris") ?: throw Exception("uris is empty")

        val urisParsed = uris.map { Uri.parse(it) }

        thumbnailer.scope.launch {
            moveInternalMux.lock()

            try {
                moveInternal = MoveInternalOp(dir, urisParsed) {
                    result.success(it)
                }

                intents.writeRequestInternal.launch(
                    IntentSenderRequest.Builder(
                        MediaStore.createWriteRequest(
                            context.contentResolver,
                            urisParsed
                        )
                    ).build()
                )
            } catch (e: Exception) {
                result.error(e.toString(), "", "")
                moveInternalMux.unlock()
            }
        }
    }

    private fun pickFileCopy(
        thumbnailer: Thumbnailer,
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
        intents: ActivityResultIntents,
    ) {
        thumbnailer.scope.launch {
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

                        val file = File(outputDir, uri.toString().split("/").last())

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

            intents.pickFileAndOpen.launch(arrayOf())
        }
    }

    private fun requestManageMedia(
        thumbnailer: Thumbnailer,
        context: Context,
        result: MethodChannel.Result,
        manageMedia: ActivityResultLauncher<String>,
    ) {
        thumbnailer.scope.launch {
            manageMediaMux.lock()

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    if (!MediaStore.canManageMedia(context)) {
                        val intent =
                            Intent(Settings.ACTION_REQUEST_MANAGE_MEDIA)
                        intent.data = "package:${context.packageName}".toUri()

                        manageMediaCallback = {
                            result.success(it)
                        }

                        manageMedia.launch(context.packageName)
                    } else {
                        result.success(true)
                    }
                }
            } catch (e: Exception) {
                Log.e("requestManageMedia", e.toString())
                result.success(false)
                manageMediaMux.unlock()
            }
        }
    }

    private fun setWallpaper(
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val idv = call.arguments
        val id =
            if (idv is Int) idv.toLong() else idv as Long

        val intent =
            WallpaperManager.getInstance(context).getCropAndSetWallpaperIntent(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
                    MediaStore.Images.Media.getContentUri(
                        MediaStore.VOLUME_EXTERNAL,
                        id
                    ) else
                    ContentUris.appendId(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI.buildUpon(),
                        id
                    ).build()
            )

        context.startActivity(intent)

        result.success(null)
    }

    private fun chooseDirectory(
        thumbnailer: Thumbnailer,
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
        intents: ActivityResultIntents,
    ) {
        thumbnailer.scope.launch {
            callbackMux.lock()
            val temporary = call.arguments as Boolean


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

            intents.chooseDirectory.launch(Pair(true, null))
        }
    }

    private fun shareMedia(
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
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

    private fun oldAndroidRename(
        thumbnailer: Thumbnailer,
        context: FlutterFragmentActivity,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        thumbnailer.scope.launch {
            try {
                val uri = call.argument<String>("uri") ?: throw Exception("empty uri")
                val newName =
                    call.argument<String>("newName") ?: throw Exception("empty name")
                val notify =
                    call.argument<Boolean>("notify") ?: throw Exception("empty notify")

                val (type, id) = typeIdFromUri(listOf(uri)).entries.first()

                val details = ContentValues().apply {
                    put(MediaStore.Files.FileColumns.DISPLAY_NAME, newName)
                }

                if (type == "images") {
                    context.contentResolver.update(
                        ContentUris.withAppendedId(
                            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                            id.first()
                        ),
                        details,
                        null,
                        null,
                    )
                } else if (type == "videos") {
                    context.contentResolver.update(
                        ContentUris.withAppendedId(
                            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                            id.first()
                        ),
                        details,
                        null,
                        null,
                    )
                }

                if (notify) {
                    context.runOnUiThread {
                        galleryApi.notify(null) {

                        }
                    }
                }

                result.success(null)
            } catch (e: java.lang.Exception) {
                Log.e("rename", e.toString())
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun rename(
        thumbnailer: Thumbnailer,
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
        intents: ActivityResultIntents,
    ) {
        thumbnailer.scope.launch {
            renameMux.lock()
            try {
                val uri = call.argument<String>("uri") ?: throw Exception("empty uri")
                val newName =
                    call.argument<String>("newName") ?: throw Exception("empty name")
                val notify =
                    call.argument<Boolean>("notify") ?: throw Exception("empty notify")

                val parsedUri = Uri.parse(uri)

                rename = RenameOp(parsedUri, newName, notify)

                intents.writeRequest.launch(
                    IntentSenderRequest.Builder(
                        MediaStore.createWriteRequest(
                            context.contentResolver,
                            listOf(parsedUri)
                        )
                    ).build()
                )

                result.success(null)
            } catch (e: java.lang.Exception) {
                renameMux.unlock()
                Log.e("rename", e.toString())
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun addToTrash(
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
        intents: ActivityResultIntents,
    ) {
        val uris = (call.arguments as List<String>).map { Uri.parse(it) }

        intents.trashRequest.launch(
            IntentSenderRequest.Builder(
                MediaStore.createTrashRequest(
                    context.contentResolver,
                    uris,
                    true
                )
            ).build()
        )

        result.success(null)
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun removeFromTrash(
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
        intents: ActivityResultIntents,
    ) {
        val uri = (call.arguments as List<String>).map { Uri.parse(it) }

        intents.trashRequest.launch(
            IntentSenderRequest.Builder(
                MediaStore.createTrashRequest(
                    context.contentResolver,
                    uri,
                    false
                )
            ).build()
        )

        result.success(null)
    }

    private fun copyMoveInternal(
        thumbnailer: Thumbnailer,
        context: FlutterFragmentActivity,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val relativePath = call.argument<String>("relativePath")!!
        val volume = call.argument<String>("volume")!!
        val dirName = call.argument<String>("dirName")!!
        val images = call.argument<List<String>>("images")!!
        val videos = call.argument<List<String>>("videos")!!

        thumbnailer.scope.launch {
            try {
                for (e in videos) {
                    copyFileInternal(
                        contentResolver = context.contentResolver,
                        internalFile = e,
                        volumeName = volume,
                        deleteAfter = true,
                        dest = relativePath,
                        isImage = false,
                    )
                }

                for (e in images) {
                    copyFileInternal(
                        contentResolver = context.contentResolver,
                        internalFile = e,
                        volumeName = volume,
                        deleteAfter = true,
                        dest = relativePath,
                        isImage = true,
                    )
                }

                context.runOnUiThread {
                    galleryApi.notify(dirName) {

                    }
                }
                result.success(null)
            } catch (e: Exception) {
                Log.i("copyMoveInternal", e.toString())
                result.error(e.toString(), null, null)
            }
        }
    }

//    private fun androidQCopyMoveFiles(
//        mediaLoaderAndMover: MediaLoaderAndMover,
//        context: Context,
//        call: MethodCall,
//        result: MethodChannel.Result,
//        intents: ActivityResultIntents,
//    ) {
//        mediaLoaderAndMover.scope.launch {
//            val dest = call.argument<String>("dest")
//            val images = call.argument<List<Long>>("images")
//            val videos = call.argument<List<Long>>("videos")
//            val move = call.argument<Boolean>("move")
//            val newDir = call.argument<Boolean>("newDir")
//            val volumeName = call.argument<String?>("volumeName")
//
//            if (dest == null) {
//                result.error("dest is empty", "", "")
//            } else if (images == null || videos == null || move == null || newDir == null) {
//                result.error("media or move or newDir or videos is empty", "", "")
//            } else if (newDir == false && volumeName == null) {
//                result.error(
//                    "if newDir is false, volumeName should be supplied",
//                    "",
//                    ""
//                )
//            } else {
//                try {
//                    if (move) {
//                        if (newDir) {
//
//                        } else {
//                            oldAndroidMoveFiles(
//                                mediaLoaderAndMover,
//                                context,
//                                if (newDir) convertDocUriToRelpath(dest) else pathToRelpath(
//                                    Path.of(
//                                        dest
//                                    ).parent.toString()
//                                ),
//                                images,
//                                videos,
//                                result
//                            )
//                        }
//                    } else {
////                        oldAndroidCopyFiles(context, dest, images, videos)
//                    }
//                } catch (e: Exception) {
////                    e.
//                    Log.e("oldAndroidCopyMoveFiles", e.message, e)
//                }
//            }
//        }
//    }

//    private fun convertDocUriToRelpath(dest: String): String {
//        if (dest.isBlank()) {
//            return ""
//        }
//
//        val uri = Uri.parse(dest)
//
//        val tree = "/tree/"
//
//        val path = uri.path!!.substring(tree.length)
//
//        val ret = if (path.startsWith("primary:")) {
//            path.substring("primary:".length)
//        } else {
//            path.dropWhile { it != ':' }.removePrefix(":")
//        }
//
//        return if (ret.last() != '/') {
//            "$ret/"
//        } else {
//            ret
//        }
//    }
//
//    private fun pathToRelpath(dest: String): String {
//        if (dest.isBlank()) {
//            return ""
//        }
//
//        val ret = if (dest.startsWith("/storage/emulated/0/")) {
//            dest.removePrefix("/storage/emulated/0/")
//        } else if (dest.startsWith("/storage/")) {
//            dest.removePrefix("/storage/").dropWhile { it != '/' }.removePrefix("/")
//        } else {
//            dest
//        }
//
//        return if (ret.last() != '/') {
//            "$ret/"
//        } else {
//            ret
//        }
//    }

    private fun oldAndroidMoveFiles(
        thumbnailer: Thumbnailer,
        context: Context,
        dest: String,
        imageIds: List<Long>,
        videoIds: List<Long>,
        result: MethodChannel.Result,
    ) {
        val imageNames = if (imageIds.isNotEmpty()) getDataOfIds(
            context,
            imageIds,
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
        ) else null

        val videoNames = if (videoIds.isNotEmpty()) getDataOfIds(
            context,
            videoIds,
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        ) else null

        if (imageNames != null) {
            updateDataAll(
                context,
                dest,
                imageNames,
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            )
        }

        if (videoNames != null) {
            updateDataAll(
                context,
                dest,
                videoNames,
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            )

        }

        notifyGallery(thumbnailer.uiScope, null)

        result.success(null)
    }

    private fun updateDataAll(
        context: Context,
        relParent: String,
        idNames: List<Pair<Long, String>>,
        uri: Uri,
    ) {
        for (e in idNames) {
            val values = ContentValues().apply {
                put(
                    "relative_path",
                    relParent
                )
            }

            context.contentResolver.update(
                ContentUris.withAppendedId(uri, e.first),
                values,
                null,
                null,
            )
        }
    }

    private fun getDataOfIds(
        context: Context,
        ids: List<Long>,
        uri: Uri,
    ): List<Pair<Long, String>> {
        val ret = mutableListOf<Pair<Long, String>>()

        val whereBuilder = StringBuilder()
        whereBuilder.append("_id = ?")
        if (ids.size > 1) {
            for (v in ids.slice(1..<ids.size)) {
                whereBuilder.append(" OR _id = ?")
            }
        }

        context.contentResolver.query(
            uri,
            arrayOf("_data", "_id"),
            whereBuilder.toString(), ids.map { it.toString() }.toTypedArray(), null,
        )?.use {
            val dataColumn = it.getColumnIndexOrThrow("_data")
            val idColumn = it.getColumnIndexOrThrow("_id")

            if (!it.moveToFirst()) {
                return@use
            }

            do {
                ret.add(Pair(it.getLong(idColumn), Path.of(it.getString(dataColumn)).name))
            } while (
                it.moveToNext()
            )
        }

        return ret
    }

    private fun copyMoveFilesDirect(
        thumbnailer: Thumbnailer,
        context: FlutterFragmentActivity,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        thumbnailer.scope.launch {
            val dest = call.argument<String>("dest")
            val images = call.argument<List<Long>>("images")
            val videos = call.argument<List<Long>>("videos")
            val move = call.argument<Boolean>("move")
            val newDir = call.argument<Boolean>("newDir")
            val volumeName = call.argument<String?>("volumeName")

            if (dest == null) {
                result.error("dest is empty", "", "")
            } else if (images == null || videos == null || move == null || newDir == null) {
                result.error("media or move or newDir or videos is empty", "", "")
            } else if (newDir == false && volumeName == null) {
                result.error(
                    "if newDir is false, volumeName should be supplied",
                    "",
                    ""
                )
            } else {
                try {
                    copyFilesMux.lock()

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

                    if (imageUris.isNotEmpty()) {
                        copyOrMove(
                            context,
                            imageUris,
                            isImage = true,
                            newDir = newDir,
                            volumeName = volumeName,
                            move = move,
                            dest = dest,
                        )
                    }

                    if (videoUris.isNotEmpty()) {
                        copyOrMove(
                            context,
                            videoUris,
                            isImage = false,
                            newDir = newDir,
                            volumeName = volumeName,
                            move = move,
                            dest = dest,
                        )
                    }

                    result.success(null)
                } catch (e: java.lang.Exception) {
                    result.error(e.toString(), null, null)
                    Log.e("copy files old", e.toString())
                } finally {
                    copyFilesMux.unlock()
                }

                notifyGallery(thumbnailer.uiScope, null)
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun copyMoveFiles(
        thumbnailer: Thumbnailer,
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
        intents: ActivityResultIntents,
    ) {
        thumbnailer.scope.launch {
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

                    copyFiles = FilesDest(
                        dest,
                        images = imageUris,
                        videos = videoUris,
                        move = move,
                        volumeName = volumeName,
                        newDir = newDir,
                        callback = {
                            if (it == null) {
                                result.success(null)
                            } else {
                                result.error(it, null, null)
                            }
                        }
                    )

                    intents.writeRequestCopyMove.launch(
                        IntentSenderRequest.Builder(
                            MediaStore.createWriteRequest(
                                context.contentResolver,
                                imageUris + videoUris
                            )
                        ).build()
                    )
                } catch (e: java.lang.Exception) {
                    copyFilesMux.unlock()
                }
            }
        }
    }

    private fun androidQDeleteFiles(
        thumbnailer: Thumbnailer,
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        thumbnailer.scope.launch {
            val uris = typeIdFromUri(call.arguments as List<String>)

            try {
                for (e in uris) {
                    for (id in e.value) {
                        if (e.key == "images") {
                            context.contentResolver.delete(
                                ContentUris.withAppendedId(
                                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                                    id
                                ),
                                null,
                                null,
                            )
                        } else if (e.key == "videos") {
                            context.contentResolver.delete(
                                ContentUris.withAppendedId(
                                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                                    id
                                ),
                                null,
                                null,
                            )
                        }
                    }
//                    val whereBuilder = StringBuilder()
//                    whereBuilder.append("_id = ?")
//                    if (e.value.size > 1) {
//                        for (v in e.value.slice(1..<e.value.size)) {
//                            whereBuilder.append(" OR _id = ?")
//                        }
//                    }
//
//                    if (e.key == "images") {
//                        context.contentResolver.delete(
//                            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
//                            whereBuilder.toString(),
//                            e.value.map { it.toString() }.toTypedArray(),
//                        )
//                    } else if (e.key == "videos") {
//                        context.contentResolver.delete(
//                            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
//                            whereBuilder.toString(),
//                            e.value.map { it.toString() }.toTypedArray(),
//                        )
//                    }
                }

                notifyGallery(thumbnailer.uiScope, null)
            } catch (e: Exception) {
                Log.i("addToTrash", e.toString())
            }
        }

        result.success(null)
    }

    fun notifyGallery(uiScope: CoroutineScope, target: String?) {
        uiScope.launch {
            galleryApi.notify(target) {
            }
        }
    }

    fun detach() {
        channel.setMethodCallHandler(null)
    }

    companion object {
        const val CHANNEL_NAME = "com.github.thebiglettuce.azari.activity_context"

        fun typeIdFromUri(uris: List<String>): MutableMap<String, MutableList<Long>> {
            return uris.map {
                val uri = Uri.parse(it)
                val id = ContentUris.parseId(uri)
                val type = uri.pathSegments.takeLast(3).first()

                Pair(type, id)
            }.fold(mutableMapOf<String, MutableList<Long>>()) { m, e ->
                var list = m[e.first]
                if (list == null) {
                    m[e.first] = mutableListOf()
                    list = m[e.first]!!
                }
                list.add(e.second);
                m
            }
        }
    }
}