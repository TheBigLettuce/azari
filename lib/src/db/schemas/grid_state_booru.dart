// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:isar/isar.dart';

import '../../interfaces/booru.dart';
import 'grid_state.dart';

part 'grid_state_booru.g.dart';

@collection
class GridStateBooru extends GridStateBase {
  @enumerated
  final Booru booru;

  GridStateBooru(this.booru,
      {required super.tags,
      required super.scrollPositionTags,
      required super.selectedPost,
      required super.scrollPositionGrid,
      required super.name,
      required super.time,
      required super.page});

  GridStateBooru.empty(this.booru, String name, String tags)
      : super(
            tags: tags,
            name: name,
            scrollPositionGrid: 0,
            selectedPost: null,
            scrollPositionTags: null,
            page: null,
            time: DateTime.now());

  GridStateBooru copy(bool replaceScrollTagsSelectedPost,
          {String? name,
          Booru? booru,
          String? tags,
          double? scrollPositionGrid,
          int? selectedPost,
          double? scrollPositionTags,
          DateTime? time,
          int? page}) =>
      GridStateBooru(booru ?? this.booru,
          tags: tags ?? this.tags,
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
