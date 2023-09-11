// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/db/platform_channel.dart';
import 'package:gallery/src/gallery/android_api/android_api_directories.dart';
import 'package:gallery/src/gallery/android_api/android_files.dart';
import 'package:gallery/src/schemas/android_gallery_directory.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';
import 'package:gallery/src/schemas/blacklisted_directory.dart';
import 'package:gallery/src/schemas/favorite_media.dart';
import 'package:gallery/src/schemas/pinned_directories.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:gallery/src/widgets/copy_move_hint_text.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:gallery/src/widgets/search_filter_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import '../../booru/interface.dart';
import '../../schemas/settings.dart';

class CallbackDescription {
  final Future<void> Function(SystemGalleryDirectory? chosen, String? newDir) c;
  final String description;

  final PreferredSizeWidget? preview;

  void call(SystemGalleryDirectory? chosen, String? newDir) {
    c(chosen, newDir);
  }

  const CallbackDescription(this.description, this.c, {this.preview});
}

class CallbackDescriptionNested {
  final void Function(SystemGalleryDirectoryFile chosen) c;
  final String description;

  void call(SystemGalleryDirectoryFile chosen) {
    c(chosen);
  }

  const CallbackDescriptionNested(this.description, this.c);
}

class AndroidDirectories extends StatefulWidget {
  final CallbackDescription? callback;
  final CallbackDescriptionNested? nestedCallback;
  final bool? noDrawer;
  final bool showBackButton;
  const AndroidDirectories(
      {super.key,
      this.callback,
      this.nestedCallback,
      this.noDrawer,
      this.showBackButton = false})
      : assert(!(callback != null && nestedCallback != null));

  @override
  State<AndroidDirectories> createState() => _AndroidDirectoriesState();
}

