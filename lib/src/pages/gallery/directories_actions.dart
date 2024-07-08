// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/init_main/app_info.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/booru/booru_api.dart";
import "package:gallery/src/pages/gallery/callback_description.dart";
import "package:gallery/src/pages/gallery/files.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/widgets/glue_provider.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:local_auth/local_auth.dart";

GridAction<GalleryDirectory> blacklist(
  BuildContext context,
  String Function(GalleryDirectory) segment,
  DirectoryMetadataService directoryMetadata,
  BlacklistedDirectoryService blacklistedDirectory,
  AppLocalizations l10n,
) {
  return GridAction(
    Icons.hide_image_outlined,
    (selected) {
      final requireAuth = <BlacklistedDirectoryData>[];
      final noAuth = <BlacklistedDirectoryData>[];

      for (final e in selected) {
        final m = directoryMetadata.get(segment(e));
        if (m != null && m.requireAuth) {
          requireAuth.add(
            BlacklistedDirectoryData(bucketId: e.bucketId, name: e.name),
          );
        } else {
          noAuth.add(
            BlacklistedDirectoryData(bucketId: e.bucketId, name: e.name),
          );
        }
      }

      if (noAuth.isNotEmpty) {
        if (requireAuth.isNotEmpty && !AppInfo().canAuthBiometric) {
          blacklistedDirectory.backingStorage.addAll(noAuth + requireAuth);
          return;
        }

        blacklistedDirectory.backingStorage.addAll(noAuth);
      }

      if (requireAuth.isNotEmpty) {
        if (AppInfo().canAuthBiometric) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.directoriesAuthMessage),
              action: SnackBarAction(
                label: l10n.authLabel,
                onPressed: () async {
                  final success = await LocalAuthentication().authenticate(
                    localizedReason: l10n.hideDirectoryReason,
                  );
                  if (!success) {
                    return;
                  }

                  blacklistedDirectory.backingStorage.addAll(requireAuth);
                },
              ),
            ),
          );
        } else {
          blacklistedDirectory.backingStorage.addAll(requireAuth);
        }
      }
    },
    true,
  );
}

GridAction<GalleryDirectory> joinedDirectories(
  BuildContext context,
  GalleryAPIDirectories api,
  CallbackDescriptionNested? callback,
  SelectionGlue Function([Set<GluePreferences>])? generate,
  String Function(GalleryDirectory) segment,
  DirectoryMetadataService directoryMetadata,
  DirectoryTagService directoryTags,
  FavoriteFileService favoriteFile,
  LocalTagsService localTags,
  AppLocalizations l10n,
) {
  return GridAction(
    Icons.merge_rounded,
    (selected) {
      joinedDirectoriesFnc(
        context,
        selected.length == 1
            ? selected.first.name
            : "${selected.length} ${l10n.directoriesPlural}",
        selected,
        api,
        callback,
        generate,
        segment,
        directoryMetadata,
        directoryTags,
        favoriteFile,
        localTags,
        l10n,
      );
    },
    true,
  );
}

Future<void> joinedDirectoriesFnc(
  BuildContext context,
  String label,
  List<GalleryDirectory> dirs,
  GalleryAPIDirectories api,
  CallbackDescriptionNested? callback,
  SelectionGlue Function([Set<GluePreferences>])? generate,
  String Function(GalleryDirectory) segment,
  DirectoryMetadataService directoryMetadata,
  DirectoryTagService directoryTags,
  FavoriteFileService favoriteFile,
  LocalTagsService localTags,
  AppLocalizations l10n,
) {
  bool requireAuth = false;

  for (final e in dirs) {
    final auth = directoryMetadata.get(segment(e))?.requireAuth ?? false;
    if (auth) {
      requireAuth = true;
      break;
    }
  }

  Future<void> onSuccess(bool success) {
    if (!success || !context.mounted) {
      return Future.value();
    }

    StatisticsGalleryService.db().current.add(joined: 1).save();

    final joined = api.joinedFiles(
      dirs,
      directoryTags,
      directoryMetadata,
      favoriteFile,
      localTags,
    );

    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return GalleryFiles(
            secure: requireAuth,
            generateGlue: generate,
            api: joined,
            callback: callback,
            directory: null,
            dirName: label,
            bucketId: "joinedDir",
            db: DatabaseConnectionNotifier.of(context),
            tagManager: TagManager.of(context),
          );
        },
      ),
    );
  }

  if (requireAuth && AppInfo().canAuthBiometric) {
    return LocalAuthentication()
        .authenticate(localizedReason: l10n.joinDirectoriesReason)
        .then(onSuccess);
  } else {
    return onSuccess(true);
  }
}

GridAction<T> addToGroup<T extends CellBase>(
  BuildContext context,
  String? Function(List<T>) initalValue,
  Future<void Function(BuildContext)?> Function(List<T>, String, bool)
      onSubmitted,
  bool showPinButton, {
  Future<List<BooruTag>> Function(String str)? completeDirectoryNameTag,
}) {
  return GridAction(
    Icons.group_work_outlined,
    (selected) {
      if (selected.isEmpty) {
        return;
      }

      Navigator.of(context, rootNavigator: true).push(
        DialogRoute<void>(
          context: context,
          builder: (context) {
            return _GroupDialogWidget<T>(
              initalValue: initalValue,
              onSubmitted: onSubmitted,
              selected: selected,
              showPinButton: showPinButton,
              completeDirectoryNameTag: completeDirectoryNameTag,
            );
          },
        ),
      );
    },
    false,
  );
}

class _GroupDialogWidget<T> extends StatefulWidget {
  const _GroupDialogWidget({
    super.key,
    required this.initalValue,
    required this.onSubmitted,
    required this.selected,
    required this.showPinButton,
    required this.completeDirectoryNameTag,
  });

  final List<T> selected;
  final String? Function(List<T>) initalValue;
  final Future<void Function(BuildContext)?> Function(List<T>, String, bool)
      onSubmitted;
  final Future<List<BooruTag>> Function(String str)? completeDirectoryNameTag;
  final bool showPinButton;

  @override
  State<_GroupDialogWidget<T>> createState() => __GroupDialogWidgetState();
}

class __GroupDialogWidgetState<T> extends State<_GroupDialogWidget<T>> {
  bool toPin = false;

  final focus = FocusNode();
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    focus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.group),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SearchBarAutocompleteWrapper(
            search: BarSearchWidget(
              textEditingController: controller,
              onChange: null,
              complete: widget.completeDirectoryNameTag,
            ),
            child: (context, controller, focus, onSubmitted) {
              return TextFormField(
                autofocus: true,
                focusNode: focus,
                controller: controller,
                // initialValue: widget.initalValue(widget.selected),
                onFieldSubmitted: (value) {
                  onSubmitted();
                  widget.onSubmitted(widget.selected, value, toPin).then((e) {
                    if (context.mounted) {
                      e?.call(context);

                      Navigator.pop(context);
                    }
                  });
                },
              );
            },
            searchFocus: focus,
          ),
          if (widget.showPinButton)
            SwitchListTile(
              title: Text(l10n.pinGroupLabel),
              value: toPin,
              onChanged: (b) {
                toPin = b;

                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}
