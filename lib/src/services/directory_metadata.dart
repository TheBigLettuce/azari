// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension DirectoryMetadataDataExt on DirectoryMetadata {
  void maybeSave() =>
      _dbInstance.get<DirectoryMetadataService>()?.addAll([this]);
}

mixin class DirectoryMetadataService implements ServiceMarker {
  const DirectoryMetadataService();

  static bool get available => _instance != null;
  static DirectoryMetadataService? safe() => _instance;

  // ignore: unnecessary_late
  static late final _instance = _dbInstance.get<DirectoryMetadataService>();

  DirectoryMetadataCache get cache => _instance!.cache;

  void addAll(List<DirectoryMetadata> data) => _instance!.addAll(data);
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
    if (!const AppApi().canAuthBiometric) {
      return true;
    }

    final directoryMetadata = _dbInstance.get<DirectoryMetadataService>();
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
