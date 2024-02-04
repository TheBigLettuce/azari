// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import android.util.Size
import android.webkit.MimeTypeMap
import androidx.core.graphics.scale
import androidx.documentfile.provider.DocumentFile
import com.bumptech.glide.Glide
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
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
import java.util.Calendar
import kotlin.coroutines.CoroutineContext
import kotlin.io.path.Path
import kotlin.io.path.deleteIfExists
import kotlin.io.path.extension

data class NetworkThumbOp(val url: String, val id: Long)

internal class Mover(
    private val coContext: CoroutineContext,
    private val context: Context,
    private val galleryApi: GalleryApi
) {
    private val channel = Channel<MoveOp>()
    private val cap = if (Runtime.getRuntime().availableProcessors() == 1) {
        1
    } else {
        Runtime.getRuntime().availableProcessors() - 1
    }
    private val thumbnailsChannel = Channel<ThumbOp>(capacity = cap)
    private val scope = CoroutineScope(coContext + Dispatchers.IO)

    private val isLockedDirMux = Mutex()
    private val isLockedFilesMux = Mutex()
    val trashDeleteMux = Mutex()
    private val locker = CacheLocker(context)

    init {
        scope.launch {
            val inProgress = mutableListOf<Job>()
            for (op in thumbnailsChannel) {
                try {
                    val newScope = CoroutineScope(Dispatchers.IO)

                    if (inProgress.count() == cap) {
                        inProgress.first().join()
                        inProgress.removeFirst()
                    }

                    inProgress.add(newScope.launch {
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


                        val docFd = context.contentResolver.openFile(docDest.uri, "w", null)
                            ?: throw Exception("could not get an output stream")
                        val fileSrc = FileSystem.SYSTEM.openReadOnly(op.source.toPath())

                        val docStream = FileOutputStream(docFd.fileDescriptor)

                        val buffer = docStream.sink().buffer()
                        val src = fileSrc.source()
                        buffer.writeAll(src)
                        buffer.flush()
                        docStream.flush()

                        docStream.fd.sync()

                        src.close()
                        buffer.close()
                        fileSrc.close()
                        docStream.close()
                        docFd.close()
                    } catch (e: Exception) {
                        Log.e("downloader", e.toString())
                    }

                    CoroutineScope(coContext).launch {
                        galleryApi.notify(op.dir) {

                        }
                    }

                    Path(op.source).deleteIfExists()
                }
            }
        }
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

    private fun perceptionHash(thumb: Bitmap): Long {
        val grayscale = rgb2Gray(thumb)
        val flattens = DCT2DFast64(grayscale)

        val median = medianOfPixelsFast64(flattens)

        var hash: Long = 0

        for (i in flattens.indices) {
            if (flattens[i] > median) {
                hash = hash or 1 shl (64 - i - 1)
            }
        }

        return hash
    }

    fun notifyGallery() {
        CoroutineScope(coContext).launch {
            galleryApi.notify(null) {
            }
        }
    }

    fun refreshFavorites(ids: List<Long>, closure: () -> Unit) {
        val time = Calendar.getInstance().time.time

        scope.launch {
            isLockedFilesMux.lock()
            loadMedia(
                "favorites",
                context,
                time,
                inRefreshAtEnd = true,
                showOnly = ids
            ) { content, empty, inRefresh ->
                sendMedia("favorites", time, content, empty, inRefresh)
            }

            closure()

            isLockedFilesMux.unlock()
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

    fun refreshFiles(
        dirId: String,
        inRefreshAtEnd: Boolean,
        isTrashed: Boolean = false,
        isFavorites: Boolean = false
    ) {
        val time = Calendar.getInstance().time.time

        scope.launch {
            isLockedFilesMux.lock()

            loadMedia(
                dirId,
                context,
                time,
                inRefreshAtEnd = inRefreshAtEnd,
                isTrashed = isTrashed,
                isFavorites = isFavorites
            ) { content, empty, inRefresh ->
                sendMedia(dirId, time, content, empty, inRefresh)
            }

            isLockedFilesMux.unlock()
        }
    }

    suspend fun refreshFilesMultiple(dirs: List<String>) {
        if (dirs.count() == 1) {
            refreshFiles(dirs.first(), inRefreshAtEnd = true)

            return
        }
        val time = Calendar.getInstance().time.time

        isLockedFilesMux.lock()

        val jobs = mutableListOf<Job>()

        for ((i, d) in dirs.subList(0, dirs.count() - 1).withIndex()) {
            if (jobs.count() == cap) {
                jobs.first().join()
                jobs.removeFirst()
            }

            jobs.add(CoroutineScope(Dispatchers.IO).launch {
                loadMedia(
                    d,
                    context,
                    time,
                    inRefreshAtEnd = false
                ) { content, empty, inRefresh ->
                    sendMedia(d, time, content, empty, inRefresh)
                }
            })
        }

        for (job in jobs) {
            job.join()
        }

        val last = dirs.last()

        loadMedia(
            last,
            context,
            time,
            inRefreshAtEnd = true
        ) { content, empty, inRefresh ->
            sendMedia(last, time, content, empty, inRefresh)
        }

        isLockedFilesMux.unlock()
    }

    private suspend fun sendMedia(
        dir: String,
        time: Long,
        content: List<DirectoryFile>,
        empty: Boolean,
        inRefresh: Boolean
    ) {
        CoroutineScope(coContext).launch {
            galleryApi.updatePictures(
                content,
                dir,
                time,
                inRefreshArg = inRefresh,
                emptyArg = empty
            ) {}
        }.join()
    }

    fun thumbCacheSize(res: MethodChannel.Result, fromPinned: Boolean) {
        CoroutineScope(Dispatchers.IO).launch {
            res.success(locker.count(fromPinned))
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

            refreshMediastore(context, galleryApi)

            isLockedDirMux.unlock()
        }
    }

    fun trashThumbIds(
        context: Context,
        lastOnly: Boolean,
        separate: Boolean = false,
        isFavorites: Boolean = false
    ): Pair<List<Long>, List<Long>> {
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

    private suspend fun loadMedia(
        dir: String,
        context: Context,
        time: Long,
        inRefreshAtEnd: Boolean,
        isTrashed: Boolean = false,
        isFavorites: Boolean = false,
        showOnly: List<Long>? = null,
        closure: suspend (content: List<DirectoryFile>, empty: Boolean, inRefresh: Boolean) -> Unit
    ) {
        val projection = arrayOf(
            MediaStore.Files.FileColumns.BUCKET_ID,
            MediaStore.Files.FileColumns.DISPLAY_NAME,
            MediaStore.Files.FileColumns.DATE_MODIFIED,
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.MEDIA_TYPE,
            MediaStore.Files.FileColumns.MIME_TYPE,
            MediaStore.Files.FileColumns.HEIGHT,
            MediaStore.Files.FileColumns.SIZE,
            MediaStore.Files.FileColumns.WIDTH
        )

        var selection =
            "(${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} OR ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}) ${if (isTrashed || isFavorites || showOnly != null) "" else "AND ${MediaStore.Files.FileColumns.BUCKET_ID} = ? "}AND ${MediaStore.Files.FileColumns.MIME_TYPE} != ?"

        if (showOnly != null) {
            if (showOnly.isEmpty()) {
                closure(listOf(), true, false)
                return
            }

            selection = "($selection) AND ${MediaStore.Files.FileColumns._ID} = ${showOnly.first()}"
            if (showOnly.count() > 1) {
                val builder = StringBuilder();
                builder.append(selection)
                for (id in showOnly) {
                    builder.append(" OR ${MediaStore.Files.FileColumns._ID} =  $id")
                }

                selection = builder.toString()
            }
        }

        val bundle = Bundle().apply {
            putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection)
            putStringArray(
                ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                if (isTrashed || isFavorites || showOnly != null) arrayOf("image/vnd.djvu") else arrayOf(
                    dir,
                    "image/vnd.djvu"
                )
            )
            putString(
                ContentResolver.QUERY_ARG_SQL_SORT_ORDER,
                "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC"
            )
            if (isTrashed) {
                putInt(MediaStore.QUERY_ARG_MATCH_TRASHED, MediaStore.MATCH_ONLY)
            } else if (isFavorites) {
                putInt(MediaStore.QUERY_ARG_MATCH_FAVORITE, MediaStore.MATCH_ONLY)
            }
        }

        context.contentResolver.query(
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
            projection,
            bundle,
            null
        )?.use { cursor ->
            val id = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
            val bucket_id = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.BUCKET_ID)
            val b_display_name =
                cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
            val date_modified =
                cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_MODIFIED)
            val media_type = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MEDIA_TYPE)
            val size = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)

            val media_height = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.HEIGHT)
            val media_width = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.WIDTH)
            val media_mime = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MIME_TYPE)

            if (!cursor.moveToFirst()) {
                closure(listOf(), true, false)
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

                    list.add(
                        DirectoryFile(
                            id = cursor.getLong(id),
                            bucketId = cursor.getString(bucket_id),
                            name = cursor.getString(b_display_name),
                            originalUri = uri.toString(),
                            lastModified = cursor.getLong(date_modified),
                            isVideo = cursor.getInt(media_type) == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO,
                            isGif = cursor.getString(media_mime) == "image/gif",
                            height = cursor.getLong(media_height),
                            width = cursor.getLong(media_width),
                            size = cursor.getInt(size).toLong()
                        )
                    )

                    if (list.count() == 40) {
                        closure(list.toList(), false, if (inRefreshAtEnd) !cursor.isLast else true)
                        list.clear()
                    }
                } while (
                    cursor.moveToNext()
                )

                if (list.isNotEmpty()) {
                    closure(list, false, !inRefreshAtEnd)
                }
            } catch (e: java.lang.Exception) {
                Log.e("refreshDirectoryFiles", "cursor block fail", e)
            }
        }
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
        saveToPinned: Boolean
    ): Pair<String, Long> {
        if (locker.exist(id)) {
            return Pair("", 0)
        }

        val thumb = if (network) Glide.with(context).asBitmap().load(uri).submit()
            .get() else context.contentResolver.loadThumbnail(uri, Size(320, 320), null)
        val stream = ByteArrayOutputStream()

        val scaled = thumb.scale(9, 8)

        val hash = diffHashFromThumb(scaled)

        thumb.compress(Bitmap.CompressFormat.JPEG, 80, stream)

        val path = locker.put(stream, id, saveToPinned)

        stream.reset()
        thumb.recycle()

        if (path == null) {
            return Pair("", 0)
        }

        return Pair(path, hash)
    }

    private suspend fun refreshMediastore(context: Context, galleryApi: GalleryApi) {
        val projection = arrayOf(
            MediaStore.Files.FileColumns.BUCKET_ID,
            MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME,
            MediaStore.Files.FileColumns.DATE_MODIFIED,
            MediaStore.Files.FileColumns.RELATIVE_PATH,
            MediaStore.Files.FileColumns.VOLUME_NAME,
            MediaStore.Files.FileColumns._ID
        )

        context.contentResolver.query(
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
            projection,
            "(${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} OR ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}) AND ${MediaStore.Files.FileColumns.MIME_TYPE} != ? AND ${MediaStore.Files.FileColumns.IS_TRASHED} = 0",
            arrayOf("image/vnd.djvu"),
            "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC"
        )?.use { cursor ->
            val id = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
            val bucket_id = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.BUCKET_ID)
            val b_display_name =
                cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME)
            val relative_path =
                cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.RELATIVE_PATH)
            val date_modified =
                cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_MODIFIED)
            val volume_name = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.VOLUME_NAME)

            val map = HashMap<String, Unit>()
            val list = mutableListOf<Directory>()

            if (!cursor.moveToFirst()) {
                CoroutineScope(coContext).launch {
                    galleryApi.updateDirectories(
                        listOf(),
                        inRefreshArg = false,
                        emptyArg = true
                    ) {}
                }.join()
                return@use
            }

            try {
                do {
                    val bucketId = cursor.getString(bucket_id)
                    if (bucketId == null || map.containsKey(bucketId)) {
                        continue
                    }

                    map[bucketId] = Unit

                    list.add(
                        Directory(
                            thumbFileId = cursor.getLong(id),
                            lastModified = cursor.getLong(date_modified),
                            bucketId = bucketId,
                            name = cursor.getString(b_display_name) ?: "Internal",
                            volumeName = cursor.getString(volume_name),
                            relativeLoc = cursor.getString(relative_path)
                        )
                    )

                    if (list.count() == 40) {
                        val copy = list.toList()
                        list.clear()

                        CoroutineScope(coContext).launch {
                            galleryApi.updateDirectories(
                                copy,
                                inRefreshArg = !cursor.isLast, emptyArg = false
                            ) {}
                        }.join()
                    }
                } while (
                    cursor.moveToNext()
                )

                if (list.isNotEmpty()) {
                    CoroutineScope(coContext).launch {
                        galleryApi.updateDirectories(
                            list,
                            inRefreshArg = false,
                            emptyArg = false
                        ) {}
                    }.join()
                }
            } catch (e: java.lang.Exception) {
                Log.e("refreshMediastore", "cursor block fail", e)
            }
        }
    }

    fun add(op: MoveOp) {
        scope.launch {
            channel.send(op)
        }
    }
}