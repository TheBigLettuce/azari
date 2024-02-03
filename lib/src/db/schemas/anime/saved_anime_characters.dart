// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/system_gallery_thumbnail_provider.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/interfaces/anime/anime_api.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../interfaces/cell/sticker.dart';

part 'saved_anime_characters.g.dart';

final _futures = <(int, AnimeMetadata), Future>{};

@collection
class SavedAnimeCharacters {
  SavedAnimeCharacters({
    required this.characters,
    required this.id,
    required this.site,
  });

  Id? isarId;

  @Index(replace: true, unique: true, composite: [CompositeIndex("site")])
  final int id;
  @enumerated
  final AnimeMetadata site;
  final List<AnimeCharacter> characters;

  static List<AnimeCharacter> load(int id, AnimeMetadata site) =>
      Dbs.g.anime.savedAnimeCharacters.getByIdSiteSync(id, site)?.characters ??
      const [];

  static bool addAsync(AnimeEntry entry, AnimeAPI api) {
    if (_futures.containsKey((entry.id, entry.site))) {
      return true;
    }

    _futures[(entry.id, entry.site)] = api.characters(entry)
      ..then((value) {
        Dbs.g.anime.writeTxnSync(() => Dbs.g.anime.savedAnimeCharacters
            .putByIdSiteSync(SavedAnimeCharacters(
                characters: value, id: entry.id, site: entry.site)));
      }).whenComplete(() => _futures.remove((entry.id, entry.site)));

    return false;
  }

  static StreamSubscription<SavedAnimeCharacters?> watch(
      int id, AnimeMetadata site, void Function(SavedAnimeCharacters?) f,
      [bool fire = false]) {
    var e = Dbs.g.anime.savedAnimeCharacters.getByIdSiteSync(id, site)?.isarId;
    e ??= Dbs.g.anime.writeTxnSync(() => Dbs.g.anime.savedAnimeCharacters
        .putByIdSiteSync(
            SavedAnimeCharacters(characters: const [], id: id, site: site)));

    return Dbs.g.anime.savedAnimeCharacters
        .watchObject(e!, fireImmediately: fire)
        .listen(f);
  }
}

@embedded
class AnimeCharacter extends Cell with CachedCellValuesMixin {
  final String imageUrl;
  final String name;
  final String role;

  AnimeCharacter({
    this.imageUrl = "",
    this.name = "",
    this.role = "",
  }) {
    initValues(ValueKey(imageUrl), imageUrl,
        () => NetImage(CachedNetworkImageProvider(imageUrl)));
  }

  @override
  int? isarId;

  @override
  List<Widget>? addButtons(BuildContext context) => null;

  @override
  List<Widget>? addInfo(BuildContext context, extra, AddInfoColorData colors) =>
      [
        addInfoTile(
            colors: colors,
            title: AppLocalizations.of(context)!.sourceFileInfoPage,
            subtitle: imageUrl),
        addInfoTile(
            colors: colors,
            title: AppLocalizations.of(context)!.role,
            subtitle: role),
      ];

  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) => null;

  @override
  String alias(bool isList) => name;

  @override
  List<Sticker> stickers(BuildContext context) => const [];

  @override
  String? fileDownloadUrl() => imageUrl;
}
