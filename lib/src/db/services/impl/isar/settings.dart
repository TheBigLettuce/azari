// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "impl.dart";

@immutable
class IsarSettingsService implements SettingsService {
  const IsarSettingsService();

  @override
  void add(SettingsData data) => _Dbs.g.main.writeTxnSync(
        () => _Dbs.g.main.isarSettings.putSync(data as IsarSettings),
      );

  /// Pick an operating system directory.
  /// Calls [onError] in case of any error and resolves to false.
  @override
  Future<bool> chooseDirectory(
      void Function(String) onError, AppLocalizations l10n) async {
    late final SettingsPath resp;

    try {
      resp = await GalleryManagementApi.current()
          .chooseDirectory(l10n)
          .then((e) => IsarSettingsPath(path: e!.$2, pathDisplay: e.$1));
    } catch (e) {
      onError(l10n.emptyResult);
      return false;
    }

    current.copy(path: resp).save();

    return Future.value(true);
  }

  @override
  SettingsData get current =>
      _Dbs.g.main.isarSettings.getSync(0) ??
      const IsarSettings(
        extraSafeFilters: true,
        showAnimeMangaPages: false,
        showWelcomePage: true,
        path: IsarSettingsPath(),
        selectedBooru: Booru.gelbooru,
        quality: DisplayQuality.sample,
        safeMode: SafeMode.normal,
      );

  @override
  StreamSubscription<SettingsData?> watch(
    void Function(SettingsData? s) f, [
    bool fire = false,
  ]) =>
      _Dbs.g.main.isarSettings.watchObject(0, fireImmediately: fire).listen(f);
}
