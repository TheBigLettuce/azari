// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

abstract interface class CompactMangaDataService {
  void addAll(List<CompactMangaData> l);

  CompactMangaData? get(String mangaId, MangaMeta site);
}

abstract class MangaData {
  const MangaData();

  String get mangaId;
  MangaMeta get site;
  String get title;
  String get thumbUrl;
}

@immutable
abstract class CompactMangaData
    implements MangaData, CellBase, Thumbnailable, Pressable<CompactMangaData> {
  const factory CompactMangaData({
    required String mangaId,
    required MangaMeta site,
    required String title,
    required String thumbUrl,
  }) = $CompactMangaData;
}

abstract class CompactMangaDataImpl
    with DefaultBuildCellImpl
    implements CompactMangaData {
  const CompactMangaDataImpl();

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
    CompactMangaData cell,
    int idx,
  ) {
    // final (client, setInner) = MangaPageDataNotifier.of(context);
    // setInner(true);

    // final api = site.api(client);

    // Navigator.of(context, rootNavigator: true).push<void>(
    //   MaterialPageRoute(
    //     builder: (context) {
    //       return MangaInfoPage(
    //         id: MangaStringId(cell.mangaId),
    //         api: api,
    //         db: DatabaseConnectionNotifier.of(context),
    //       );
    //     },
    //   ),
    // ).then((value) {
    //   setInner(false);

    //   return value;
    // });
  }
}
