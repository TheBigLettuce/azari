// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/platform/gallery_api.dart";
import "package:flutter/widgets.dart";

class CallbackDescription {
  const CallbackDescription(
    this.c, {
    required this.preview,
    required this.joinable,
    required this.suggestFor,
  });
  final Future<void> Function(
    String chosen,
    String volumeName,
    String bucketId,
    bool newDir,
  ) c;
  final List<String> suggestFor;

  final PreferredSizeWidget preview;

  final bool joinable;

  void call({
    required String chosen,
    required String volumeName,
    required String bucketId,
    required bool newDir,
  }) =>
      c(
        chosen,
        volumeName,
        bucketId,
        newDir,
      );
}

class CallbackDescriptionNested {
  const CallbackDescriptionNested(
    this.c, {
    this.returnBack = false,
    required this.preview,
  });

  final void Function(File chosen) c;
  final bool returnBack;

  final PreferredSizeWidget preview;

  void call(File chosen) {
    c(chosen);
  }
}
