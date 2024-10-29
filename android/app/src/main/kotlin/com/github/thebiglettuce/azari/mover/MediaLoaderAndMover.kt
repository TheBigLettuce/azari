// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package com.github.thebiglettuce.azari.mover

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import android.util.Size
import android.webkit.MimeTypeMap
import androidx.core.graphics.get
import androidx.core.graphics.scale
import androidx.documentfile.provider.DocumentFile
import com.bumptech.glide.Glide
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import com.github.thebiglettuce.azari.generated.Directory
import com.github.thebiglettuce.azari.generated.DirectoryFile
import okio.FileSystem
import okio.Path.Companion.toPath
import okio.buffer
import okio.sink
import okio.use
import java.io.ByteArrayOutputStream
import java.io.FileOutputStream
import java.util.Calendar
import kotlin.io.path.Path
import kotlin.io.path.deleteIfExists
import kotlin.io.path.extension

class MediaLoaderAndMover(private val context: Context) {
    private val cap = if (Runtime.getRuntime().availableProcessors() == 1) {
        1
    } else {
        Runtime.getRuntime().availableProcessors() - 1
    }

    private val moveChannel = Channel<MoveOp>()
    private val thumbnailsChannel = Channel<ThumbOp>(capacity = cap)

    internal val scope = CoroutineScope(Dispatchers.IO)
    internal val uiScope = CoroutineScope(Dispatchers.Main)

    private val isLockedDirMux = Mutex()
    private val isLockedFilesMux = Mutex()
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
                        inProgress.removeFirst()
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
                    inProgress.removeFirst()
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

