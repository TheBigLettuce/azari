// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/services/services.dart";

abstract interface class PostsSourceService<T>
    extends FilteringResourceSource<T> {
  const PostsSourceService();

  @override
  SourceStorage<T> get backingStorage;

  String get tags;
  set tags(String t);

  void clear();
}

abstract class GridPostSource extends PostsSourceService<Post> {
  @override
  PostsOptimizedStorage get backingStorage;
}

abstract class PostsOptimizedStorage extends SourceStorage<Post> {
  List<Post> get firstFiveNormal;

  List<Post> get firstFiveRelaxed;

  List<Post> get firstFiveAll;
}
