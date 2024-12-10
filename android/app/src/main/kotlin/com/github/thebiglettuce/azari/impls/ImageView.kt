// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package com.github.thebiglettuce.azari.impls

import android.content.Context
import android.graphics.PointF
import android.net.Uri
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import com.davemorrissey.labs.subscaleview.SubsamplingScaleImageView
import com.github.piasy.biv.view.BigImageView
import com.github.piasy.biv.view.GlideImageViewFactory
import com.github.piasy.biv.view.ImageViewFactory
import com.github.thebiglettuce.azari.generated.GalleryPageChangeEvent
import com.github.thebiglettuce.azari.generated.PlatformGalleryApi
import io.flutter.Log
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlin.math.absoluteValue


internal class ImageView(
    context: Context,
    id: Int,
    galleryApi: PlatformGalleryApi,
    params: Map<String, String>,
) : PlatformView {
    private var imageView: View?

    override fun getView(): View? = imageView

    override fun dispose() {
        imageView?.invalidate()
        imageView = null
    }

    init {
        imageView = BigImageView(context).apply {
            setOnClickListener { galleryApi.galleryTapDownEvent { } }
            setImageViewFactory(GlideImageViewFactory())
            setOptimizeDisplay(false)
            setImageViewFactory(GestureImageViewFactory(galleryApi))
            showImage(Uri.parse(params["uri"]))
        }
    }
}

class GestureImageViewFactory(
    private val galleryApi: PlatformGalleryApi,
) : GlideImageViewFactory() {
    override fun createStillImageView(context: Context?): SubsamplingScaleImageView {
        return GestureImageView(galleryApi, context)
            .apply {
                setOnStateChangedListener(listener)
            }
    }
}

class PanZoomListener(val ssiv: SubsamplingScaleImageView) :
    SubsamplingScaleImageView.DefaultOnStateChangedListener() {
    var isScaling = false

    override fun onScaleChanged(newScale: Float, origin: Int) {
        isScaling = newScale != ssiv.minScale
    }
}

class GestureImageView(
    val galleryApi: PlatformGalleryApi,
    context: Context?,
) :
    SubsamplingScaleImageView(context) {
    val listener = PanZoomListener(this)

    val gestureDetector: GestureDetector =
        GestureDetector(context, object : GestureDetector.SimpleOnGestureListener() {
            override fun onFling(
                e1: MotionEvent?,
                e2: MotionEvent,
                velocityX: Float,
                velocityY: Float,
            ): Boolean {
                if (listener.isScaling) {
                    return false
                }

                if (velocityY > 0 && velocityX > 0 && velocityY > velocityX) {
                    return false
                } else if (velocityY < 0 && velocityX < 0 && velocityY < velocityX) {
                    return false
                } else if (velocityY < 0 && velocityX > 0 && velocityY.absoluteValue > velocityX) {
                    return false
                }

                if (e2.pointerCount > 1) {
                    return false
                }

                galleryApi.galleryPageChangeEvent(if (velocityX > 0) GalleryPageChangeEvent.LEFT else GalleryPageChangeEvent.RIGHT) {}

                return true
            }
        }, null)

    override fun onTouchEvent(event: MotionEvent): Boolean {
        val handledGesture = gestureDetector.onTouchEvent(event)
        if (handledGesture) {
            return true
        }

        return super.onTouchEvent(event)
    }
}


class NativeViewFactory(private val galleryApi: PlatformGalleryApi) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return ImageView(
            context,
            viewId,
            galleryApi,
            args as Map<String, String>
        )
    }
}