class _AndroidDirectoriesState extends State<AndroidDirectories>
    with SearchFilterGrid<SystemGalleryDirectory> {
  late StreamSubscription<Settings?> settingsWatcher;
  bool proceed = true;
  late final extra = api.getExtra()
    ..setRefreshGridCallback(() {
      if (state.gridKey.currentState?.mutationInterface?.isRefreshing ==
          false) {
        _refresh();
      }
    });

  late final GridSkeletonStateFilter<SystemGalleryDirectory> state =
      GridSkeletonStateFilter(
    transform: (cell, _) => cell,
    filter: extra.filter,
    index: kGalleryDrawerIndex,
  );
  late final api = getAndroidGalleryApi(
      temporaryDb: widget.callback != null || widget.nestedCallback != null,
      setCurrentApi: widget.callback == null);
  final stream = StreamController<int>(sync: true);

  bool isThumbsLoading = false;

  int? trashThumbId;

  @override
  void initState() {
    super.initState();
    settingsWatcher = settingsIsar().settings.watchObject(0).listen((event) {
      state.settings = event!;

      setState(() {});
    });
    searchHook(state);

    if (widget.callback != null) {
      PlatformFunctions.trashThumbId().then((value) {
        try {
          setState(() {
            trashThumbId = value;
          });
        } catch (_) {}
      });
    }

    extra.setRefreshingStatusCallback((i, inRefresh, empty) {
      state.gridKey.currentState?.mutationInterface?.unselectAll();

      stream.add(i);

      if (!inRefresh || empty) {
        state.gridKey.currentState?.mutationInterface?.setIsRefreshing(false);
        performSearch(searchTextController.text);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    api.close();
    stream.close();
    settingsWatcher.cancel();
    disposeSearch();
    state.dispose();
    clearTemporaryImagesDir();
    super.dispose();
  }

  void _joinedDirectories(String label, List<SystemGalleryDirectory> dirs) {
    if (widget.callback != null || widget.nestedCallback != null) {
      return;
    }

    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return AndroidFiles(
            api: extra.joinedDir(dirs.map((e) => e.bucketId).toList()),
            callback: widget.nestedCallback,
            dirName: label,
            bucketId: "joinedDir");
      },
    ));
  }

  void _refresh() {
    PlatformFunctions.trashThumbId().then((value) {
      try {
        setState(() {
          trashThumbId = value;
        });
      } catch (_) {}
    });
    stream.add(0);
    state.gridKey.currentState?.mutationInterface?.setIsRefreshing(true);
    api.refresh();
  }

  GridBottomSheetAction<SystemGalleryDirectory> _joinedDirectoriesAction() {
    return GridBottomSheetAction(Icons.merge_rounded, (selected) {
      _joinedDirectories(
        selected.length == 1
            ? selected.first.name
            : "${selected.length} ${AppLocalizations.of(context)!.directoriesPlural}",
        selected,
      );
    },
        true,
        GridBottomSheetActionExplanation(
          label: AppLocalizations.of(context)!.joinActionLabel,
          body: AppLocalizations.of(context)!.joinActionBody,
        ));
  }

  @override
  Widget build(BuildContext context) {
    var insets = MediaQuery.viewPaddingOf(context);

    return makeGridSkeleton<SystemGalleryDirectory>(
      context,
      state,
      CallbackGrid(
          key: state.gridKey,
          getCell: (i) => api.directCell(i),
          initalScrollPosition: 0,
          scaffoldKey: state.scaffoldKey,
          onBack: widget.showBackButton ? () => Navigator.pop(context) : null,
          systemNavigationInsets: insets,
          hasReachedEnd: () => true,
          inlineMenuButtonItems: true,
          menuButtonItems: widget.callback != null
              ? [
                  IconButton(
                      onPressed: () async {
                        try {
                          widget.callback!(
                              null,
                              await PlatformFunctions.chooseDirectory(
                                  temporary: true));
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                        } catch (e) {
                          log("new folder in android_directories",
                              level: Level.SEVERE.value, error: e);
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.create_new_folder_outlined))
                ]
              : null,
          aspectRatio: state
              .settings.gallerySettings.directoryAspectRatio.value,
          hideAlias: state.settings.gallerySettings.hideDirectoryName,
          immutable: false,
          segments: Segments(
            "Uncategorized",
            segment: (cell) {
              for (final booru in Booru.values) {
                if (booru.url == cell.name) {
                  return ("Booru", true);
                }
              }

              final dirTag = PostTags().directoryTag(cell.bucketId);
              if (dirTag != null) {
                return (
                  dirTag,
                  blacklistedDirIsar()
                          .pinnedDirectories
                          .getSync(fastHash(dirTag)) !=
                      null
                );
              }

              final name = cell.name.split(" ");
              return (
                name.first.toLowerCase(),
                blacklistedDirIsar()
                        .pinnedDirectories
                        .getSync(fastHash(name.first.toLowerCase())) !=
                    null
              );
            },
            addToSticky: (seg, {unsticky}) {
              if (seg == "Booru" || seg == "Special") {
                return;
              }
              if (unsticky == true) {
                blacklistedDirIsar().writeTxnSync(() {
                  blacklistedDirIsar()
                      .pinnedDirectories
                      .deleteSync(fastHash(seg));
                });
              } else {
                blacklistedDirIsar().writeTxnSync(() {
                  blacklistedDirIsar()
                      .pinnedDirectories
                      .putSync(PinnedDirectories(seg, DateTime.now()));
                });
              }
            },
            injectedSegments: [
              if (blacklistedDirIsar().favoriteMedias.countSync() != 0)
                SystemGalleryDirectory(
                    bucketId: "favorites",
                    name: "Favorites", // change
                    tag: "",
                    volumeName: "",
                    relativeLoc: "",
                    lastModified: 0,
                    thumbFileId: blacklistedDirIsar()
                        .favoriteMedias
                        .where()
                        .sortByTimeDesc()
                        .findFirstSync()!
                        .id),
              if (trashThumbId != null)
                SystemGalleryDirectory(
                    bucketId: "trash",
                    name: "Trash", // change
                    tag: "",
                    volumeName: "",
                    relativeLoc: "",
                    lastModified: 0,
                    thumbFileId: trashThumbId!),
            ],
            onLabelPressed: _joinedDirectories,
          ),
          mainFocus: state.mainFocus,
          footer: widget.callback?.preview,
          initalCellCount: widget.callback != null
              ? extra.db.systemGalleryDirectorys.countSync()
              : 0,
          searchWidget: SearchAndFocus(
              searchWidget(context,
                  hint: AppLocalizations.of(context)!.directoriesHint),
              searchFocus),
          refresh: () {
            if (widget.callback != null) {
              PlatformFunctions.trashThumbId().then((value) {
                try {
                  setState(() {
                    trashThumbId = value;
                  });
                } catch (_) {}
              });
              return Future.value(extra.db.systemGalleryDirectorys.countSync());
            } else {
              _refresh();

              return null;
            }
          },
          overrideOnPress: (context, cell) {
            if (widget.callback != null) {
              widget.callback!.c(cell, null).then((_) {
                Navigator.pop(context);
              });
            } else {
              final d = cell;

              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => switch (cell.bucketId) {
                      "favorites" => AndroidFiles(
                          api: extra.favorites(),
                          callback: widget.nestedCallback,
                          dirName: "favorites",
                          bucketId: "favorites"),
                      "trash" => AndroidFiles(
                          api: extra.trash(),
                          callback: widget.nestedCallback,
                          dirName: "trash",
                          bucketId: "trash"),
                      String() => AndroidFiles(
                          api: api.files(d),
                          dirName: d.name,
                          callback: widget.nestedCallback,
                          bucketId: d.bucketId)
                    },
                  ));
            }
          },
          progressTicker: stream.stream,
          hideShowFab: ({required bool fab, required bool foreground}) =>
              state.updateFab(setState, fab: fab, foreground: foreground),
          description: GridDescription(
              kGalleryDrawerIndex,
              widget.callback != null || widget.nestedCallback != null
                  ? [_joinedDirectoriesAction()]
                  : [
                      GridBottomSheetAction(Icons.tag, (selected) {
                        Navigator.push(
                            context,
                            DialogRoute(
                              context: context,
                              builder: (context) {
                                final currentTag = PostTags()
                                    .directoryTag(selected[0].bucketId);
                                return AlertDialog(
                                    title: Text(AppLocalizations.of(context)!
                                        .currentTagTitle),
                                    content: ListTile(
                                      title: Text(
                                          currentTag ??
                                              AppLocalizations.of(context)!
                                                  .directoryTagNone,
                                          style: currentTag == null
                                              ? const TextStyle(
                                                  fontStyle: FontStyle.italic)
                                              : null),
                                      leading: IconButton(
                                          onPressed: () {
                                            PostTags().removeDirectoryTag(
                                                selected[0].bucketId);
                                            setState(() {});
                                            Navigator.pop(context);
                                          },
                                          icon: const Icon(Icons.close)),
                                      trailing: IconButton(
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                DialogRoute(
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      title: Text(
                                                          AppLocalizations.of(
                                                                  context)!
                                                              .enterNewTagTitle),
                                                      content: TextFormField(
                                                        autofocus: true,
                                                        initialValue:
                                                            currentTag,
                                                        onFieldSubmitted:
                                                            (value) {
                                                          if (value
                                                              .isNotEmpty) {
                                                            PostTags()
                                                                .setDirectoryTag(
                                                                    selected[0]
                                                                        .bucketId,
                                                                    value);
                                                            setState(() {});
                                                            Navigator.pop(
                                                                context);
                                                            Navigator.pop(
                                                                context);
                                                          } else {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(SnackBar(
                                                                    content: Text(
                                                                        AppLocalizations.of(context)!
                                                                            .valueIsEmpty)));
                                                          }
                                                        },
                                                      ),
                                                    );
                                                  },
                                                ));
                                          },
                                          icon: const Icon(Icons.edit)),
                                    ));
                              },
                            ));
                      },
                          true,
                          GridBottomSheetActionExplanation(
                            label: AppLocalizations.of(context)!
                                .directoryTagActionLabel,
                            body: AppLocalizations.of(context)!
                                .directoryTagActionBody,
                          ),
                          showOnlyWhenSingle: true),
                      GridBottomSheetAction(Icons.hide_image_outlined,
                          (selected) {
                        extra.addBlacklisted(selected
                            .map(
                                (e) => BlacklistedDirectory(e.bucketId, e.name))
                            .toList());
                      },
                          true,
                          GridBottomSheetActionExplanation(
                            label: AppLocalizations.of(context)!
                                .blacklistActionLabel,
                            body: AppLocalizations.of(context)!
                                .blacklistActionBody,
                          )),
                      _joinedDirectoriesAction()
                    ],
              state.settings.gallerySettings.directoryColumns,
              listView: false,
              bottomWidget:
                  widget.callback != null || widget.nestedCallback != null
                      ? copyMoveHintText(
                          context,
                          widget.callback != null
                              ? widget.callback!.description
                              : widget.nestedCallback!.description)
                      : null,
              keybindsDescription:
                  AppLocalizations.of(context)!.androidGKeybindsDescription)),
      popSenitel: widget.callback == null && widget.nestedCallback == null,
      noDrawer: widget.noDrawer ?? false,
    );
  }
}
