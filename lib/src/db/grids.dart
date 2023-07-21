// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'isar.dart';

class GridTab {
  final Isar _instance;

  final IsarBooruTagging _excluded;
  final IsarBooruTagging _latest;

  BooruTagging get excluded => _excluded;
  BooruTagging get latest => _latest;

  void onTagPressed(BuildContext context, Tag t) {
    t = t.trim();
    if (t.tag.isEmpty) {
      return;
    }

    latest.add(t);

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return BooruScroll.secondary(
        grids: this,
        instance: newSecondaryGrid(),
        tags: t.tag,
      );
    }));
  }

  void close() {
    _instance.close();
  }

  Isar get instance => _instance;

  void updateScroll(BooruAPI booru, double pos, int? page, {double? tagPos}) {
    _instance.writeTxnSync(() => _instance.scrollPositionPrimarys
        .putSync(ScrollPositionPrimary(pos, page: page, tagPos: tagPos)));
  }

  void updateScrollSecondary(Isar isar, double pos, String tags, int? page,
      {int? selectedPost, double? scrollPositionTags}) {
    isar.writeTxnSync(() => isar.secondaryGrids.putSync(SecondaryGrid(
        tags, scrollPositionTags, selectedPost, pos,
        page: page)));
  }

  Isar newSecondaryGrid() {
    var p = DateTime.now().microsecondsSinceEpoch.toString();

    _instance
        .writeTxnSync(() => _instance.gridRestores.putSync(GridRestore(p)));

    return Isar.openSync([PostSchema, SecondaryGridSchema],
        directory: _directoryPath, inspector: false, name: p);
  }

  void removeSecondaryGrid(String name) {
    var grid =
        _instance.gridRestores.filter().pathEqualTo(name).findFirstSync();
    if (grid != null) {
      var db = Isar.getInstance(grid.path);
      if (db != null) {
        db.close(deleteFromDisk: true);
      }
      _instance.writeTxnSync(() => _instance.gridRestores.deleteSync(grid.id!));
    }
  }

  void restoreState(BuildContext context) {
    var toRestore =
        _instance.gridRestores.where().sortByDateDesc().findAllSync();

    Navigator.of(context).pushReplacementNamed("/booru");

    _restoreState(context, toRestore, true);
  }

  void _restoreState(
      BuildContext context, List<GridRestore> toRestore, bool push) {
    if (toRestore.isEmpty) {
      if (!push) {
        Navigator.pop(context);
      }
      return;
    }

    for (true;;) {
      var restore = toRestore.removeAt(0);

      var isarR = _restoreIsarGrid(restore.path);

      var state = isarR.secondaryGrids.getSync(0);

      if (state == null) {
        removeSecondaryGrid(isarR.name);
        continue;
      }

      var page = MaterialPageRoute(
        builder: (context) {
          return BooruScroll.restore(
            grids: this,
            instance: isarR,
            tags: state.tags,
            initalScroll: state.scrollPositionGrid,
            pageViewScrollingOffset: state.scrollPositionTags,
            initalPost: state.selectedPost,
            booruPage: state.page,
          );
        },
      );

      if (push) {
        Navigator.push(context, page);
      } else {
        Navigator.pushReplacement(
          context,
          page,
        );
      }

      break;
    }
  }

  void restoreStateNext(BuildContext context, String exclude) {
    var toRestore = _instance.gridRestores
        .where()
        .pathNotEqualTo(exclude)
        .sortByDateDesc()
        .findAllSync();

    _restoreState(context, toRestore, false);
  }

  GridTab._new(this._instance)
      : _excluded =
            IsarBooruTagging(excludedMode: true, isarCurrent: _instance),
        _latest = IsarBooruTagging(excludedMode: false, isarCurrent: _instance);
}

GridTab makeGridTab(Booru newBooru) {
  return GridTab._new(_primaryGridIsar(newBooru));
}

class IsarBooruTagging implements BooruTagging {
  final Isar isarCurrent;
  final bool excludedMode;

  @override
  List<Tag> get() {
    return isarCurrent.tags
        .filter()
        .isExcludedEqualTo(excludedMode)
        .sortByTimeDesc()
        .findAllSync();
  }

  @override
  void add(Tag t) {
    var instance = isarCurrent;

    instance.writeTxnSync(() => instance.tags
        .putByTagIsExcludedSync(t.copyWith(isExcluded: excludedMode)));
  }

  @override
  void delete(Tag t) {
    var instance = isarCurrent;

    instance.writeTxnSync(
        () => instance.tags.deleteByTagIsExcludedSync(t.tag, excludedMode));
  }

  @override
  void clear() {
    var instance = isarCurrent;

    instance.writeTxnSync(() {
      var all = instance.tags
          .filter()
          .isExcludedEqualTo(excludedMode)
          .findAllSync()
          .map((e) => e.isarId!)
          .toList();
      instance.tags.deleteAllSync(all);
    });
  }

  const IsarBooruTagging(
      {required this.excludedMode, required this.isarCurrent});
}