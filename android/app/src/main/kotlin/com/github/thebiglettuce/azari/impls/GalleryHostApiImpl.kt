// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package com.github.thebiglettuce.azari.impls

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaDataSource
import android.media.MediaMetadataRetriever
import android.os.Build
import android.provider.MediaStore
import android.system.Os
import android.util.Log
import androidx.core.net.toUri
import coil3.imageLoader
import coil3.request.CachePolicy
import coil3.request.ImageRequest
import coil3.request.allowHardware
import coil3.request.bitmapConfig
import coil3.target.Target
import coil3.video.VideoFrameDecoder
import com.github.thebiglettuce.azari.generated.GalleryHostApi
import com.github.thebiglettuce.azari.generated.UriFile
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

internal class GalleryHostApiImpl(
    private val context: Context,
) :
    GalleryHostApi {
    override fun mediaVersion(callback: (Result<Long>) -> Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            callback(Result.success(MediaStore.getGeneration(context, MediaStore.VOLUME_EXTERNAL)))
        } else {
            callback(Result.success(0))
        }
    }

    override fun getUriPicturesDirectly(
        uris: List<String>,
        callback: (Result<List<UriFile>>) -> Unit,
    ) {
        CoroutineScope(Dispatchers.IO).launch {
            val ret = mutableListOf<UriFile>()

            for (uri in uris) {
                val parsedUri = uri.toUri()

                val type = context.contentResolver.getType(parsedUri) ?: continue

                if (type.startsWith("video")) {
//                    context.imageLoader.execute(
//                        ImageRequest.Builder(context)
//                            .diskCachePolicy(CachePolicy.DISABLED)
//                            .networkCachePolicy(CachePolicy.DISABLED)
//                            .memoryCachePolicy(CachePolicy.DISABLED)
//                            .allowHardware(false)
//                            .data(parsedUri)
//                            .decoderFactory(({ result, options, _ ->
//                                VideoFrameDecoder(
//                                    result.source,
//                                    options
//                                )
//                            })).build()
//                    ).image?.run {
//
//                    }

                    (context.contentResolver.openFile(
                        parsedUri,
                        "r",
                        null
                    ))?.use {
                        val stat = Os.fstat(it.fileDescriptor)

                        ret.add(
                            UriFile(
                                uri = uri,
                                lastModified = stat.st_mtim.tv_sec,
                                size = stat.st_size,
                                name = parsedUri.lastPathSegment!!.split("/").last(),
                                height = 0,
                                width = 0,
                                isGif = false,
                                isVideo = true,
                            )
                        )
                    }
                } else {
                    (context.contentResolver.openFile(
                        parsedUri,
                        "r",
                        null
                    ))?.use {
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
                                isGif = type == "image/gif",
                                isVideo = false,
                            )
                        )
                    }
                }


            }

            callback(Result.success(ret))
        }
    }
}


//                context.contentResolver.openFileDescriptor(parsedUri, "rw")?.use {
//                    MediaMetadataRetriever().use { retriever ->
//                        retriever.setDataSource(it.fileDescriptor)
//
//                        val hasImage =
//                            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_HAS_IMAGE)
//                        val hasVideo =
//                            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_HAS_VIDEO)
//
//                        Log.i("MediaMetadataRetriever", "${hasImage}: ${hasVideo}")
//
//                        if (hasImage != null && hasVideo != null) {
//                            return@use
//                        }
//
//                        val srcWidth: Int
//                        val srcHeight: Int
//                        val mimeType =
//                            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_MIMETYPE)
//                                ?: ""
//                        if (hasImage != null) {
//                            val rotation =
//                                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_IMAGE_ROTATION)
//                                    ?.toIntOrNull()
//                                    ?: 0
//                            if (rotation == 90 || rotation == 270) {
//                                srcWidth =
//                                    retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_IMAGE_HEIGHT)
//                                        ?.toIntOrNull()
//                                        ?: 0
//                                srcHeight =
//                                    retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_IMAGE_WIDTH)
//                                        ?.toIntOrNull()
//                                        ?: 0
//                            } else {
//                                srcWidth =
//                                    retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_IMAGE_WIDTH)
//                                        ?.toIntOrNull()
//                                        ?: 0
//                                srcHeight =
//                                    retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_IMAGE_HEIGHT)
//                                        ?.toIntOrNull()
//                                        ?: 0
//                            }
//                        } else {
//                            val rotation =
//                                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
//                                    ?.toIntOrNull()
//                                    ?: 0
//                            if (rotation == 90 || rotation == 270) {
//                                srcWidth =
//                                    retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
//                                        ?.toIntOrNull()
//                                        ?: 0
//                                srcHeight =
//                                    retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
//                                        ?.toIntOrNull()
//                                        ?: 0
//                            } else {
//                                srcWidth =
//                                    retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
//                                        ?.toIntOrNull()
//                                        ?: 0
//                                srcHeight =
//                                    retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
//                                        ?.toIntOrNull()
//                                        ?: 0
//                            }
//                        }
//
//                        val stat = Os.fstat(it.fileDescriptor)
//
//                        ret.add(
//                            UriFile(
//                                uri = uri,
//                                lastModified = stat?.st_mtim?.tv_sec ?: 0,
//                                size = stat?.st_size ?: 0,
//                                name = parsedUri.lastPathSegment!!.split("/").last(),
//                                height = srcHeight.toLong(),
//                                width = srcWidth.toLong(),
//                                isGif = mimeType == "image/gif",
//                                isVideo = hasVideo != null,
//                            )
//                        )
//                    }
//                }

