// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

abstract class HiddenBooruPostData implements CellBase, Thumbnailable {
  const HiddenBooruPostData(
    this.booru,
    this.postId,
    this.thumbUrl,
  );

  factory HiddenBooruPostData.forDb(
    String thumbUrl,
    int postId,
    Booru booru,
  ) =>
      switch (_currentDb) {
        ServicesImplTable.isar => IsarHiddenBooruPost(booru, postId, thumbUrl),
      };

  final String thumbUrl;

  @Index(unique: true, replace: true, composite: [CompositeIndex("booru")])
  final int postId;
  @enumerated
  final Booru booru;

  @override
  ImageProvider<Object> thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => ValueKey((postId, booru));

  @override
  String alias(bool isList) {
    return "$postId ${booru.string}";
  }

  @override
  CellStaticData description() => const CellStaticData();
}

abstract interface class HiddenBooruPostService implements ServiceMarker {
  List<HiddenBooruPostData> get all;

  bool isHidden(int postId, Booru booru);

  void addAll(List<HiddenBooruPostData> booru);
  void removeAll(List<(int, Booru)> booru);

  StreamSubscription<void> watch(void Function(void) f);
}
