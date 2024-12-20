// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package com.github.thebiglettuce.azari.mover

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import android.util.Size
import android.webkit.MimeTypeMap
import androidx.core.graphics.scale
import androidx.documentfile.provider.DocumentFile
import coil3.BitmapImage
import coil3.imageLoader
import coil3.request.ImageRequest
import coil3.request.allowHardware
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import okio.FileSystem
import okio.Path.Companion.toPath
import okio.buffer
import okio.sink
import okio.use
import java.io.ByteArrayOutputStream
import java.io.FileOutputStream
import kotlin.io.path.Path
import kotlin.io.path.deleteIfExists
import kotlin.io.path.extension

class Thumbnailer(private val context: Context) {
    private val cap = if (Runtime.getRuntime().availableProcessors() == 1) {
        1
    } else {
        Runtime.getRuntime().availableProcessors() - 1
    }

    private val moveChannel = Channel<MoveOp>()
    private val thumbnailsChannel = Channel<ThumbOp>(capacity = cap)

    internal val scope = CoroutineScope(Dispatchers.IO)
    internal val uiScope = CoroutineScope(Dispatchers.Main)

    val trashDeleteMux = Mutex()
    private val locker = CacheLocker(context)

    private var initDone = false

    fun initMover() {
        if (initDone) {
            return
        }

        scope.launch {
            val inProgress = mutableListOf<Job>()

            for (op in thumbnailsChannel) {
                try {
                    if (inProgress.count() == cap) {
                        inProgress.first().join()
                        inProgress.removeAt(0)
                    }

                    inProgress.add(launch {
                        var res: Pair<String, Long>
                        try {
                            res = when (op.thumb) {
                                is Long -> {
                                    val uri = ContentUris.withAppendedId(
                                        MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
                                        op.thumb
                                    )

                                    getThumb(op.thumb, uri, false, saveToPinned = op.saveToPinned)
                                }

                                is NetworkThumbOp -> {
                                    getThumb(
                                        op.thumb.id,
                                        Uri.parse(op.thumb.url),
                                        network = true,
                                        saveToPinned = op.saveToPinned
                                    )
                                }

                                else -> {
                                    Pair("", 0)
                                }
                            }

                        } catch (e: Exception) {
                            res = Pair("", 0)
                            Log.e("thumbnail coro", e.toString())
                        }

                        op.callback.invoke(res.first, res.second)
                    })
                } catch (e: java.lang.Exception) {
                    Log.e("thumbnails", e.toString())
                }
            }

            for (job in inProgress) {
                job.cancelAndJoin()
            }
            inProgress.clear()
        }

        scope.launch {
            val inProgress = mutableListOf<Job>()

            for (op in moveChannel) {
                if (inProgress.count() == cap) {
                    inProgress.first().join()
                    inProgress.removeAt(0)
                }

                inProgress.add(launch {
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

                        val docFd =
                            (context.contentResolver.openFile(
                                docDest.uri,
                                "w",
                                null
                            ))
                                ?: throw Exception("could not get an output stream")
                        docFd.use { fd ->
                            FileSystem.SYSTEM.openReadOnly(op.source.toPath()).use { fileSrc ->
                                FileOutputStream(fd.fileDescriptor).use { docStream ->
                                    docStream.sink().buffer().use { buffer ->
                                        fileSrc.source().use { src ->
                                            buffer.writeAll(src)
                                        }

                                        buffer.flush()
                                    }

                                    docStream.flush()
                                    docStream.fd.sync()
                                }
                            }
                        }
                    } catch (e: Exception) {
                        Log.e("Mover move coro", e.toString())
                    }

                    op.notifyGallery(uiScope, op.dir)

                    Path(op.source).deleteIfExists()
                })
            }

            for (job in inProgress) {
                job.cancelAndJoin()
            }
            inProgress.clear()
        }

