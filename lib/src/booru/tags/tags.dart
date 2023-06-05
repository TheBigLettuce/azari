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

class BooruTagging<T extends Tags> {
  final T Function(String booru) _getTags;
  final void Function(List<String> v, String domain) _addTags;

  T get() {
    var currentBooru = isar().settings.getSync(0)!.selectedBooru;

    return _getTags(currentBooru.string);
  }

  void add(String t) {
    var booruTags = get();
    List<String> tagsCopy = List.from(booruTags.tags);
    tagsCopy.remove(t);

    _addTags([t, ...tagsCopy], booruTags.domain);
  }

  void delete(String t) {
    var booruTags = get();
    List<String> tags = List.from(booruTags.tags);
    tags.remove(t);

    _addTags(tags, booruTags.domain);
  }

  List<String> getStrings() => get().tags;

  const BooruTagging(T Function(String s) getTags,
      void Function(List<String> v, String domain) addTags)
      : _addTags = addTags,
        _getTags = getTags;
}

class BooruTags {
  BooruTagging<ExcludedTags> excluded = BooruTagging((s) {
    var booruTags = isar().excludedTags.getSync(fastHash(s));
    if (booruTags == null) {
      booruTags = ExcludedTags(s, []);
      isar().writeTxnSync(() => isar().excludedTags.putSync(booruTags!));
    }

    return booruTags;
  }, (v, domain) {
    isar().writeTxnSync(
        () => isar().excludedTags.putSync(ExcludedTags(domain, v)));
  });

  BooruTagging<LastTags> latest = BooruTagging((s) {
    var booruTags = isar().lastTags.getSync(fastHash(s));
    if (booruTags == null) {
      booruTags = LastTags(s, []);
      isar().writeTxnSync(() => isar().lastTags.putSync(booruTags!));
    }

    return booruTags;
  }, (v, domain) {
    isar().writeTxnSync(() => isar().lastTags.putSync(LastTags(domain, v)));
  });

  void onPressed(BuildContext context, String t) {
    t = t.trim();
    if (t.isEmpty) {
      return;
    }

    latest.add(t);
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
}
