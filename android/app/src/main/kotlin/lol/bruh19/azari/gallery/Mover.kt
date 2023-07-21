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
import java.util.Calendar
import kotlin.coroutines.CoroutineContext
import kotlin.io.path.Path
import kotlin.io.path.deleteIfExists
import kotlin.io.path.extension

internal class Mover(
    private val coContext: CoroutineContext,
    private val context: Context,
    private val galleryApi: GalleryApi
) {
    private val channel = Channel<MoveOp>()
    private val thumbnailsChannel = Channel<ThumbOp>(capacity = 8)
    private val scope = CoroutineScope(coContext + Dispatchers.IO)

    private val isLockedDirMux = Mutex()
    private val isLockedFilesMux = Mutex()

    init {
        scope.launch {
            val inProgress = mutableListOf<Job>()
            for (uris in thumbnailsChannel) {
                try {
                    val newScope = CoroutineScope(coContext + Dispatchers.IO)

                    if (inProgress.size == 8) {
                        inProgress.first().join()
                        inProgress.removeFirst()
                    }

                    inProgress.add(newScope.launch {
                        var res: ThumbnailId
                        try {
                            val uri = ContentUris.withAppendedId(
                                MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
                                uris.thumb
                            )

                            val (byt, hash) = getThumb(uri)
                            res = ThumbnailId(uris.thumb, byt, hash)
                        } catch (e: Exception) {
                            res = ThumbnailId(uris.thumb, transparentImage, 0)
                            Log.e("thumbnail coro", e.toString())
                        }

                        CoroutineScope(coContext).launch {
                            galleryApi.addThumbnails(
                                listOf(res),
                                uris.notify
                            ) {}
                        }.join()

                        uris.callback?.invoke()
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

                    CoroutineScope(coContext).launch {
                        galleryApi.notify(op.dir) {

                        }
                    }

                    Path(op.source).deleteIfExists()
                }
            }
        }
    }

    fun thumbnailsCallback(thumb: Long, callback: () -> Unit) {
        scope.launch {
            thumbnailsChannel.send(ThumbOp(thumb, callback))
        }
    }

    fun getThumbnailCallback(thumb: Long, result: MethodChannel.Result) {
        scope.launch {
            try {
                val (t, h) = getThumb(
                    ContentUris.withAppendedId(
                        MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
                        thumb
                    )
                )

                result.success(
                    mapOf<String, Any>(Pair("data", t), Pair("hash", h))
                )
            } catch (e: Exception) {
                result.success(
                    mapOf<String, Any>(Pair("data", transparentImage), Pair("hash", 0L))
                )
            }
        }
    }


    fun notifyGallery() {
        CoroutineScope(coContext).launch {
            galleryApi.notify(null) {
            }
        }
    }

    fun refreshFiles(dirId: String, isTrashed: Boolean = false) {
        if (isLockedFilesMux.isLocked) {
            return
        }

        val time = Calendar.getInstance().time.time

        scope.launch {
            if (!isLockedFilesMux.tryLock()) {
                return@launch
            }

            refreshDirectoryFiles(dirId, context, time, isTrashed = isTrashed)

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

            refreshMediastore(context, galleryApi)

            isLockedDirMux.unlock()
        }
    }

    private suspend fun refreshDirectoryFiles(
        dir: String,
        context: Context,
        time: Long,
        isTrashed: Boolean
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

        val selection =
            "(${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} OR ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}) ${if (isTrashed) "" else "AND ${MediaStore.Files.FileColumns.BUCKET_ID} = ? "}AND ${MediaStore.Files.FileColumns.MIME_TYPE} != ?"

        val bundle = Bundle().apply {
            putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection)
            putStringArray(
                ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                if (isTrashed) arrayOf("image/vnd.djvu") else arrayOf(dir, "image/vnd.djvu")
            )
            putString(
                ContentResolver.QUERY_ARG_SQL_SORT_ORDER,
                "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC"
            )
            if (isTrashed) {
                putInt(MediaStore.QUERY_ARG_MATCH_TRASHED, MediaStore.MATCH_ONLY)
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
                CoroutineScope(coContext).launch {
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
                        val copy = list.toList()
                        list.clear()

                        CoroutineScope(coContext).launch {
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
                    CoroutineScope(coContext).launch {
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

    private fun getThumb(uri: Uri): Pair<ByteArray, Long> {
        val thumb = context.contentResolver.loadThumbnail(uri, Size(320, 320), null)
        val stream = ByteArrayOutputStream()

        val scaled = thumb.scale(9, 8)
        var hash: Long = 0
        val grayscale = List(8) { i ->
            List(9) { j ->
                scaled.getColor(j, i).luminance()
            }
        }

        var idx = 0
        for (l in grayscale) {
            for (i in 0 until l.size - 1) {
                if (l[i] < l[i + 1]) {
                    hash = hash or 1 shl (64 - idx - 1)
                }
                idx++
            }
        }

        thumb.compress(Bitmap.CompressFormat.JPEG, 80, stream)

        val bytes = stream.toByteArray()

        stream.reset()
        thumb.recycle()

        return Pair(bytes, hash)
    }

    fun loadThumb(id: Long) {
        scope.launch {
            thumbnailsChannel.send(ThumbOp(id, null, true))
        }
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

                //map.values.
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

        val version = MediaStore.getVersion(
            context,
            MediaStore.getVolumeName(MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
        )

        CoroutineScope(coContext).launch {
            galleryApi.finish(
                version
            ) {}
        }.join()
    }

//    private fun filterAndSendThumbs(thumbs: List<Long>, galleryApi: GalleryApi) {
//        CoroutineScope(coContext).launch {
//            galleryApi.thumbsExist(thumbs) {
//                if (it.isEmpty()) {
//                    return@thumbsExist
//                }
//                scope.launch {
//                    thumbnailsChannel.send(ThumbOp(it, null))
//                }
//            }
//        }
//    }

    fun add(op: MoveOp) {
        scope.launch {
            channel.send(op)
        }
    }
}