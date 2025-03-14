// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension DirectoryMetadataDataExt on DirectoryMetadata {
  void maybeSave() =>
      _currentDb.get<DirectoryMetadataService>()?.addAll([this]);
}

extension GetOrCreateDirMetadataCacheExt on DirectoryMetadataService {
  DirectoryMetadata getOrCreate(String id) {
    final d = cache.get(id);
    if (d != null) {
      return d;
    }

    final newD = DirectoryMetadata(categoryName: id, time: DateTime.now());

    addAll([newD]);

    return newD;
  }

  Future<bool> canAuth(String id, String reason) async {
    if (!AppInfo().canAuthBiometric) {
      return true;
    }

    final directoryMetadata = _currentDb.get<DirectoryMetadataService>();
    if (directoryMetadata == null) {
      return true;
    }

    if (cache.get(id)?.requireAuth ?? false) {
      final success =
          await LocalAuthentication().authenticate(localizedReason: reason);
      if (!success) {
        return false;
      }
    }

    return true;
  }
}

extension DirectoryMetadataCacheFindHelpersExt on DirectoryMetadataCache {
  List<DirectoryMetadata?> getAllNulled(List<String> ids) {
    final ret = <DirectoryMetadata?>[];

    for (final id in ids) {
      ret.add(get(id));
    }

    return ret;
  }
}

abstract interface class DirectoryMetadataService implements ServiceMarker {
  DirectoryMetadataCache get cache;

  void addAll(List<DirectoryMetadata> data);
}

abstract class DirectoryMetadataCache
    extends ReadOnlyStorage<String, DirectoryMetadata> {}

@immutable
abstract class DirectoryMetadata {
  const factory DirectoryMetadata({
    required String categoryName,
    required DateTime time,
  }) = $DirectoryMetadata;

  String get categoryName;
  DateTime get time;

  bool get blur;
  bool get requireAuth;
  bool get sticky;

  DirectoryMetadata copyBools({
    bool? blur,
    bool? sticky,
    bool? requireAuth,
  });
}

class DirectoryMetadataSegments implements SegmentCapability {
  const DirectoryMetadataSegments(this.specialLabel, this.db);

  final DirectoryMetadataService db;

  final String specialLabel;

  @override
  bool get ignoreButtons => false;

  @override
  Set<SegmentModifier> get(String seg) {
    if (seg.isEmpty) {
      return const {};
    }

    if (seg == "Booru" || seg == specialLabel) {
      return const {SegmentModifier.sticky};
    }

    final m = db.cache.get(seg);
    if (m == null) {
      return const {};
    }

    final set = <SegmentModifier>{};

    if (m.blur) {
      set.add(SegmentModifier.blur);
    }

    if (m.requireAuth) {
      set.add(SegmentModifier.auth);
    }

    if (m.sticky) {
      set.add(SegmentModifier.sticky);
    }

    return set;
  }

  @override
  void add(List<String> segments_, Set<SegmentModifier> m) {
    final segments = segments_
        .where((element) => element != "Booru" && element != specialLabel)
        .toList();

    if (segments.isEmpty || m.isEmpty) {
      return;
    }

    final l = db.cache.getAllNulled(segments).indexed.map(
          (element) =>
              element.$2 ??
              DirectoryMetadata(
                categoryName: segments[element.$1],
                time: DateTime.now(),
              ),
        );
    final toUpdate = <DirectoryMetadata>[];

    for (var seg in l) {
      for (final e in m) {
        switch (e) {
          case SegmentModifier.blur:
            seg = seg.copyBools(blur: true);
          case SegmentModifier.auth:
            seg = seg.copyBools(requireAuth: true);
          case SegmentModifier.sticky:
            seg = seg.copyBools(sticky: true);
        }
      }

      toUpdate.add(seg);
    }

    db.addAll(toUpdate);
  }

  @override
  void remove(List<String> segments_, Set<SegmentModifier> m) {
    final segments = segments_
        .where((element) => element != "Booru" && element != specialLabel)
        .toList();

    if (segments.isEmpty || m.isEmpty) {
      return;
    }

    final l = db.cache.getAllNulled(segments).indexed.map(
          (e) =>
              e.$2 ??
              DirectoryMetadata(
                categoryName: segments[e.$1],
                time: DateTime.now(),
              ),
        );
    final toUpdate = <DirectoryMetadata>[];

    for (var seg in l) {
      for (final e in m) {
        switch (e) {
          case SegmentModifier.blur:
            seg = seg.copyBools(blur: false);
          case SegmentModifier.auth:
            seg = seg.copyBools(requireAuth: false);
          case SegmentModifier.sticky:
            seg = seg.copyBools(sticky: false);
        }
      }

      toUpdate.add(seg);
    }

    db.addAll(toUpdate);
  }
}
