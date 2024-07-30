// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/net/booru/booru_api.dart";
import "package:flutter/widgets.dart";

Future<List<BooruTag>> autocompleteTag(
  String tagString,
  Future<List<BooruTag>> Function(String) complF,
) {
  if (tagString.isEmpty) {
    return Future.value([]);
  } else if (tagString.characters.last == " ") {
    return Future.value([]);
  }

  final tags = tagString.trim().split(" ");

  return tags.isEmpty || tags.last.isEmpty
      ? Future.value([])
      : complF(tags.last);
}
