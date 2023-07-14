// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery

import android.content.ContentUris
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.provider.MediaStore
import android.util.Log
import android.util.Size
import android.webkit.MimeTypeMap
import androidx.documentfile.provider.DocumentFile
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
    private val thumbnailsChannel = Channel<ThumbOp>(capacity = 2)
    private val scope = CoroutineScope(coContext + Dispatchers.IO)

    private val isLockedDirMux = Mutex()
    private val isLockedFilesMux = Mutex()

    init {
        scope.launch {
            for (uris in thumbnailsChannel) {
                val newScope = CoroutineScope(coContext + Dispatchers.IO)

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
                                            copy
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

                            CoroutineScope(coContext).launch {
                                galleryApi.addThumbnails(
                                    thumbs,
                                    uris.notify
                                ) {}
                            }.join()
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

                    CoroutineScope(coContext).launch {
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
        CoroutineScope(coContext).launch {
            galleryApi.notify {

            }
        }
    }

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

            refreshMediastore(context, galleryApi)

            isLockedDirMux.unlock()
        }
    }

    private suspend fun refreshDirectoryFiles(
        dir: String,
        context: Context,
        time: Long,
    ) {
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
                    //filterAndSendThumbs(list.map { it.id })

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

    private fun getThumb(uri: Uri): ByteArray {
        val thumb = context.contentResolver.loadThumbnail(uri, Size(320, 320), null)
        //Glide.with(context).asBitmap().load(uri).apply(RequestOptions.sizeMultiplierOf(0.1f)).thumbnail().
        val stream = ByteArrayOutputStream()

        thumb.compress(Bitmap.CompressFormat.JPEG, 50, stream)

        val bytes = stream.toByteArray()

        stream.reset()
        thumb.recycle()

        return bytes
    }

    fun loadThumb(id: Long) {
        scope.launch {
            thumbnailsChannel.send(ThumbOp(listOf(id), null, true))
        }
    }

    private suspend fun refreshMediastore(context: Context, galleryApi: GalleryApi) {
        val projection = arrayOf(
            MediaStore.Files.FileColumns.BUCKET_ID,
            MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME,
            MediaStore.Files.FileColumns.DATE_MODIFIED,
            MediaStore.Files.FileColumns.RELATIVE_PATH,
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
            val relative_path =
                cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.RELATIVE_PATH)
            val date_modified =
                cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_MODIFIED)

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

                    val idval = cursor.getLong(id)
                    val lastmodifval = cursor.getLong(date_modified)
                    val nameval = cursor.getString(b_display_name) ?: "Internal"
                    val relativepathval = cursor.getString(relative_path)

                    list.add(
                        Directory(
                            thumbFileId = idval,
                            lastModified = lastmodifval,
                            bucketId = bucketId,
                            name = nameval,
                            relativeLoc = relativepathval
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

    private fun filterAndSendThumbs(thumbs: List<Long>, galleryApi: GalleryApi) {
        CoroutineScope(coContext).launch {
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