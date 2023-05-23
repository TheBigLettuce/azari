// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/excluded_tags.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:logging/logging.dart';

import '../../pages/booru_scroll.dart';

class BooruTags {
  void onPressed(BuildContext context, String t) {
    t = t.trim();
    if (t.isEmpty) {
      return;
    }

    addLatest(t);
    newSecondaryGrid().then((value) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return BooruScroll.secondary(
          isar: value,
          tags: t,
        );
      }));
    }).onError((error, stackTrace) {
      log("searching for tag $t",
          level: Level.WARNING.value, error: error, stackTrace: stackTrace);
    });
  }

  LastTags _booruTagsLatest() {
    var currentBooru = isar().settings.getSync(0)!.selectedBooru;
    var booruTags = isar().lastTags.getSync(fastHash(currentBooru.string));
    if (booruTags == null) {
      booruTags = LastTags(currentBooru.string, []);
      isar().writeTxnSync(() => isar().lastTags.putSync(booruTags!));
    }

    return booruTags;
  }

  ExcludedTags _booruTagsExcluded() {
    var currentBooru = isar().settings.getSync(0)!.selectedBooru;
    var booruTags = isar().excludedTags.getSync(fastHash(currentBooru.string));
    if (booruTags == null) {
      booruTags = ExcludedTags(currentBooru.string, []);
      isar().writeTxnSync(() => isar().excludedTags.putSync(booruTags!));
    }

    return booruTags;
  }

  void addLatest(String t) {
    var booruTags = _booruTagsLatest();
    List<String> tagsCopy = List.from(booruTags.tags);
    tagsCopy.remove(t);
    tagsCopy.add(t);

    isar().writeTxnSync(() {
      isar()
          .lastTags
          .putSync(LastTags(booruTags.domain, tagsCopy.reversed.toList()));
    });
  }

  void deleteTag(String tag) {
    var booruTags = _booruTagsLatest();
    List<String> tags = List.from(booruTags.tags);
    tags.remove(tag);

    isar().writeTxnSync(
        () => isar().lastTags.putSync(LastTags(booruTags.domain, tags)));
  }

  List<String> getLatest() => _booruTagsLatest().tags;

  void addExcluded(String t) {
    var booruTags = _booruTagsExcluded();
    List<String> tagsCopy = List.from(booruTags.tags);
    tagsCopy.remove(t);
    tagsCopy.add(t);

    isar().writeTxnSync(() => isar()
        .excludedTags
        .putSync(ExcludedTags(booruTags.domain, tagsCopy.reversed.toList())));
  }

  void deleteExcludedTag(String tag) {
    var booruTags = _booruTagsExcluded();
    List<String> tags = List.from(booruTags.tags);
    tags.remove(tag);

    isar().writeTxnSync(() =>
        isar().excludedTags.putSync(ExcludedTags(booruTags.domain, tags)));
  }

  List<String> getExcluded() => _booruTagsExcluded().tags;
}
