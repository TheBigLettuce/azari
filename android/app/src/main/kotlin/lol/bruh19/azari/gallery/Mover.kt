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
    private val cap = if (Runtime.getRuntime().availableProcessors() == 1) {
        1
    } else {
        Runtime.getRuntime().availableProcessors() - 1
    }
    private val thumbnailsChannel = Channel<ThumbOp>(capacity = cap)
    private val scope = CoroutineScope(coContext + Dispatchers.IO)

    private val isLockedDirMux = Mutex()
    private val isLockedFilesMux = Mutex()

    init {
        scope.launch {
            val inProgress = mutableListOf<Job>()
            for (uris in thumbnailsChannel) {
                try {
                    val newScope = CoroutineScope(Dispatchers.IO)

                    if (inProgress.size == cap) {
                        inProgress.first().join()
                        inProgress.removeFirst()
                    }

                    inProgress.add(newScope.launch {
                        var res: Pair<ByteArray, Long>
                        try {
                            val uri = ContentUris.withAppendedId(
                                MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
                                uris.thumb
                            )

                            res = getThumb(uri)
                        } catch (e: Exception) {
                            res = Pair(transparentImage, 0)
                            Log.e("thumbnail coro", e.toString())
                        }

                        uris.callback.invoke(res.first, res.second)
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

    fun getThumbnailCallback(thumb: Long, result: MethodChannel.Result) {
        scope.launch {
            thumbnailsChannel.send(ThumbOp(thumb) { byt, hash ->
                result.success(mapOf<String, Any>(Pair("data", byt), Pair("hash", hash)))
            })
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

    fun refreshFavorites(ids: List<Long>) {
        if (isLockedFilesMux.isLocked) {
            return
        }

        val time = Calendar.getInstance().time.time

        scope.launch {
            if (!isLockedFilesMux.tryLock()) {
                return@launch
            }

            refreshDirectoryFiles("favorites", context, time, inRefreshAtEnd = true, showOnly = ids)

            isLockedFilesMux.unlock()
        }
    }

    fun refreshFiles(dirId: String, inRefreshAtEnd: Boolean, isTrashed: Boolean = false) {
        val time = Calendar.getInstance().time.time

        scope.launch {
            isLockedFilesMux.lock()

            refreshDirectoryFiles(
                dirId,
                context,
                time,
                inRefreshAtEnd = inRefreshAtEnd,
                isTrashed = isTrashed
            )

            isLockedFilesMux.unlock()
        }
    }

    suspend fun refreshFilesMultiple(dirs: List<String>) {
        val time = Calendar.getInstance().time.time

        isLockedFilesMux.lock()
        for ((i, d) in dirs.withIndex()) {
            refreshDirectoryFiles(d, context, time, inRefreshAtEnd = i == dirs.size - 1)
        }
        isLockedFilesMux.unlock()
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

    fun trashThumbId(context: Context): Long? {
        val projection = arrayOf(
            MediaStore.Files.FileColumns._ID,
        )

        val bundle = Bundle().apply {
            putString(
                ContentResolver.QUERY_ARG_SQL_SELECTION,
                "(${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} OR ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}) AND  ${MediaStore.Files.FileColumns.MIME_TYPE} != ?"
            )
            putInt(ContentResolver.QUERY_ARG_LIMIT, 1)
            putStringArray(ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS, arrayOf("image/vnd.djvu"))
            putString(
                ContentResolver.QUERY_ARG_SQL_SORT_ORDER,
                "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC"
            )
            putInt(MediaStore.QUERY_ARG_MATCH_TRASHED, MediaStore.MATCH_ONLY)
        }

        var result: Long? = null;

        context.contentResolver.query(
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
            projection,
            bundle,
            null
        )?.use {
            if (!it.moveToFirst()) {
                return@use
            }

            result = it.getLong(0)
        }

        return result
    }

    private suspend fun refreshDirectoryFiles(
        dir: String,
        context: Context,
        time: Long,
        inRefreshAtEnd: Boolean,
        isTrashed: Boolean = false,
        showOnly: List<Long>? = null
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
            "(${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} OR ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}) ${if (isTrashed || showOnly != null) "" else "AND ${MediaStore.Files.FileColumns.BUCKET_ID} = ? "}AND ${MediaStore.Files.FileColumns.MIME_TYPE} != ?"

        if (showOnly != null) {
            if (showOnly.isEmpty()) {
                CoroutineScope(coContext).launch {
                    galleryApi.updatePictures(
                        listOf(),
                        dir,
                        time,
                        inRefreshArg = false,
                        emptyArg = true
                    ) {}
                }.join()
                return
            }

            selection = "($selection) AND ${MediaStore.Files.FileColumns._ID} = ${showOnly.first()}"
            if (showOnly.size > 1) {
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
                if (isTrashed || showOnly != null) arrayOf("image/vnd.djvu") else arrayOf(
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
                                inRefreshArg = if (inRefreshAtEnd) !cursor.isLast else true,
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
                            inRefreshArg = !inRefreshAtEnd,
                            emptyArg = false
                        ) {}
                    }.join()
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
            for (i in 0 until l.size - 1) {
                if (l[i] < l[i + 1]) {
                    hash = hash or 1 shl (64 - idx - 1)
                }
                idx++
            }
        }

        return hash
    }

    private fun getThumb(uri: Uri): Pair<ByteArray, Long> {
        val thumb = context.contentResolver.loadThumbnail(uri, Size(320, 320), null)
        val stream = ByteArrayOutputStream()

        val scaled = thumb.scale(9, 8)

        val hash = diffHashFromThumb(scaled)

        thumb.compress(Bitmap.CompressFormat.JPEG, 80, stream)

        val bytes = stream.toByteArray()

        stream.reset()
        thumb.recycle()

        return Pair(bytes, hash)
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

    fun add(op: MoveOp) {
        scope.launch {
            channel.send(op)
        }
    }
}

// these are written from github.com/corona10/goimagehash impl
// goimagehash is BSD 2-Clause License

private fun medianOfPixelsFast64(grayscale: List<Double>): Double {
    val tmp = grayscale.toMutableList()
    val pos = tmp.size / 2

    return quickSelectMedian(tmp, 0, tmp.size - 1, pos)
}

private fun quickSelectMedian(sequence: MutableList<Double>, low1: Int, hi1: Int, k: Int): Double {
    if (low1 == hi1) {
        return sequence[k]
    }

    var hi = hi1
    var low = low1
    while (low < hi) {
        val pivot = low / 2 + hi / 2
        val pivotValue = sequence[pivot]
        var storeIndx = low
        var prevhi = sequence[hi]
        val prevpivot = sequence[pivot]
        sequence[pivot] = prevhi
        sequence[hi] = prevpivot

        for (i in low until hi) {
            if (sequence[i] < pivotValue) {
                val previdx = sequence[storeIndx]
                val previ = sequence[i]
                sequence[storeIndx] = previ
                sequence[i] = previdx
                storeIndx++
            }
        }

        prevhi = sequence[hi]
        val previdx = sequence[storeIndx]
        sequence[hi] = previdx
        sequence[storeIndx] = prevhi

        if (k <= storeIndx) {
            hi = storeIndx
        } else {
            low = storeIndx + 1
        }
    }

    if (sequence.size % 2 == 0) {
        return sequence[k - 1] / 2 + sequence[k] / 2
    }

    return sequence[k]
}

private fun pixel2Gray(r: Float, g: Float, b: Float): Double {
    return 0.299 * r / 257 + 0.587 * g / 257 + 0.114 * b / 256
}

private fun rgb2Gray(pixels: Bitmap): MutableList<Double> {
    val ret = MutableList(pixels.height * pixels.width) {
        0.0
    }

    for (i in 0 until 64) {
        for (j in 0 until 64) {
            val color = pixels.getColor(j, i)
            ret[j + (i * 64)] = pixel2Gray(color.red(), color.green(), color.blue())
        }
    }

    return ret
}

private fun DCT2DFast64(pixels: MutableList<Double>): List<Double> {
    for (i in 0 until 64) {
        forwardDCT64(pixels.subList(i * 64, (i * 64) + 64))
    }

    val row = MutableList(64) { 0.0 }
    val flattens = MutableList(64) { 0.0 }

    for (i in 0 until 8) {
        for (j in 0 until 64) {
            row[j] = pixels[64 * j + i]
        }

        forwardDCT64(row)

        for (j in 0 until 8) {
            flattens[8 * j + i] = row[j]
        }
    }

    return flattens
}


// forwardDCT64 function returns result of DCT-II.
// DCT type II, unscaled. Algorithm by Byeong Gi Lee, 1984.
// Static implementation by Evan Oberholster, 2022.
private fun forwardDCT64(input: MutableList<Double>) {
    val temp = MutableList(64) { 0.0 }
    for (i in 0 until 32) {
        val (x, y) = Pair(input[i], input[63 - i])
        temp[i] = x + y
        temp[i + 32] = (x - y) / dct64[i]
    }

    forwardDCT32(temp.subList(0, 32))
    forwardDCT32(temp.subList(32, temp.size))

    for (i in 0 until 32 - 1) {
        input[i * 2 + 0] = temp[i]
        input[i * 2 + 1] = temp[i + 32] + temp[i + 32 + 1]
    }

    input[62] = temp[31]
    input[63] = temp[63]
}

private fun forwardDCT32(input: MutableList<Double>) {
    val temp = MutableList(32) { 0.0 }
    for (i in 0 until 16) {
        val (x, y) = Pair(input[i], input[31 - i])
        temp[i] = x + y
        temp[i + 16] = (x - y) / dct32[i]
    }

    forwardDCT16(temp.subList(0, 16))
    forwardDCT16(temp.subList(16, temp.size))

    for (i in 0 until 16 - 1) {
        input[i * 2 + 0] = temp[i]
        input[i * 2 + 1] = temp[i + 16] + temp[i + 16 + 1]
    }

    input[30] = temp[15]
    input[31] = temp[31]
}

private fun forwardDCT16(input: MutableList<Double>) {
    val temp = MutableList(16) { 0.0 }
    for (i in 0 until 8) {
        val (x, y) = Pair(input[i], input[15 - i])
        temp[i] = x + y
        temp[i + 8] = (x - y) / dct16[i]
    }

    forwardDCT8(temp.subList(0, 8))
    forwardDCT8(temp.subList(8, temp.size))

    for (i in 0 until 8 - 1) {
        input[i * 2 + 0] = temp[i]
        input[i * 2 + 1] = temp[i + 8] + temp[i + 8 + 1]
    }

    input[14] = temp[7]
    input[15] = temp[15]
}

private fun forwardDCT8(input: MutableList<Double>) {
    val (a, b) = Pair(Array(4) { 0.0 }, Array(4) { 0.0 })

    val (x0, y0) = Pair(input[0], input[7])
    val (x1, y1) = Pair(input[1], input[6])
    val (x2, y2) = Pair(input[2], input[5])
    val (x3, y3) = Pair(input[3], input[4])

    a[0] = x0 + y0
    a[1] = x1 + y1
    a[2] = x2 + y2
    a[3] = x3 + y3
    b[0] = (x0 - y0) / 1.9615705608064609
    b[1] = (x1 - y1) / 1.6629392246050907
    b[2] = (x2 - y2) / 1.1111404660392046
    b[3] = (x3 - y3) / 0.3901806440322566

    forwardDCT4(a)
    forwardDCT4(b)

    input[0] = a[0]
    input[1] = b[0] + b[1]
    input[2] = a[1]
    input[3] = b[1] + b[2]
    input[4] = a[2]
    input[5] = b[2] + b[3]
    input[6] = a[3]
    input[7] = b[3]
}

private fun forwardDCT4(input: Array<Double>) {
    val (x0, y0) = Pair(input[0], input[3])
    val (x1, y1) = Pair(input[1], input[2])

    var t0 = x0 + y0
    var t1 = x1 + y1
    var t2 = (x0 - y0) / 1.8477590650225735
    var t3 = (x1 - y1) / 0.7653668647301797

    var (x, y) = Pair(t0, t1)
    t0 += t1
    t1 = (x - y) / 1.4142135623730951

    x = t2
    y = t3

    t2 += t3
    t3 = (x - y) / 1.4142135623730951

    input[0] = t0
    input[1] = t2 + t3
    input[2] = t1
    input[3] = t3
}

val dct64 = listOf(
    1.9993976373924083,
    1.9945809133573804,
    1.9849590691974202,
    1.9705552847778824,
    1.9514042600770571,
    1.9275521315908797,
    1.8990563611860733,
    1.8659855976694777,
    1.8284195114070614,
    1.7864486023910306,
    1.7401739822174227,
    1.6897071304994142,
    1.6351696263031674,
    1.5766928552532127,
    1.5144176930129691,
    1.448494165902934,
    1.3790810894741339,
    1.3063456859075537,
    1.2304631811612539,
    1.151616382835691,
    1.0699952397741948,
    0.9857963844595683,
    0.8992226593092132,
    0.8104826280099796,
    0.7197900730699766,
    0.627363480797783,
    0.5334255149497968,
    0.43820248031373954,
    0.3419237775206027,
    0.24482135039843256,
    0.1471291271993349,
    0.049082457045824535
)


val dct32 = listOf(
    1.9975909124103448,
    1.978353019929562,
    1.9400625063890882,
    1.8830881303660416,
    1.8079785862468867,
    1.7154572200005442,
    1.6064150629612899,
    1.4819022507099182,
    1.3431179096940369,
    1.191398608984867,
    1.0282054883864435,
    0.8551101868605644,
    0.6737797067844401,
    0.48596035980652796,
    0.2934609489107235,
    0.09813534865483627
)

val dct16 = listOf(
    1.9903694533443936,
    1.9138806714644176,
    1.76384252869671,
    1.546020906725474,
    1.2687865683272912,
    0.9427934736519956,
    0.5805693545089246,
    0.19603428065912154
)