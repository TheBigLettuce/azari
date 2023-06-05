// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:dio/dio.dart';
import 'package:gallery/src/schemas/settings.dart';
import '../db/isar.dart';
import '../schemas/post.dart';

abstract class BooruAPI {
  Dio get client;

  String name();

  int? currentPage();

  String domain();

  Future<Post> singlePost(int id);

  Future<List<Post>> page(int p, String tags);

  Future<List<Post>> fromPost(int postId, String tags);

  Future<List<String>> completeTag(String tag);

  Uri browserLink(int id);

  void close();
}

int numberOfElementsPerRefresh() {
  var settings = isar().settings.getSync(0)!;
  if (settings.listViewBooru) {
    return 20;
  }

  return 10 * settings.picturesPerRow;
}

bool isSafeModeEnabled() => isar().settings.getSync(0)!.safeMode;

//enum Rating { questionable, explicit, safe }
