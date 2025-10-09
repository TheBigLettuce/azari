// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/services/impl/io.dart";
import "package:azari/src/services/impl/obj/booru_pool_impl.dart";
import "package:azari/src/services/services.dart";
import "package:isar/isar.dart";

part "favorite_pool.g.dart";

@collection
class IsarFavoritePool extends BooruPoolImpl implements $BooruPool {
  const IsarFavoritePool({
    required this.thumbUrl,
    required this.id,
    required this.booru,
    required this.isarId,
    required this.category,
    required this.description,
    required this.isDeleted,
    required this.name,
    required this.postIds,
    required this.updatedAt,
  });

  const IsarFavoritePool.noId({
    required this.thumbUrl,
    required this.id,
    required this.booru,
    required this.category,
    required this.description,
    required this.isDeleted,
    required this.name,
    required this.postIds,
    required this.updatedAt,
  }) : isarId = null;

  factory IsarFavoritePool.fromPool(BooruPool pool) => IsarFavoritePool.noId(
    thumbUrl: pool.thumbUrl,
    id: pool.id,
    booru: pool.booru,
    category: pool.category,
    description: pool.description,
    isDeleted: pool.isDeleted,
    name: pool.name,
    postIds: pool.postIds,
    updatedAt: pool.updatedAt,
  );

  final Id? isarId;

  @override
  @Index(unique: true, replace: true, composite: [CompositeIndex("booru")])
  final int id;

  @enumerated
  @override
  final Booru booru;

  @override
  final String thumbUrl;

  @enumerated
  @override
  final BooruPoolCategory category;

  @override
  final String description;

  @override
  final bool isDeleted;

  @override
  final String name;

  @override
  final List<int> postIds;

  @override
  final DateTime updatedAt;

  @override
  BooruPool copy({
    bool? isDeleted,
    int? id,
    Booru? booru,
    String? name,
    String? description,
    String? thumbUrl,
    List<int>? postIds,
    BooruPoolCategory? category,
    DateTime? updatedAt,
  }) => IsarFavoritePool(
    thumbUrl: thumbUrl ?? this.thumbUrl,
    id: id ?? this.id,
    booru: booru ?? this.booru,
    isarId: isarId,
    category: category ?? this.category,
    description: description ?? this.description,
    isDeleted: isDeleted ?? this.isDeleted,
    name: name ?? this.name,
    postIds: postIds ?? this.postIds,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