        initDone = true
    }

    fun dispose() {
        moveChannel.close()
        thumbnailsChannel.close()
        scope.cancel()
        uiScope.cancel()
    }

    fun deleteCachedThumbs(thumbs: List<Long>, fromPinned: Boolean) {
        scope.launch {
            locker.removeAll(thumbs, fromPinned)
        }
    }

    fun clearCachedThumbs(fromPinned: Boolean) {
        scope.launch { locker.clear(fromPinned) }
    }

    fun getCachedThumbnail(thumb: Long, result: MethodChannel.Result) {
        scope.launch {
            if (locker.exist(thumb)) {
                result.success(mapOf<String, Any>(Pair("path", ""), Pair("hash", 0)))
            } else {
                thumbnailsChannel.send(ThumbOp(thumb) { path, hash ->
                    result.success(mapOf<String, Any>(Pair("path", path), Pair("hash", hash)))
                })
            }
        }
    }

    fun saveThumbnailNetwork(url: String, id: Long, result: MethodChannel.Result) {
        scope.launch {
            thumbnailsChannel.send(
                ThumbOp(
                    NetworkThumbOp(url, id),
                    saveToPinned = true
                ) { path, hash ->
                    result.success(mapOf<String, Any>(Pair("path", path), Pair("hash", hash)))
                })
        }
    }

    fun thumbCacheSize(res: MethodChannel.Result, fromPinned: Boolean) {
        scope.launch {
            res.success(locker.count(fromPinned))
        }
    }

    fun trashThumbIds(
        context: Context,
        lastOnly: Boolean,
        separate: Boolean = false,
        isFavorites: Boolean = false,
    ): Pair<List<Long>, List<Long>> {
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.R) {
            return Pair(listOf(), listOf())
        }

        val projection = if (separate) arrayOf(
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.MEDIA_TYPE,
        ) else arrayOf(MediaStore.Files.FileColumns._ID)

        val bundle = Bundle().apply {
            putString(
                ContentResolver.QUERY_ARG_SQL_SELECTION,
                "(${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} OR ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}) AND  ${MediaStore.Files.FileColumns.MIME_TYPE} != ?"
            )
            if (lastOnly) {
                putInt(ContentResolver.QUERY_ARG_LIMIT, 1)
            }
            putStringArray(ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS, arrayOf("image/vnd.djvu"))
            putString(
                ContentResolver.QUERY_ARG_SQL_SORT_ORDER,
                "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC"
            )
            if (isFavorites) {
                putInt(MediaStore.QUERY_ARG_MATCH_FAVORITE, MediaStore.MATCH_ONLY)
            } else {
                putInt(MediaStore.QUERY_ARG_MATCH_TRASHED, MediaStore.MATCH_ONLY)
            }
        }

        var result: Pair<List<Long>, List<Long>>? = null

        context.contentResolver.query(
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
            projection,
            bundle,
            null
        )?.use {
            if (!it.moveToFirst()) {
                return@use
            }

            if (separate) {
                val videos = mutableListOf<Long>()
                val images = mutableListOf<Long>()

                do {
                    val id = it.getLong(0)
                    val typ = it.getInt(1)

                    if (typ == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO) {
                        videos.add(id)
                    } else {
                        images.add(id)
                    }
                } while (
                    it.moveToNext()
                )

                result = Pair(images, videos)
            } else {
                val r = List<Long>(it.count) { idx ->
                    it.moveToPosition(idx)
                    it.getLong(0)
                }

                result = Pair(r, listOf())
            }
        }

        return if (result == null) Pair(listOf(), listOf()) else result!!
    }

    private fun diffHashFromThumb(scaled: Bitmap): Long {
        var hash: Long = 0
        val grayscale = List(8) { i ->
            List(9) { j ->
                scaled.getColor(j, i).luminance()
            }
        }

        var idx = 0
        for (l in grayscale) {
            for (i in 0 until l.count() - 1) {
                if (l[i] < l[i + 1]) {
                    hash = hash or 1 shl (64 - idx - 1)
                }
                idx++
            }
        }

        return hash
    }

    private suspend fun getThumb(
        id: Long,
        uri: Uri,
        network: Boolean,
        saveToPinned: Boolean,
    ): Pair<String, Long> {
        if (locker.exist(id)) {
            return Pair("", 0)
        }


        val thumb =
            if (network) (context.imageLoader.execute(
                ImageRequest.Builder(context).data(uri).allowHardware(false).build()
            ).image!! as BitmapImage).bitmap
            else if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.Q) (context.imageLoader.execute(
                ImageRequest.Builder(context).data(uri).size(320, 320).allowHardware(false).build()
            ).image!! as BitmapImage).bitmap else context.contentResolver.loadThumbnail(
                uri,
                Size(320, 320),
                null
            )
        val stream = ByteArrayOutputStream()

        val scaled = thumb.scale(9, 8)

        val hash = diffHashFromThumb(scaled)

        thumb.compress(
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) Bitmap.CompressFormat.WEBP_LOSSY else Bitmap.CompressFormat.JPEG,
            80,
            stream
        )

        val path = locker.put(stream, id, saveToPinned)

        stream.reset()
        thumb.recycle()

        if (path == null) {
            return Pair("", 0)
        }

        return Pair(path, hash)
    }

    fun add(op: MoveOp) {
        scope.launch {
            moveChannel.send(op)
        }
    }
}
