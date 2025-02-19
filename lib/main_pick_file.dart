// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "main.dart";

/// Entrypoint for the second Android's Activity.
/// Picks a file and returns to the app requested.
@pragma("vm:entry-point")
Future<void> mainPickfile() async {
  final notificationStream =
      StreamController<NotificationRouteEvent>.broadcast();

  await initMain(AppInstanceType.pickFile, notificationStream);

  final accentColor = await PlatformApi().accentColor;

  runApp(
    Services.inject(
      Builder(
        builder: (context) {
          final db = Services.of(context);
          final (tagManager,) = (db.get<TagManagerService>(),);

          return PinnedTagsHolder(
            pinnedTags: tagManager?.pinned,
            child: MaterialApp(
              title: "Azari",
              themeAnimationCurve: Easing.standard,
              themeAnimationDuration: const Duration(milliseconds: 300),
              darkTheme: buildTheme(context, Brightness.dark, accentColor),
              theme: buildTheme(context, Brightness.light, accentColor),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) => WrapGridPage(
                  addScaffoldAndBar: true,
                  child: DirectoriesPage(
                    l10n: context.l10n(),
                    callback: ReturnFileCallback(
                      choose: (chosen, [_]) {
                        PlatformApi().closeApp(chosen.originalUri);

                        return Future.value();
                      },
                      preview: PreferredSize(
                        preferredSize:
                            Size.fromHeight(CopyMovePreview.size.toDouble()),
                        child: IgnorePointer(
                          child: Builder(
                            builder: (context) {
                              final l10n = context.l10n();

                              return CopyMovePreview(
                                files: null,
                                title: l10n.pickFileNotice,
                                icon: Icons.file_open_rounded,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    directoryMetadata: db.get<DirectoryMetadataService>(),
                    directoryTags: db.get<DirectoryTagService>(),
                    favoritePosts: db.get<FavoritePostSourceService>(),
                    blacklistedDirectories:
                        db.get<BlacklistedDirectoryService>(),
                    miscSettingsService: db.get<MiscSettingsService>(),
                    localTagsService: db.get<LocalTagsService>(),
                    galleryService: db.get<GalleryService>()!,
                    gridDbs: db.get<GridDbService>()!,
                    gridSettings: db.get<GridSettingsService>()!,
                    settingsService: db.require<SettingsService>(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
