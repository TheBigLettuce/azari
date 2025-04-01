// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "home.dart";

mixin _BeforeYouContinueDialogMixin {
  void maybeBeforeYouContinueDialog(
    BuildContext context,
    SettingsData settings,
    GalleryService galleryService,
  ) {
    if (settings.path.isEmpty) {
      WidgetsBinding.instance.scheduleFrameCallback(
        (timeStamp) {
          Navigator.push(
            context,
            DialogRoute<void>(
              context: context,
              builder: (context) {
                final l10n = context.l10n();

                return AlertDialog(
                  title: Text(l10n.beforeYouContinueTitle),
                  content: Text(l10n.needChooseDirectory),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(l10n.later),
                    ),
                    TextButton(
                      onPressed: FilesApi.available
                          ? () {
                              chooseDirectoryCallback((_) {}, l10n);

                              Navigator.pop(context);
                            }
                          : null,
                      child: Text(l10n.choose),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    }
  }
}

/// Pick an operating system directory.
/// Calls [onError] in case of any error and resolves to false.
Future<bool> chooseDirectoryCallback(
  void Function(String) onError,
  AppLocalizations l10n,
) async {
  late final ({String formattedPath, String path}) resp;

  try {
    resp = (await const FilesApi().chooseDirectory(l10n))!;
  } catch (e, trace) {
    Logger.root.severe("chooseDirectory", e, trace);
    onError(l10n.emptyResult);
    return false;
  }

  final current = const SettingsService().current;
  current
      .copy(
        path:
            current.path.copy(path: resp.path, pathDisplay: resp.formattedPath),
      )
      .save();

  return Future.value(true);
}
