// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

class CompactMangaDataBase {
  const CompactMangaDataBase({
    required this.mangaId,
    required this.site,
    required this.thumbUrl,
    required this.title,
  });

  @Index(unique: true, replace: true, composite: [CompositeIndex("site")])
  final String mangaId;

  @enumerated
  final MangaMeta site;

  final String title;
  final String thumbUrl;
}

mixin CompactMangaData
    implements
        CompactMangaDataBase,
        CellBase,
        Thumbnailable,
        Pressable<CompactMangaData> {
  @override
  CellStaticData description() => const CellStaticData();

  @override
  String alias(bool isList) => title;

  @override
  ImageProvider<Object> thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => ValueKey(thumbUrl);

  @override
  void onPress(
    BuildContext context,
    GridFunctionality<CompactMangaData> functionality,
    CompactMangaDataBase cell,
    int idx,
  ) {
    final (client, setInner) = MangaPageDataNotifier.of(context);
    setInner(true);

    final api = site.api(client);

    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (context) {
          return MangaInfoPage(
            id: MangaStringId(cell.mangaId),
            api: api,
            db: DatabaseConnectionNotifier.of(context),
          );
        },
      ),
    ).then((value) {
      setInner(false);

      return value;
    });
  }
}

abstract interface class CompactMangaDataService {
  void addAll(List<CompactMangaData> l);

  CompactMangaData? get(String mangaId, MangaMeta site);
}