    fun refreshFavorites(
        ids: List<Long>,
        sortingMode: FilesSortingMode,
        sendMedia: SendMedia,
        closure: () -> Unit,
    ) {
        val time = Calendar.getInstance().time.time

        scope.launch {
            isLockedFilesMux.lock()

            loadMedia(
                listOf(),
                context,
                inRefreshAtEnd = true,
                type = LoadMediaType.Normal,
                limit = 0,
                showOnly = ids,
                sortingMode = sortingMode,
            ) { content, notFound, empty, inRefresh ->
                sendMedia(scope, uiScope, "favorites", time, content, notFound, empty, inRefresh)
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

    fun refreshFilesDirectly(
        dir: String = "",
        type: LoadMediaType = LoadMediaType.Normal,
        limit: Long, sortingMode: FilesSortingMode,
        closure: suspend (content: List<DirectoryFile>, notFound: List<Long>, empty: Boolean, inRefresh: Boolean) -> Unit,
    ) {
        scope.launch {
            loadMedia(
                listOf(dir),
                context,
                inRefreshAtEnd = true,
                type = type,
                limit = limit,
                sortingMode = sortingMode,
                closure = closure,
            )
        }
    }

    fun filesDirectly(
        ids: List<Long>,
        closure: suspend (content: List<DirectoryFile>, notFound: List<Long>, empty: Boolean, inRefresh: Boolean) -> Unit,
    ) {
        scope.launch {
            loadMedia(
                listOf(),
                context,
                inRefreshAtEnd = true,
                type = LoadMediaType.Normal,
                showOnly = ids,
                limit = 0,
                sortingMode = FilesSortingMode.None,
                closure = closure,
            )
        }
    }

    fun filesSearchByNameDirectly(
        name: String,
        limit: Long,
        closure: (List<DirectoryFile>) -> Unit,
    ) {
//        val time = Calendar.getInstance().time.time

        scope.launch {
//            isLockedFilesMux.lock()

            filterMedia(
                context,
                name,
                limit,
                sortingMode = FilesSortingMode.None
            ) { content, notFound, empty, inRefresh ->
                closure(content)
            }

//            isLockedFilesMux.unlock()
        }
    }

    fun refreshFiles(
        dirId: String,
        inRefreshAtEnd: Boolean,
        type: LoadMediaType,
        limit: Long,
        sortingMode: FilesSortingMode,
        sendMedia: SendMedia,
    ) {
        val time = Calendar.getInstance().time.time

        scope.launch {
            isLockedFilesMux.lock()

            loadMedia(
                listOf(dirId),
                context,
                inRefreshAtEnd = inRefreshAtEnd,
                type = type,
                limit = limit,
                sortingMode = sortingMode,
            ) { content, notFound, empty, inRefresh ->
                sendMedia(scope, uiScope, dirId, time, content, notFound, empty, inRefresh)
            }

            isLockedFilesMux.unlock()
        }
    }

    fun refreshFilesMultiple(
        dirs: List<String>, sortingMode: FilesSortingMode,
        sendMedia: SendMedia,
    ) {
        if (dirs.count() == 1) {
            refreshFiles(
                dirs.first(),
                inRefreshAtEnd = true,
                type = LoadMediaType.Normal,
                limit = 0,
                sortingMode = sortingMode,
                sendMedia = sendMedia,
            )

            return
        }

        val time = Calendar.getInstance().time.time

        scope.launch {
            isLockedFilesMux.lock()

            loadMedia(
                dirs,
                context,
                inRefreshAtEnd = true,
                type = LoadMediaType.Normal,
                limit = 0,
                sortingMode = sortingMode,
            ) { content, notFound, empty, inRefresh ->
                sendMedia(scope, uiScope, dirs.last(), time, content, notFound, empty, inRefresh)
            }

            isLockedFilesMux.unlock()
        }
    }

    fun thumbCacheSize(res: MethodChannel.Result, fromPinned: Boolean) {
        scope.launch {
            res.success(locker.count(fromPinned))
        }
    }

    fun refreshGallery(sendDirectories: SendDirectories) {
        if (isLockedDirMux.isLocked) {
            return
        }

        scope.launch {
            if (!isLockedDirMux.tryLock()) {
                return@launch
            }

            refreshDirectories(context, sendDirectories)

            isLockedDirMux.unlock()
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

    private suspend fun filterMedia(
        context: Context,
        name: String,
        limit: Long,
        sortingMode: FilesSortingMode,
        closure: suspend (content: List<DirectoryFile>, notFound: List<Long>, empty: Boolean, inRefresh: Boolean) -> Unit,
    ) {
        val projection = arrayOf(
            MediaStore.Files.FileColumns.BUCKET_ID,
            MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME,
            MediaStore.Files.FileColumns.DISPLAY_NAME,
            MediaStore.Files.FileColumns.DATE_MODIFIED,
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.MEDIA_TYPE,
            MediaStore.Files.FileColumns.MIME_TYPE,
            MediaStore.Files.FileColumns.HEIGHT,
            MediaStore.Files.FileColumns.SIZE,
            MediaStore.Files.FileColumns.WIDTH
        )

        val selection =
            "(${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} OR ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}) AND ${MediaStore.Files.FileColumns.MIME_TYPE} != ? AND ${MediaStore.Files.FileColumns.DISPLAY_NAME} LIKE ?"

        val bundle = Bundle().apply {
            putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection)
            putStringArray(
                ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                arrayOf("image/vnd.djvu", "$name%"),
            )
            putString(
                ContentResolver.QUERY_ARG_SQL_SORT_ORDER,
                if (sortingMode == FilesSortingMode.None) "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC" else "${MediaStore.Files.FileColumns.SIZE} DESC"
            )
            if (limit != 0L) {
                putInt(ContentResolver.QUERY_ARG_LIMIT, limit.toInt())
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
            val bucket_name =
                cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME)
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
                closure(listOf(), listOf(), true, false)
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

                    val id = cursor.getLong(id)

                    list.add(
                        DirectoryFile(
                            id = id,
                            bucketId = cursor.getString(bucket_id),
                            name = cursor.getString(b_display_name),
                            originalUri = uri.toString(),
                            lastModified = cursor.getLong(date_modified),
                            isVideo = cursor.getInt(media_type) == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO,
                            isGif = cursor.getString(media_mime) == "image/gif",
                            height = cursor.getLong(media_height),
                            width = cursor.getLong(media_width),
                            size = cursor.getInt(size).toLong(),
                            bucketName = cursor.getString(bucket_name) ?: "",
                        )
                    )

                    if (limit == 0L && list.count() == 40) {
                        closure(
                            list.toList(),
                            listOf(),
                            false, true
                        )
                        list.clear()
                    }
                } while (
                    cursor.moveToNext()
                )

                if (limit == 0L) {
                    closure(
                        list,
                        listOf(),
                        false,
                        list.isNotEmpty()
                    )
                    if (list.isNotEmpty()) {
                        closure(
                            listOf(),
                            listOf(),
                            false, false
                        )
                    }
                } else {
                    closure(
                        list,
                        listOf(),
                        list.isEmpty(), false,
                    )
                }
            } catch (e: java.lang.Exception) {
                Log.e("filterMedia", "cursor block fail", e)
            }
        }
    }

    private suspend fun loadMedia(
        dirs: List<String>,
        context: Context,
        inRefreshAtEnd: Boolean,
        type: LoadMediaType,
        showOnly: List<Long>? = null,
        limit: Long,
        sortingMode: FilesSortingMode,
        closure: suspend (content: List<DirectoryFile>, notFound: List<Long>, empty: Boolean, inRefresh: Boolean) -> Unit,
    ) {
        if (type == LoadMediaType.Trashed) {
            if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.R) {
                closure(listOf(), listOf(), true, false)
                return
            }
        }

        val projection = arrayOf(
            MediaStore.Files.FileColumns.BUCKET_ID,
            MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME,
            MediaStore.Files.FileColumns.DISPLAY_NAME,
            MediaStore.Files.FileColumns.DATE_MODIFIED,
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.MEDIA_TYPE,
            MediaStore.Files.FileColumns.MIME_TYPE,
            MediaStore.Files.FileColumns.HEIGHT,
            MediaStore.Files.FileColumns.SIZE,
            MediaStore.Files.FileColumns.WIDTH
        )

        val s = StringBuilder()

        if (dirs.size == 1) {
            s.append("${MediaStore.Files.FileColumns.BUCKET_ID} = ? ")
        } else {
            s.append("(")
            s.append("${MediaStore.Files.FileColumns.BUCKET_ID} = ?")

            for (i in 1..<dirs.size) {
                s.append(" OR ")
                s.append("${MediaStore.Files.FileColumns.BUCKET_ID} = ?")
            }
            s.append(") ")
        }

        var selection =
            "(${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} OR ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}) ${if (type != LoadMediaType.Normal || showOnly != null) "" else "AND $s"}AND ${MediaStore.Files.FileColumns.MIME_TYPE} != ?"

        if (showOnly != null) {
            if (showOnly.isEmpty()) {
                closure(listOf(), listOf(), true, false)
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
                if (type != LoadMediaType.Normal || showOnly != null) arrayOf("image/vnd.djvu") else dirs.toTypedArray() + arrayOf(
                    "image/vnd.djvu"
                )
            )
            putString(
                ContentResolver.QUERY_ARG_SQL_SORT_ORDER,
                if (sortingMode == FilesSortingMode.None) "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC" else "${MediaStore.Files.FileColumns.SIZE} DESC"
            )
            if (type == LoadMediaType.Trashed) {
                putInt(MediaStore.QUERY_ARG_MATCH_TRASHED, MediaStore.MATCH_ONLY)
            }

            if (limit != 0L) {
                putInt(ContentResolver.QUERY_ARG_LIMIT, limit.toInt())
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
            val bucket_name =
                cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME)
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
                closure(listOf(), showOnly ?: listOf(), true, false)
                return@use
            }

            try {
                val showOnlyMap =
                    showOnly?.fold<Long, MutableMap<Long, Boolean>>(mutableMapOf()) { map, e ->
                        map[e] = false;

                        return@fold map;
                    }

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

                    val id = cursor.getLong(id)

                    list.add(
                        DirectoryFile(
                            id = id,
                            bucketId = cursor.getString(bucket_id),
                            name = cursor.getString(b_display_name),
                            originalUri = uri.toString(),
                            lastModified = cursor.getLong(date_modified),
                            isVideo = cursor.getInt(media_type) == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO,
                            isGif = cursor.getString(media_mime) == "image/gif",
                            height = cursor.getLong(media_height),
                            width = cursor.getLong(media_width),
                            size = cursor.getInt(size).toLong(),
                            bucketName = cursor.getString(bucket_name) ?: "",
                        )
                    )

                    showOnlyMap?.put(id, true)

                    if (limit == 0L && list.count() == 40) {
                        closure(
                            list.toList(),
                            listOf(),
                            false, true
                        )
                        list.clear()
                    }
                } while (
                    cursor.moveToNext()
                )

                if (limit == 0L) {
                    closure(
                        list,
                        if (list.isEmpty()) listNotContainsId(showOnlyMap) else listOf(),
                        false,
                        !inRefreshAtEnd && list.isNotEmpty()
                    )
                    if (list.isNotEmpty()) {
                        closure(
                            listOf(),
                            listNotContainsId(showOnlyMap),
                            false, !inRefreshAtEnd
                        )
                    }
                } else {
                    closure(
                        list,
                        listNotContainsId(showOnlyMap),
                        list.isEmpty(), !inRefreshAtEnd
                    )
                }
            } catch (e: java.lang.Exception) {
                Log.e("refreshDirectoryFiles", "cursor block fail", e)
            }
        }
    }

    private fun listNotContainsId(map: Map<Long, Boolean>?): List<Long> {
        if (map == null) {
            return listOf()
        }

        return map.entries.dropWhile { it.value }.map { it.key }
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
            if (network) Glide.with(context)
                .asBitmap().disallowHardwareConfig().load(uri).submit()
                .get() else if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.Q) Glide.with(context)
                .asBitmap().disallowHardwareConfig().load(uri).override(320, 320).submit()
                .get() else context.contentResolver.loadThumbnail(uri, Size(320, 320), null)
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

    private suspend fun refreshDirectories(context: Context, sendCallback: SendDirectories) {
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
            "(${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} OR ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}) AND ${MediaStore.Files.FileColumns.MIME_TYPE} != ? ${if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) "AND ${MediaStore.Files.FileColumns.IS_TRASHED} = 0" else ""}",
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
            val volume_name = cursor.getColumnIndexOrThrow(
                MediaStore.Files.FileColumns.VOLUME_NAME
            )

            val map = HashMap<String, Unit>()
            val resMap = mutableMapOf<String, Directory>()

            if (!cursor.moveToFirst()) {
                sendCallback(scope, uiScope, mapOf(), false, true)
                return@use
            }

            try {
                do {
                    val bucketId = cursor.getString(bucket_id)
                    if (bucketId == null || map.containsKey(bucketId)) {
                        continue
                    }

                    map[bucketId] = Unit

                    resMap[bucketId] = Directory(
                        thumbFileId = cursor.getLong(id),
                        lastModified = cursor.getLong(date_modified),
                        bucketId = bucketId,
                        name = cursor.getString(b_display_name) ?: "Internal",
                        volumeName = if (volume_name == null) "" else cursor.getString(volume_name),
                        relativeLoc = cursor.getString(relative_path)
                    )


                    if (resMap.count() == 40) {
                        val copy = resMap.toMap()
                        resMap.clear()

                        val toContinue = sendCallback(scope, uiScope, copy, true, false)
                        if (!toContinue) {
                            return@use
                        }
                    }
                } while (
                    cursor.moveToNext()
                )

                sendCallback(scope, uiScope, resMap, resMap.isNotEmpty(), false)
                if (resMap.isNotEmpty()) {
                    sendCallback(scope, uiScope, mapOf(), false, false)
                }
            } catch (e: java.lang.Exception) {
                Log.e("refreshMediastore", "cursor block fail", e)
            }
        }
    }

    fun add(op: MoveOp) {
        scope.launch {
            moveChannel.send(op)
        }
    }

    companion object Enums {
        enum class LoadMediaType {
            Trashed, Latest, Normal;
        }

        enum class FilesSortingMode {
            None, Size;

            companion object {
                fun fromDartInt(int: Int): FilesSortingMode {
                    return when (int) {
                        1 -> Size
                        else -> None
                    }
                }
            }
        }
    }
}