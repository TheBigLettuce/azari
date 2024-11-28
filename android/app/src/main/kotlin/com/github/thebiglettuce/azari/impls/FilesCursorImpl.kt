// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package com.github.thebiglettuce.azari.impls

import android.content.ContentResolver
import android.content.ContentUris
import android.database.Cursor
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import com.github.thebiglettuce.azari.App
import com.github.thebiglettuce.azari.generated.DirectoryFile
import com.github.thebiglettuce.azari.generated.FilesCursor
import com.github.thebiglettuce.azari.generated.FilesCursorType
import com.github.thebiglettuce.azari.generated.FilesSortingMode
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

class FilesCursorImpl(private val appContext: App, private val scope: CoroutineScope) :
    FilesCursor {
    private val liveInstances: MutableMap<String, FilesCursorState?> = mutableMapOf()

    private val projection = arrayOf(
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

    private var i: Long = 0L

    override fun acquire(
        directories: List<String>,
        type: FilesCursorType,
        sortingMode: FilesSortingMode,
        limit: Long,
    ): String {
        i += 1
        val token = i.toString()

        Log.i("FilesCursorImpl", "acquire, token: $token")

        if (type == FilesCursorType.TRASHED && (Build.VERSION.SDK_INT <= Build.VERSION_CODES.R)) {
            liveInstances[token] = null
            return token
        }

        val s = StringBuilder()

        if (directories.size == 1) {
            s.append("${MediaStore.Files.FileColumns.BUCKET_ID} = ? ")
        } else {
            s.append("(")
            s.append("${MediaStore.Files.FileColumns.BUCKET_ID} = ?")

            for (i in 1..<directories.size) {
                s.append(" OR ")
                s.append("${MediaStore.Files.FileColumns.BUCKET_ID} = ?")
            }
            s.append(") ")
        }

        var selection =
            "(${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} OR ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}) ${if (type != FilesCursorType.NORMAL) "" else "AND $s"}AND ${MediaStore.Files.FileColumns.MIME_TYPE} != ?"

        val bundle = Bundle().apply {
            putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection)
            putStringArray(
                ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                if (type != FilesCursorType.NORMAL) arrayOf("image/vnd.djvu") else directories.toTypedArray() + arrayOf(
                    "image/vnd.djvu"
                )
            )
            putString(
                ContentResolver.QUERY_ARG_SQL_SORT_ORDER,
                if (sortingMode == FilesSortingMode.NONE) "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC" else "${MediaStore.Files.FileColumns.SIZE} DESC"
            )
            if (type == FilesCursorType.TRASHED) {
                putInt(MediaStore.QUERY_ARG_MATCH_TRASHED, MediaStore.MATCH_ONLY)
            }

            if (limit != 0L) {
                putInt(ContentResolver.QUERY_ARG_LIMIT, limit.toInt())
            }
        }

        val cursor = appContext.contentResolver.query(
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
            projection,
            bundle,
            null
        )

        liveInstances[token] = if (cursor == null) null else FilesCursorState(cursor, limit)

        return token
    }

    override fun acquireFilter(name: String, sortingMode: FilesSortingMode, limit: Long): String {
        i += 1
        val token = i.toString()

        Log.i("FilesCursorImpl", "acquireFilter, token: $token")

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
                if (sortingMode == FilesSortingMode.NONE) "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC" else "${MediaStore.Files.FileColumns.SIZE} DESC"
            )
            if (limit != 0L) {
                putInt(ContentResolver.QUERY_ARG_LIMIT, limit.toInt())
            }
        }

        val cursor = appContext.contentResolver.query(
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
            projection,
            bundle,
            null
        )

        liveInstances[token] = if (cursor == null) null else FilesCursorState(cursor, limit)

        return token
    }

    override fun acquireIds(ids: List<Long>): String {
        i += 1
        val token = i.toString()

        Log.i("FilesCursorImpl", "acquireIds, token: $token")

        if (ids.isEmpty()) {
            liveInstances[token] = null
            return token
        }

        var selection =
            "(${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} OR ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}) AND ${MediaStore.Files.FileColumns.MIME_TYPE} != ?"

        selection = "($selection) AND ${MediaStore.Files.FileColumns._ID} = ${ids.first()}"
        if (ids.count() > 1) {
            val builder = StringBuilder();
            builder.append(selection)
            for (id in ids) {
                builder.append(" OR ${MediaStore.Files.FileColumns._ID} =  $id")
            }

            selection = builder.toString()
        }

        val bundle = Bundle().apply {
            putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection)
            putStringArray(
                ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                arrayOf("image/vnd.djvu")
            )
            putString(
                ContentResolver.QUERY_ARG_SQL_SORT_ORDER,
                "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC"
            )
        }

        val cursor = appContext.contentResolver.query(
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
            projection,
            bundle,
            null
        )

        liveInstances[token] = if (cursor == null) null else FilesCursorState(cursor, 0)

        return token
    }

    override fun advance(token: String, callback: (Result<List<DirectoryFile>>) -> Unit) {
        scope.launch {
            val state = liveInstances[token]
            if (state == null) {
                callback(Result.success(listOf()))
                return@launch
            }

            val cursor = state.cursor

            if (cursor.isAfterLast) {
                Log.i("FilesCursorImpl", "isAfterLast")

                callback(Result.success(listOf()))
                destroy(token)
                return@launch
            }

            if (!state.movedToFirst) {
                Log.i("FilesCursorImpl", "movedToFirst")

                val moveToFirst = cursor.moveToFirst()

                if (!moveToFirst) {
                    callback(Result.success(listOf()))
                    destroy(token)
                    return@launch
                } else {
                    cursor.moveToPrevious()
                }
                state.movedToFirst = true
            }

            try {
                while (cursor.moveToNext()) {
                    val id = cursor.getLong(state.id)

                    val uri =
                        if (cursor.getInt(state.media_type) == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO) {
                            ContentUris.withAppendedId(
                                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                                id
                            )
                        } else {
                            ContentUris.withAppendedId(
                                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                                id
                            )
                        }


                    state.list.add(
                        DirectoryFile(
                            id = id,
                            bucketId = cursor.getString(state.bucket_id),
                            name = cursor.getString(state.b_display_name),
                            originalUri = uri.toString(),
                            lastModified = cursor.getLong(state.date_modified),
                            isVideo = cursor.getInt(state.media_type) == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO,
                            isGif = cursor.getString(state.media_mime) == "image/gif",
                            height = cursor.getLong(state.media_height),
                            width = cursor.getLong(state.media_width),
                            size = cursor.getInt(state.size).toLong(),
                            bucketName = cursor.getString(state.bucket_name) ?: "",
                        )
                    )

                    if (state.limit == 0L && state.list.count() == 40) {
                        callback(Result.success(state.list.toList()))
                        state.list.clear()
                        break
                    }
                }

                if (state.list.isNotEmpty()) {
                    callback(Result.success(state.list.toList()))
                    state.list.clear()
                }

                Log.i("FilesCursorImpl", "end of while")
            } catch (e: java.lang.Exception) {
                Log.e("FilesCursorImpl", "advance", e)
            }
        }
    }

    override fun destroy(token: String) {
        Log.i("FilesCursorImpl", "destroy")

        liveInstances.remove(token)?.close()
    }
}

class FilesCursorState(val cursor: Cursor, val limit: Long) {
    var movedToFirst: Boolean = false

    val list = mutableListOf<DirectoryFile>()

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

    fun close() {
        if (!cursor.isClosed) {
            Log.i("FilesCursorState", "close cursor")

            cursor.close()
        }
    }
}
