// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery

import android.content.Context
import android.net.Uri
import android.util.Log
import android.view.View
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.davemorrissey.labs.subscaleview.ImageSource
import com.davemorrissey.labs.subscaleview.SubsamplingScaleImageView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

internal class ImageView(
    context: Context,
    id: Int,
    galleryApi: GalleryApi,
    params: Map<String, String>,
) : PlatformView {
    private var imageView: View

    override fun getView(): View {
        return imageView
    }

    override fun dispose() {
        imageView.invalidate()
    }

    init {
        val isGif = params.containsKey("gif")

        if (isGif) {
            imageView = android.widget.ImageView(context)

            try {
                Glide.with(context).asGif()
                    .load(Uri.parse(params["uri"])).diskCacheStrategy(
                        DiskCacheStrategy.NONE
                    ).into(imageView as android.widget.ImageView)
            } catch (e: Exception) {
                Log.e("loading image", e.toString())
            }
        } else {
            imageView = SubsamplingScaleImageView(context)
            imageView.setOnClickListener { galleryApi.galleryTapDownEvent { } }
            (imageView as SubsamplingScaleImageView).setImage(ImageSource.uri(Uri.parse(params["uri"])))
//            try {
//                Glide.with(context).load(Uri.parse(params["uri"])).diskCacheStrategy(
//                    DiskCacheStrategy.NONE
//                )
//                    .into(imageView)
//            } catch (e: java.lang.Exception) {
//                Log.e("loading image", e.toString())
//            }
        }
    }
}


class NativeViewFactory(private val galleryApi: GalleryApi) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return ImageView(context, viewId, galleryApi, args as Map<String, String>)
    }
}