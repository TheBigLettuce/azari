// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/widgets.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory.dart';

class CallbackDescription {
  final Future<void> Function(SystemGalleryDirectory? chosen, String? newDir) c;
  final String description;
  final List<String> suggestFor;
  final IconData icon;

  final PreferredSizeWidget? preview;

  final bool joinable;

  void call(SystemGalleryDirectory? chosen, String? newDir) {
    c(chosen, newDir);
  }

  const CallbackDescription(
    this.description,
    this.c, {
    this.preview,
    required this.icon,
    required this.joinable,
    required this.suggestFor,
  });
}
