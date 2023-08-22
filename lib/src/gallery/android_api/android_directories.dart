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
import 'package:gallery/src/pages/senitel.dart';
import 'package:gallery/src/schemas/android_gallery_directory.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';
import 'package:gallery/src/schemas/blacklisted_directory.dart';
import 'package:gallery/src/schemas/pinned_directories.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:gallery/src/widgets/search_filter_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import '../../booru/interface.dart';
import '../../schemas/settings.dart';

class CallbackDescription {
  final void Function(SystemGalleryDirectory? chosen, String? newDir) c;
  final String description;

  void call(SystemGalleryDirectory? chosen, String? newDir) {
    c(chosen, newDir);
  }

  const CallbackDescription(this.description, this.c);
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
  const AndroidDirectories(
      {super.key, this.callback, this.nestedCallback, this.noDrawer})
      : assert(!(callback != null && nestedCallback != null));

  @override
  State<AndroidDirectories> createState() => _AndroidDirectoriesState();
}

class _AndroidDirectoriesState extends State<AndroidDirectories>
    with SearchFilterGrid<SystemGalleryDirectory> {
  late StreamSubscription<Settings?> settingsWatcher;
  bool proceed = true;
  late final extra = api.getExtra()
    ..setOnThumbnailCallback(() {
      if (!proceed) {
        return;
      }
      proceed = false;
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        state.gridKey.currentState?.setState(() {
          proceed = true;
        });
      });
    })
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
          onWillPop: () => popUntilSenitel(context));
  late final api = getAndroidGalleryApi(
      temporaryDb: widget.callback != null || widget.nestedCallback != null,
      setCurrentApi: widget.callback == null);
  final stream = StreamController<int>(sync: true);

  bool isThumbsLoading = false;

  @override
  void initState() {
    super.initState();
    settingsWatcher = settingsIsar().settings.watchObject(0).listen((event) {
      state.settings = event!;

      setState(() {});
    });
    searchHook(state);

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

  void _refresh() {
    stream.add(0);
    state.gridKey.currentState?.mutationInterface?.setIsRefreshing(true);
    api.refresh();
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
                            Navigator.pop(context);
                          } catch (e) {
                            log("new folder in android_directories",
                                level: Level.SEVERE.value, error: e);
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.create_new_folder_outlined))
                  ]
                : [
                    IconButton(
                        onPressed: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return AndroidFiles(
                                api: extra.trash(),
                                callback: widget.nestedCallback,
                                dirName: "trash",
                                bucketId: "trash");
                          }));
                        },
                        icon: const Icon(Icons.delete)),
                    IconButton(
                        onPressed: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return AndroidFiles(
                                api: extra.favorites(),
                                callback: widget.nestedCallback,
                                dirName: "favorites",
                                bucketId: "favorites");
                          }));
                        },
                        icon: const Icon(Icons.star_border_outlined))
                  ],
            aspectRatio:
                state.settings.gallerySettings.directoryAspectRatio?.value ?? 1,
            hideAlias: state.settings.gallerySettings.hideDirectoryName,
            immutable: false,
            segments: Segments(
              (cell) {
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
                  name.first,
                  blacklistedDirIsar()
                          .pinnedDirectories
                          .getSync(fastHash(name.first)) !=
                      null
                );
              },
              "Uncategorized",
              addToSticky: (seg, {unsticky}) {
                if (seg == "Booru") {
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
            ),
            mainFocus: state.mainFocus,
            loadThumbsDirectly: extra.loadThumbs,
            initalCellCount: widget.callback != null
                ? extra.db.systemGalleryDirectorys.countSync()
                : 0,
            searchWidget: SearchAndFocus(
                searchWidget(context,
                    hint: AppLocalizations.of(context)!.directoriesHint),
                searchFocus),
            refresh: () {
              if (widget.callback != null) {
                return Future.value(
                    extra.db.systemGalleryDirectorys.countSync());
              } else {
                _refresh();

                return null;
              }
            },
            overrideOnPress: (context, indx) {
              if (widget.callback != null) {
                widget.callback!(
                    state.gridKey.currentState!.mutationInterface!
                        .getCell(indx),
                    null);
                Navigator.pop(context);
              } else {
                var d = state.gridKey.currentState!.mutationInterface!
                    .getCell(indx);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AndroidFiles(
                          api: api.images(d),
                          dirName: d.name,
                          callback: widget.nestedCallback,
                          bucketId: d.bucketId),
                    ));
              }
            },
            progressTicker: stream.stream,
            hideShowFab: ({required bool fab, required bool foreground}) =>
                state.updateFab(setState, fab: fab, foreground: foreground),
            description: GridDescription(
                kGalleryDrawerIndex,
                widget.callback != null || widget.nestedCallback != null
                    ? []
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
                                      title: const Text(
                                          "Current tag"), // TODO: change
                                      content: ListTile(
                                        title: Text(currentTag ?? "none",
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
                                                        title: const Text(
                                                            "Enter new tag"), // TODO: change
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
                                                                      selected[
                                                                              0]
                                                                          .bucketId,
                                                                      value);
                                                              setState(() {});
                                                              Navigator.pop(
                                                                  context);
                                                              Navigator.pop(
                                                                  context);
                                                            } else {
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      const SnackBar(
                                                                          content:
                                                                              Text("Value is empty"))); // TODO : change
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
                        }, true, showOnlyWhenSingle: true),
                        GridBottomSheetAction(Icons.hide_image_outlined,
                            (selected) {
                          extra.addBlacklisted(selected
                              .map((e) =>
                                  BlacklistedDirectory(e.bucketId, e.name))
                              .toList());
                        }, true)
                      ],
                state.settings.gallerySettings.directoryColumns ??
                    GridColumn.two,
                listView: state.settings.listViewBooru,
                bottomWidget:
                    widget.callback == null && widget.nestedCallback == null
                        ? null
                        : gridBottomWidgetText(
                            context,
                            widget.callback != null
                                ? widget.callback!.description
                                : widget.nestedCallback!.description),
                keybindsDescription:
                    AppLocalizations.of(context)!.androidGKeybindsDescription)),
        popSenitel: widget.callback == null && widget.nestedCallback == null,
        noDrawer: widget.noDrawer ?? false);
  }
}

PreferredSizeWidget gridBottomWidgetText(BuildContext context, String title) =>
    PreferredSize(
      preferredSize: const Size.fromHeight(12),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          title,
          style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.8)),
        ),
      ),
    );
