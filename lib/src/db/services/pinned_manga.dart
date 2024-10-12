// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

abstract interface class PinnedMangaService implements ServiceMarker {
  int get count;

  bool exist(String mangaId, MangaMeta site);

  List<PinnedManga> getAll(int limit);

  void addAll(List<MangaEntry> l);
  void reAdd(List<PinnedManga> l);

  List<PinnedManga> deleteAll(List<(MangaId, MangaMeta)> ids);
  void deleteSingle(String mangaId, MangaMeta site);

  StreamSubscription<void> watch(void Function(void) f);
}

@immutable
abstract class PinnedManga
    implements MangaData, CellBase, Thumbnailable, Pressable<PinnedManga> {
  const factory PinnedManga({
    required String mangaId,
    required MangaMeta site,
    required String title,
    required String thumbUrl,
  }) = $PinnedManga;
}

abstract class PinnedMangaImpl
    with DefaultBuildCellImpl
    implements PinnedManga {
  const PinnedMangaImpl();

  @override
  CellStaticData description() => const CellStaticData(
        alignTitleToTopLeft: true,
      );

  @override
  String alias(bool isList) => title;

  @override
  ImageProvider<Object> thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => ValueKey(thumbUrl);

  @override
  void onPress(
    BuildContext context,
    GridFunctionality<PinnedManga> functionality,
    PinnedManga cell,
    int idx,
  ) {
    // final (client, setInner) = MangaPageDataNotifier.of(context);
    // setInner(true);

    // final api = site.api(client);

    // Navigator.of(context, rootNavigator: true).push(
    //   MaterialPageRoute<void>(
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

mixin PinnedMangaDbScope<W extends DbConnHandle<PinnedMangaService>>
    implements DbScope<PinnedMangaService, W>, PinnedMangaService {
  @override
  int get count => widget.db.count;

  @override
  bool exist(String mangaId, MangaMeta site) => widget.db.exist(mangaId, site);

  @override
  List<PinnedManga> getAll(int limit) => widget.db.getAll(limit);

  @override
  void addAll(List<MangaEntry> l) => widget.db.addAll(l);

  @override
  void reAdd(List<PinnedManga> l) => widget.db.reAdd(l);

  @override
  List<PinnedManga> deleteAll(List<(MangaId, MangaMeta)> ids) =>
      widget.db.deleteAll(ids);

  @override
  void deleteSingle(String mangaId, MangaMeta site) =>
      widget.db.deleteSingle(mangaId, site);

  @override
  StreamSubscription<void> watch(void Function(void) f) => widget.db.watch(f);
}
