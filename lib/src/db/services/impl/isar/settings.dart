// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "impl.dart";

class IsarSettingsService implements SettingsService {
  IsarSettingsService();

  Isar get db => Dbs().main;

  IsarCollection<IsarSettings> get collection => db.isarSettings;

  @override
  late SettingsData current =
      collection.getSync(0) ?? const IsarSettings.empty();

  @visibleForTesting
  void clearStorageTest_() {
    db.writeTxnSync(() {
      collection.clearSync();
    });

    current = const IsarSettings.empty();
  }

  @override
  void add(SettingsData data) {
    db.writeTxnSync(
      () {
        collection.putSync(data as IsarSettings);

        current = data;
      },
    );
  }

  /// Pick an operating system directory.
  /// Calls [onError] in case of any error and resolves to false.
  @override
  Future<bool> chooseDirectory(
    void Function(String) onError,
    AppLocalizations l10n,
  ) async {
    late final SettingsPath resp;

    try {
      resp = await gallery.GalleryApi().chooseDirectory(l10n).then(
            (e) =>
                IsarSettingsPath(path: e!.path, pathDisplay: e.formattedPath),
          );
    } catch (e, trace) {
      Logger.root.severe("chooseDirectory", e, trace);
      onError(l10n.emptyResult);
      return false;
    }

    current.copy(path: resp).save();

    return Future.value(true);
  }

  @override
  StreamSubscription<SettingsData?> watch(
    void Function(SettingsData? s) f, [
    bool fire = false,
  ]) =>
      collection.watchObject(0, fireImmediately: fire).listen(f);
}
