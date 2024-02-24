// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/image_view/image_view.dart';

class ImageViewDescription<T extends Cell> {
  const ImageViewDescription({
    this.beforeImageViewRestore,
    this.onExitImageView,
    this.pageViewScrollingOffset,
    this.statistics,
    this.initalCell,
    this.ignoreImageViewEndDrawer = false,
    required this.imageViewKey,
  });

  /// [initalCell] is needed for the state restoration.
  /// If [initalCell] is not null the grid will launch image view setting [ImageView.startingCell] as this value.
  final int? initalCell;

  /// [pageViewScrollingOffset] is needed for the state restoration.
  /// If not null, [pageViewScrollingOffset] gets supplied to the [ImageView.infoScrollOffset].
  final double? pageViewScrollingOffset;

  final void Function()? onExitImageView;

  final void Function()? beforeImageViewRestore;

  final ImageViewStatistics? statistics;

  final bool ignoreImageViewEndDrawer;

  final GlobalKey<ImageViewState<T>> imageViewKey;
}