//class VideoFrameDecoder(
//    private val source: ImageSource,
//    private val options: Options,
//) : Decoder {
//
//    override suspend fun decode() = MediaMetadataRetriever().use { retriever ->
//        retriever.setDataSource(source)
//
//        // Resolve the dimensions to decode the video frame at accounting
//        // for the source's aspect ratio and the target's size.
//        var srcWidth: Int
//        var srcHeight: Int
//        val rotation = retriever.extractMetadata(METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
//        if (rotation == 90 || rotation == 270) {
//            srcWidth = retriever.extractMetadata(METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 0
//            srcHeight = retriever.extractMetadata(METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 0
//        } else {
//            srcWidth = retriever.extractMetadata(METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 0
//            srcHeight = retriever.extractMetadata(METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 0
//        }
//
////        val dstSize = if (srcWidth > 0 && srcHeight > 0) {
////            val (dstWidth, dstHeight) = DecodeUtils.computeDstSize(
////                srcWidth = srcWidth,
////                srcHeight = srcHeight,
////                targetSize = options.size,
////                scale = options.scale,
////                maxSize = options.maxBitmapSize,
////            )
////            val rawScale = DecodeUtils.computeSizeMultiplier(
////                srcWidth = srcWidth,
////                srcHeight = srcHeight,
////                dstWidth = dstWidth,
////                dstHeight = dstHeight,
////                scale = options.scale,
////            )
////            val scale = if (options.precision == Precision.INEXACT) {
////                rawScale.coerceAtMost(1.0)
////            } else {
////                rawScale
////            }
////            val width = (scale * srcWidth).roundToInt()
////            val height = (scale * srcHeight).roundToInt()
////            Size(width, height)
////        } else {
////            // We were unable to decode the video's dimensions.
////            // Fall back to decoding the video frame at the original size.
////            // We'll scale the resulting bitmap after decoding if necessary.
////            Size.ORIGINAL
////        }
//
//        val frameMicros = computeFrameMicros(retriever)
////        val (dstWidth, dstHeight) = dstSize
//        val rawBitmap: Bitmap? = if (SDK_INT >= 28 && options.videoFrameIndex >= 0) {
//            retriever.getFrameAtIndex(
//                frameIndex = options.videoFrameIndex,
//                config = options.bitmapConfig,
//            )?.also {
//                srcWidth = it.width
//                srcHeight = it.height
//            }
//        } else {
//            retriever.getFrameAtTime(
//                0, 1,
//                options.bitmapConfig,
//            )?.also {
//                srcWidth = it.width
//                srcHeight = it.height
//            }
//        }
//
//        // If you encounter this exception make sure your video is encoded in a supported codec.
//        // https://developer.android.com/guide/topics/media/media-formats#video-formats
//        checkNotNull(rawBitmap) { "Failed to decode frame at $frameMicros microseconds." }
//
//        val bitmap = normalizeBitmap(rawBitmap, dstSize)
//
////        val isSampled = if (srcWidth > 0 && srcHeight > 0) {
////            DecodeUtils.computeSizeMultiplier(
////                srcWidth = srcWidth,
////                srcHeight = srcHeight,
////                dstWidth = bitmap.width,
////                dstHeight = bitmap.height,
////                scale = options.scale,
////            ) < 1.0
////        } else {
////            // We were unable to determine the original size of the video. Assume it is sampled.
////            true
////        }
//
//        DecodeResult(
//            image = bitmap.toDrawable(options.context.resources).asImage(),
//            isSampled = isSampled,
//        )
//    }
//
//    private fun computeFrameMicros(retriever: MediaMetadataRetriever): Long {
//        val frameMicros = options.videoFrameMicros
//        if (frameMicros >= 0) {
//            return frameMicros
//        }
//
//        val framePercent = options.videoFramePercent
//        if (framePercent >= 0) {
//            val durationMillis =
//                retriever.extractMetadata(METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L
//            return 1000 * (framePercent * durationMillis).roundToLong()
//        }
//
//        return 0
//    }
//
//    /** Return [inBitmap] or a copy of [inBitmap] that is valid for the input [options] and [size]. */
//    private fun normalizeBitmap(inBitmap: Bitmap, size: Size): Bitmap {
//        // Fast path: if the input bitmap is valid, return it.
//        if (isConfigValid(inBitmap, options) && isSizeValid(inBitmap, options, size)) {
//            return inBitmap
//        }
//
//        // Slow path: re-render the bitmap with the correct size + config.
//        val scale = DecodeUtils.computeSizeMultiplier(
//            srcWidth = inBitmap.width,
//            srcHeight = inBitmap.height,
//            dstWidth = size.width.pxOrElse { inBitmap.width },
//            dstHeight = size.height.pxOrElse { inBitmap.height },
//            scale = options.scale,
//        ).toFloat()
//        val dstWidth = (scale * inBitmap.width).roundToInt()
//        val dstHeight = (scale * inBitmap.height).roundToInt()
//        val safeConfig = when {
//            SDK_INT >= 26 && options.bitmapConfig == Bitmap.Config.HARDWARE -> Bitmap.Config.ARGB_8888
//            else -> options.bitmapConfig
//        }
//
//        val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
//        val outBitmap = createBitmap(dstWidth, dstHeight, safeConfig)
//        outBitmap.applyCanvas {
//            scale(scale, scale)
//            drawBitmap(inBitmap, 0f, 0f, paint)
//        }
//        inBitmap.recycle()
//
//        return outBitmap
//    }
//
//    private fun isConfigValid(bitmap: Bitmap, options: Options): Boolean {
//        return SDK_INT < 26 ||
//                bitmap.config != Bitmap.Config.HARDWARE ||
//                options.bitmapConfig == Bitmap.Config.HARDWARE
//    }
//
//    private fun isSizeValid(bitmap: Bitmap, options: Options, size: Size): Boolean {
//        if (options.precision == Precision.INEXACT) return true
//        val multiplier = DecodeUtils.computeSizeMultiplier(
//            srcWidth = bitmap.width,
//            srcHeight = bitmap.height,
//            dstWidth = size.width.pxOrElse { bitmap.width },
//            dstHeight = size.height.pxOrElse { bitmap.height },
//            scale = options.scale,
//        )
//        return multiplier == 1.0
//    }
//
//    private fun MediaMetadataRetriever.setDataSource(source: ImageSource) {
//        val metadata = source.metadata
//        when {
//            SDK_INT >= 23 && metadata is MediaSourceMetadata -> {
//                setDataSource(metadata.mediaDataSource)
//            }
//
//            metadata is AssetMetadata -> {
//                options.context.assets.openFd(metadata.filePath).use {
//                    setDataSource(it.fileDescriptor, it.startOffset, it.length)
//                }
//            }
//
//            metadata is ContentMetadata -> {
//                setDataSource(options.context, metadata.uri.toAndroidUri())
//            }
//
//            metadata is ResourceMetadata -> {
//                setDataSource("android.resource://${metadata.packageName}/${metadata.resId}")
//            }
//
//            source.fileSystem === FileSystem.SYSTEM -> {
//                setDataSource(source.file().toFile().path)
//            }
//
//            SDK_INT >= 23 -> {
//                val handle = source.fileSystem.openReadOnly(source.file())
//                setDataSource(FileHandleMediaDataSource(handle))
//            }
//
//            else -> {
//                error(
//                    "Unable to read ${source.file()} as a custom file system " +
//                            "(${source.fileSystem}) is used and the device is API 22 or earlier.",
//                )
//            }
//        }
//    }
//
//    class Factory : Decoder.Factory {
//
//        override fun create(
//            result: SourceFetchResult,
//            options: Options,
//            imageLoader: ImageLoader,
//        ): Decoder? {
//            if (!isApplicable(result.mimeType)) return null
//            return VideoFrameDecoder(result.source, options)
//        }
//
//        private fun isApplicable(mimeType: String?): Boolean {
//            return mimeType != null && mimeType.startsWith("video/")
//        }
//    }
//}