// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package com.github.thebiglettuce.azari.impls

import android.database.Cursor
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import com.github.thebiglettuce.azari.App
import com.github.thebiglettuce.azari.generated.DirectoriesCursor
import com.github.thebiglettuce.azari.generated.Directory
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

class DirectoriesCursorImpl(private val appContext: App, private val scope: CoroutineScope) :
    DirectoriesCursor {
    private val liveInstances: MutableMap<String, DirectoriesCursorState?> = mutableMapOf()

    private var i: Long = 0L

    override fun acquire(): String {
        i += 1
        val token = i.toString()

        Log.i("DirectoriesCursorImpl", "acquire, token: $token")

        val projection = arrayOf(
            MediaStore.Files.FileColumns.BUCKET_ID,
            MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME,
            MediaStore.Files.FileColumns.DATE_MODIFIED,
            MediaStore.Files.FileColumns.RELATIVE_PATH,
            MediaStore.Files.FileColumns.VOLUME_NAME,
            MediaStore.Files.FileColumns._ID
        )

        val cursor = appContext.contentResolver.query(
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
            projection,
            "(${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} OR ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}) AND ${MediaStore.Files.FileColumns.MIME_TYPE} != ? ${if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) "AND ${MediaStore.Files.FileColumns.IS_TRASHED} = 0" else ""}",
            arrayOf("image/vnd.djvu"),
            "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC"
        )

        liveInstances[token] = if (cursor == null) null else DirectoriesCursorState(cursor)

        return token
    }

    override fun advance(token: String, callback: (Result<Map<String, Directory>>) -> Unit) {
        scope.launch {
            val state = liveInstances[token]
            if (state == null) {
                callback(Result.success(mapOf()))
                return@launch
            }

            val cursor = state.cursor

            if (cursor.isAfterLast || (state.resMap.isEmpty() && cursor.isLast)) {
                Log.i("DirectoriesCursorImpl", "isAfterLast")

                callback(Result.success(mapOf()))
                destroy(token)
                return@launch
            }

            if (!state.movedToFirst) {
                Log.i("DirectoriesCursorImpl", "movedToFirst")

                val moveToFirst = cursor.moveToFirst()

                if (!moveToFirst) {
                    callback(Result.success(mapOf()))
                    destroy(token)
                    return@launch
                } else {
                    cursor.moveToPrevious()
                }
                state.movedToFirst = true
            }

            try {
                while (cursor.moveToNext()) {
                    val bucketId = cursor.getString(state.bucket_id)
                    if (bucketId == null || state.map.containsKey(bucketId)) {
                        continue
                    }

                    state.map[bucketId] = Unit

                    state.resMap[bucketId] = Directory(
                        thumbFileId = cursor.getLong(state.id),
                        lastModified = cursor.getLong(state.date_modified),
                        bucketId = bucketId,
                        name = cursor.getString(state.b_display_name) ?: "Internal",
                        volumeName = cursor.getString(state.volume_name),
                        relativeLoc = cursor.getString(state.relative_path)
                    )

                    if (state.resMap.count() == 40) {
                        val copy = state.resMap.toMap()
                        state.resMap.clear()

                        callback(Result.success(copy))
                        break
                    }
                }

                if (state.resMap.isNotEmpty()) {
                    val copy = state.resMap.toMap()
                    state.resMap.clear()

                    callback(Result.success(copy))
                }

                Log.i("DirectoriesCursorImpl", "end of while")
            } catch (e: java.lang.Exception) {
                Log.e("DirectoriesCursorImpl", "advance", e)
            }
        }
    }

    override fun destroy(token: String) {
        Log.i("DirectoriesCursorImpl", "destroy")

        liveInstances.remove(token)?.close()
    }
}

class DirectoriesCursorState(val cursor: Cursor) {
    var movedToFirst: Boolean = false

    val map = HashMap<String, Unit>()
    val resMap = mutableMapOf<String, Directory>()

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

    fun close() {
        if (!cursor.isClosed) {
            Log.i("DirectoriesCursorState", "close cursor")
            cursor.close()
        }
    }
}
