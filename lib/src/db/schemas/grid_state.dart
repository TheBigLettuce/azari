// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:isar/isar.dart';

import 'settings.dart';

part 'grid_state.g.dart';

@collection
class GridState extends GridStateBase {
  GridState(
      {required super.tags,
      required super.scrollPositionTags,
      required super.selectedPost,
      required super.scrollPositionGrid,
      required super.name,
      required super.safeMode,
      required super.time,
      required super.page});

  GridState.empty(String name, String tags, SafeMode safeMode)
      : super(
            tags: tags,
            name: name,
            safeMode: safeMode,
            scrollPositionGrid: 0,
            selectedPost: null,
            scrollPositionTags: null,
            page: null,
            time: DateTime.now());

  GridState copy(bool replaceScrollTagsSelectedPost,
          {String? name,
          String? tags,
          double? scrollPositionGrid,
          int? selectedPost,
          SafeMode? safeMode,
          double? scrollPositionTags,
          DateTime? time,
          int? page}) =>
      GridState(
          tags: tags ?? this.tags,
          safeMode: safeMode ?? this.safeMode,
          scrollPositionTags: replaceScrollTagsSelectedPost
              ? scrollPositionTags
              : scrollPositionTags ?? this.scrollPositionTags,
          selectedPost: replaceScrollTagsSelectedPost
              ? selectedPost
              : selectedPost ?? this.selectedPost,
          scrollPositionGrid: scrollPositionGrid ?? this.scrollPositionGrid,
          page: page ?? this.page,
          time: time ?? this.time,
          name: name ?? this.name);
}

class GridStateBase {
  Id? id;

  @Index(unique: true, replace: true)
  final String name;
  @Index()
  final DateTime time;

  final String tags;

  final double scrollPositionGrid;

  final int? selectedPost;
  final double? scrollPositionTags;
  final int? page;

  @enumerated
  final SafeMode safeMode;

  GridStateBase(
      {required this.tags,
      required this.scrollPositionTags,
      required this.selectedPost,
      required this.safeMode,
      required this.scrollPositionGrid,
      required this.name,
      required this.page,
      required this.time});
}
