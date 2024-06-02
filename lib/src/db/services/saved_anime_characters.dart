// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

abstract base class AnimeCharacter
    implements
        AnimeCell,
        ContentWidgets,
        Infoable,
        Downloadable,
        Thumbnailable {
  const AnimeCharacter({
    required this.imageUrl,
    required this.name,
    required this.role,
  });

  final String imageUrl;
  final String name;
  final String role;

  @override
  CellStaticData description() => const CellStaticData(
        alignTitleToTopLeft: true,
        titleAtBottom: true,
        titleLines: 3,
      );

  @override
  ImageProvider<Object> thumbnail() => CachedNetworkImageProvider(imageUrl);

  @override
  Key uniqueKey() => ValueKey(imageUrl);

  @override
  String alias(bool isList) => name;

  @override
  String? fileDownloadUrl() => imageUrl;

  @override
  Contentable openImage() => NetImage(
        this,
        thumbnail(),
      );

  @override
  Widget info(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SliverList.list(
      children: [
        addInfoTile(
          title: l10n.sourceFileInfoPage,
          subtitle: imageUrl,
        ),
        addInfoTile(
          title: l10n.role,
          subtitle: role,
        ),
      ],
    );
  }
}

mixin AnimeCharacterDbScope<W extends DbConnHandle<SavedAnimeCharactersService>>
    implements
        DbScope<SavedAnimeCharactersService, W>,
        SavedAnimeCharactersService {
  @override
  List<AnimeCharacter> load(int id, AnimeMetadata site) =>
      widget.db.load(id, site);

  @override
  bool addAsync(AnimeEntryData entry, AnimeAPI api) =>
      widget.db.addAsync(entry, api);

  @override
  StreamSubscription<List<AnimeCharacter>?> watch(
    int id,
    AnimeMetadata site,
    void Function(List<AnimeCharacter>?) f, [
    bool fire = false,
  ]) =>
      widget.db.watch(id, site, f);
}

abstract interface class SavedAnimeCharactersService implements ServiceMarker {
  List<AnimeCharacter> load(int id, AnimeMetadata site);

  bool addAsync(AnimeEntryData entry, AnimeAPI api);

  StreamSubscription<List<AnimeCharacter>?> watch(
    int id,
    AnimeMetadata site,
    void Function(List<AnimeCharacter>?) f, [
    bool fire = false,
  ]);
}
