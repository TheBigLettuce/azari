package com.github.thebiglettuce.azari.impls

import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.system.Os
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import com.github.thebiglettuce.azari.generated.DirectoryFile
import com.github.thebiglettuce.azari.generated.GalleryHostApi
import com.github.thebiglettuce.azari.generated.UriFile
import com.github.thebiglettuce.azari.mover.MediaLoaderAndMover

internal class GalleryHostApiImpl(
    private val context: Context,
    private val mediaLoaderAndMover: MediaLoaderAndMover,
) :
    GalleryHostApi {
    override fun getPicturesDirectly(
        dir: String?,
        limit: Long,
        onlyLatest: Boolean,
        callback: (Result<List<DirectoryFile>>) -> Unit,
    ) {

        mediaLoaderAndMover.refreshFilesDirectly(
            dir = dir
                ?: "",
            limit = limit,
            type = if (onlyLatest) MediaLoaderAndMover.Enums.LoadMediaType.Latest else MediaLoaderAndMover.Enums.LoadMediaType.Normal,
            sortingMode = MediaLoaderAndMover.Enums.FilesSortingMode.None,
        ) { list, notFound, empty, inRefresh ->
            callback(Result.success(list))
        }
    }

    override fun latestFilesByName(
        name: String,
        limit: Long,
        callback: (Result<List<DirectoryFile>>) -> Unit,
    ) {
        mediaLoaderAndMover.filesSearchByNameDirectly(name, limit) { list ->
            callback(Result.success(list))
        }
    }

    override fun getPicturesOnlyDirectly(
        ids: List<Long>,
        callback: (Result<List<DirectoryFile>>) -> Unit,
    ) {
        mediaLoaderAndMover.filesDirectly(ids) { list, notFound, empty, inRefresh ->
            callback(Result.success(list))
        }
    }

    override fun getUriPicturesDirectly(
        uris: List<String>,
        callback: (Result<List<UriFile>>) -> Unit,
    ) {
        CoroutineScope(Dispatchers.IO).launch {
            val ret = mutableListOf<UriFile>()

            for (uri in uris) {
                val parsedUri = Uri.parse(uri)



                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) context.contentResolver.openFile(
                    parsedUri,
                    "r",
                    null
                ) else context.contentResolver.openFileDescriptor(parsedUri, "r"))?.use {
                    val options = BitmapFactory.Options().apply {
                        inJustDecodeBounds = true
                    }

                    BitmapFactory.decodeFileDescriptor(it.fileDescriptor, null, options)

                    val stat = Os.fstat(it.fileDescriptor)

                    ret.add(
                        UriFile(
                            uri = uri,
                            lastModified = stat.st_mtim.tv_sec,
                            size = stat.st_size,
                            name = parsedUri.lastPathSegment!!.split("/").last(),
                            height = options.outHeight.toLong(),
                            width = options.outWidth.toLong(),
                        )
                    )
                }
            }

            callback(Result.success(ret))
        }
    }
}