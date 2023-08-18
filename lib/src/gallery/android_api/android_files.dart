// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/db/platform_channel.dart';
import 'package:gallery/src/gallery/android_api/android_api_directories.dart';
import 'package:gallery/src/gallery/android_api/android_directories.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';
import 'package:gallery/src/schemas/favorite_media.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import '../../schemas/settings.dart';
import '../../widgets/search_filter_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SameFilterAccumulator {
  final Map<int, Set<int>> data;
  int skipped;

  SameFilterAccumulator.empty()
      : data = {},
        skipped = 0;
}

class AndroidFiles extends StatefulWidget {
  final String dirName;
  final String bucketId;
  final GalleryAPIFiles<AndroidGalleryFilesExtra, SystemGalleryDirectoryFile>
      api;
  final CallbackDescriptionNested? callback;
  const AndroidFiles(
      {super.key,
      required this.api,
      this.callback,
      required this.dirName,
      required this.bucketId});

  @override
  State<AndroidFiles> createState() => _AndroidFilesState();
}

class _AndroidFilesState extends State<AndroidFiles>
    with SearchFilterGrid<SystemGalleryDirectoryFile> {
  late StreamSubscription<Settings?> settingsWatcher;
  bool proceed = true;
  late final AndroidGalleryFilesExtra extra = widget.api.getExtra()
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
    ..setRefreshingStatusCallback((i, inRefresh, empty) {
      if (empty && !extra.isTrash() && !extra.isFavorites()) {
        state.gridKey.currentState?.currentBottomSheet?.close();
        state.gridKey.currentState?.imageViewKey.currentState?.key.currentState
            ?.closeEndDrawer();
        final imageViewContext =
            state.gridKey.currentState?.imageViewKey.currentContext;
        if (imageViewContext != null) {
          Navigator.of(imageViewContext).pop();
        }
        Navigator.of(context).pop();
        return;
      }

      state.gridKey.currentState?.mutationInterface?.unselectAll();

      stream.add(i);

      if (!inRefresh) {
        state.gridKey.currentState?.imageViewKey.currentState
            ?.update(state.gridKey.currentState!.mutationInterface!.cellCount);
        state.gridKey.currentState?.mutationInterface?.setIsRefreshing(false);
        performSearch(searchTextController.text);
        setState(() {});
      }
    })
    ..setRefreshGridCallback(() {
      if (state.gridKey.currentState?.mutationInterface?.isRefreshing ==
          false) {
        _refresh();
      }
    })
    ..setPassFilter((cells, data, end) {
      return switch (currentFilteringMode()) {
        FilteringMode.favorite => _filterFavorite(cells),
        FilteringMode.noFilter => (cells, data),
        FilteringMode.same => _filterSame(cells, data, end),
        FilteringMode.tag => _filterTag(cells),
        FilteringMode.video => _filterVideo(cells),
        FilteringMode.gif => _filterGif(cells),
        FilteringMode.size => (cells, data),
        FilteringMode.duplicate => _filterDuplicate(cells),
        FilteringMode.original => _filterOriginal(cells)
      };
    });

  (Iterable<SystemGalleryDirectoryFile>, dynamic) _filterFavorite(
      Iterable<SystemGalleryDirectoryFile> cells) {
    return (cells.where((element) => element.isFavorite()), null);
  }

  (Iterable<SystemGalleryDirectoryFile>, dynamic) _filterTag(
      Iterable<SystemGalleryDirectoryFile> cells) {
    if (searchTextController.text.isEmpty) {
      return (cells, null);
    }

    return (
      cells.where((element) => PostTags()
          .containsTagMultiple(element.name, searchTextController.text)),
      null
    );
  }

  (Iterable<SystemGalleryDirectoryFile>, dynamic) _filterSame(
      Iterable<SystemGalleryDirectoryFile> cells,
      SameFilterAccumulator? accu,
      bool end) {
    accu ??= SameFilterAccumulator.empty();

    for (final (isarId, hash)
        in extra.getDifferenceHash(cells, state.settings.expensiveHash)) {
      if (hash == null) {
        accu.skipped++;
        continue;
      } else if (hash == 0) {
        continue;
      }

      final prev = accu.data[hash] ?? {};

      accu.data[hash] = {...prev, isarId};
    }

    if (end) {
      Iterable<SystemGalleryDirectoryFile> ret;

      if (state.settings.expensiveHash) {
        final Set<int> distanceSet = {};

        accu.data.removeWhere((key, value) {
          if (value.length > 1) {
            for (final e in value) {
              distanceSet.add(e);
            }
            return true;
          }
          return false;
        });

        for (final first in accu.data.keys) {
          for (final second in accu.data.keys) {
            if (first == second) {
              continue;
            }

            final distance = hammingDistance(first, second);
            if (distance < 3) {
              for (final e in accu.data[first]!) {
                distanceSet.add(e);
              }

              for (final e in accu.data[second]!) {
                distanceSet.add(e);
              }
            }
          }
        }

        ret = () sync* {
          for (final i in distanceSet) {
            var file = widget.api.directCell(i - 1);
            file.isarId = null;
            yield file;
          }
        }();
      } else {
        ret = () sync* {
          for (final i in accu!.data.values) {
            if (i.length > 1) {
              for (final v in i) {
                var file = widget.api.directCell(v - 1);
                file.isarId = null;
                yield file;
              }
            }
          }
        }();
      }

      if (accu.skipped != 0) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Results are incomplete"), // TODO: change
          duration: const Duration(seconds: 20),
          action: SnackBarAction(
              label: "Load more", // TODO: change
              onPressed: () {
                extra.loadNextThumbnails(() {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        duration: 4.seconds,
                        content: const Text("Loaded"))); // TODO: change
                    performSearch(searchTextController.text);
                  } catch (_) {}
                }, state.settings.expensiveHash);
              }),
        ));
      }

      return (ret, accu);
    }

    return ([], accu);
  }

  int hammingDistance(int first, int second) {
    return bitCount(first ^ second);
  }

  // stolen from internet
  int bitCount(int n) {
    n = n - ((n >> 1) & 0x5555555555555555);
    n = (n & 0x3333333333333333) + ((n >> 2) & 0x3333333333333333);
    n = (n + (n >> 4)) & 0x0f0f0f0f0f0f0f0f;
    n = n + (n >> 8);
    n = n + (n >> 16);
    n = n + (n >> 32);
    return n & 0x7f;
  }

  (Iterable<SystemGalleryDirectoryFile>, dynamic) _filterVideo(
      Iterable<SystemGalleryDirectoryFile> cells) {
    return (cells.where((element) => element.isVideo), null);
  }

  (Iterable<SystemGalleryDirectoryFile>, dynamic) _filterGif(
      Iterable<SystemGalleryDirectoryFile> cells) {
    return (cells.where((element) => element.isGif), null);
  }

  (Iterable<SystemGalleryDirectoryFile>, dynamic) _filterDuplicate(
      Iterable<SystemGalleryDirectoryFile> cells) {
    return (cells.where((element) => element.isDuplicate()), null);
  }

  (Iterable<SystemGalleryDirectoryFile>, dynamic) _filterOriginal(
      Iterable<SystemGalleryDirectoryFile> cells) {
    return (
      cells
          .where((element) => PostTags().containsTag(element.name, "original")),
      null
    );
  }

  late final GridSkeletonStateFilter<SystemGalleryDirectoryFile> state =
      GridSkeletonStateFilter(
          transform: (cell, sorting) {
            if (sorting == SortingMode.size ||
                currentFilteringMode() == FilteringMode.same) {
              cell.injectedStickers.add(cell.sizeSticker());
            }

            return cell;
          },
          hook: (selected) {
            if (selected == FilteringMode.tag) {
              markSearchVirtual();
            }

            if (selected == FilteringMode.size) {
              return SortingMode.size;
            }

            return SortingMode.none;
          },
          filter: extra.filter,
          index: kGalleryDrawerIndex,
          filteringModes: {
            FilteringMode.noFilter,
            if (!extra.isFavorites()) FilteringMode.favorite,
            FilteringMode.original,
            FilteringMode.duplicate,
            FilteringMode.same,
            FilteringMode.tag,
            FilteringMode.gif,
            FilteringMode.size,
            FilteringMode.video
          },
          onWillPop: () => Future.value(true));
  final stream = StreamController<int>(sync: true);

  @override
  void initState() {
    super.initState();

    settingsWatcher = settingsIsar().settings.watchObject(0).listen((event) {
      if (state.settings.expensiveHash != event!.expensiveHash) {
        performSearch(searchTextController.text);
      }
      state.settings = event;

      setState(() {});
    });
    searchHook(state);
  }

  @override
  void dispose() {
    widget.api.close();
    stream.close();
    settingsWatcher.cancel();
    disposeSearch();
    state.dispose();
    super.dispose();
  }

  void _refresh() {
    stream.add(0);
    state.gridKey.currentState?.mutationInterface?.setIsRefreshing(true);
    widget.api.refresh();
  }

  void _moveOrCopy(BuildContext context,
      List<SystemGalleryDirectoryFile> selected, bool move) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return AndroidDirectories(
          callback: CallbackDescription(
              move
                  ? AppLocalizations.of(context)!.chooseMoveDestination
                  : AppLocalizations.of(context)!.chooseCopyDestination,
              (chosen, newDir) {
            if (chosen == null && newDir == null) {
              throw "both are empty";
            }

            if (chosen != null && chosen.bucketId == widget.bucketId) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(move
                      ? AppLocalizations.of(context)!.cantMoveSameDest
                      : AppLocalizations.of(context)!.cantCopySameDest)));
              return;
            }

            PlatformFunctions.copyMoveFiles(
                chosen?.relativeLoc, chosen?.volumeName, selected,
                move: move, newDir: newDir);
          }),
        );
      },
    ));
  }

  void _favoriteOrUnfavorite(
      BuildContext context, List<SystemGalleryDirectoryFile> selected) {
    for (final fav in selected) {
      if (fav.isFavorite()) {
        blacklistedDirIsar().writeTxnSync(
            () => blacklistedDirIsar().favoriteMedias.deleteSync(fav.id));
      } else {
        blacklistedDirIsar().writeTxnSync(() =>
            blacklistedDirIsar().favoriteMedias.putSync(FavoriteMedia(fav.id)));
      }
    }

    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    var insets = MediaQuery.viewPaddingOf(context);

    return makeGridSkeleton<SystemGalleryDirectoryFile>(
      context,
      state,
      CallbackGrid(
          key: state.gridKey,
          getCell: (i) => widget.api.directCell(i),
          initalScrollPosition: 0,
          scaffoldKey: state.scaffoldKey,
          systemNavigationInsets: insets,
          hasReachedEnd: () => true,
          immutable: false,
          tightMode: true,
          addIconsImage: (cell) {
            return widget.callback != null
                ? [
                    IconButton(
                        onPressed: () {
                          widget.callback!(cell);
                        },
                        icon: const Icon(Icons.check))
                  ]
                : extra.isTrash()
                    ? [
                        IconButton(
                            onPressed: () {
                              PlatformFunctions.removeFromTrash(
                                  [cell.originalUri]);
                            },
                            icon: const Icon(Icons.restore_from_trash))
                      ]
                    : [
                        IconButton(
                            onPressed: () {
                              _favoriteOrUnfavorite(context, [cell]);
                            },
                            icon: const Icon(Icons.star_border)),
                        IconButton(
                            onPressed: () {
                              deleteDialog(context, [cell]);
                            },
                            icon: const Icon(Icons.delete)),
                        IconButton(
                            onPressed: () {
                              _moveOrCopy(context, [cell], false);
                            },
                            icon: const Icon(Icons.copy)),
                        IconButton(
                            onPressed: () {
                              _moveOrCopy(context, [cell], true);
                            },
                            icon: const Icon(Icons.forward))
                      ];
          },
          aspectRatio:
              state.settings.gallerySettings.filesAspectRatio?.value ?? 1,
          hideAlias: state.settings.gallerySettings.hideFileName,
          loadThumbsDirectly: extra.loadThumbnails,
          searchWidget: SearchAndFocus(
              searchWidget(context, hint: widget.dirName), searchFocus),
          mainFocus: state.mainFocus,
          hideShowFab: ({required bool fab, required bool foreground}) =>
              state.updateFab(setState, fab: fab, foreground: foreground),
          refresh: extra.supportsDirectRefresh
              ? () async {
                  final i = await widget.api.refresh();

                  performSearch(searchTextController.text);

                  return i;
                }
              : () {
                  _refresh();
                  return null;
                },
          menuButtonItems: [
            IconButton(
                onPressed: () {
                  var settings = settingsIsar().settings.getSync(0)!;
                  settingsIsar().writeTxnSync(() => settingsIsar()
                      .settings
                      .putSync(settings.copy(
                          gallerySettings: settings.gallerySettings.copy(
                              hideFileName:
                                  !(settings.gallerySettings.hideFileName ??
                                      false)))));
                },
                icon: const Icon(Icons.subtitles))
          ],
          onBack: () {
            if (currentFilteringMode() != FilteringMode.noFilter) {
              resetSearch();
              return;
            }
            Navigator.pop(context);
          },
          progressTicker: stream.stream,
          description: GridDescription(
              kGalleryDrawerIndex,
              widget.callback != null
                  ? []
                  : extra.isTrash()
                      ? [
                          GridBottomSheetAction(Icons.restore_from_trash,
                              (selected) {
                            PlatformFunctions.removeFromTrash(
                                selected.map((e) => e.originalUri).toList());
                          }, false)
                        ]
                      : [
                          GridBottomSheetAction(Icons.tag_rounded,
                              (selected) async {
                            for (final elem in selected) {
                              if (PostTags().getTagsPost(elem.name).isEmpty) {
                                await PostTags()
                                    .getOnlineAndSaveTags(elem.name);
                              }
                            }
                            GalleryImpl.instance().notify(null);
                          }, false),
                          GridBottomSheetAction(Icons.star_border_outlined,
                              (selected) {
                            _favoriteOrUnfavorite(context, selected);
                          }, false),
                          GridBottomSheetAction(Icons.delete, (selected) {
                            deleteDialog(context, selected);
                          }, false),
                          GridBottomSheetAction(Icons.copy, (selected) {
                            _moveOrCopy(context, selected, false);
                          }, false),
                          GridBottomSheetAction(Icons.forward, (selected) {
                            _moveOrCopy(context, selected, true);
                          }, false)
                        ],
              state.settings.gallerySettings.filesColumns ?? GridColumn.two,
              listView: state.settings.listViewBooru,
              bottomWidget: widget.callback != null
                  ? gridBottomWidgetText(
                      context, AppLocalizations.of(context)!.chooseFileNotice)
                  : null,
              keybindsDescription: widget.dirName)),
      noDrawer: widget.callback != null,
      overrideOnPop: () {
        if (currentFilteringMode() != FilteringMode.noFilter) {
          resetSearch();
          return Future.value(false);
        }

        return Future.value(true);
      },
    );
  }
}

void deleteDialog(
    BuildContext context, List<SystemGalleryDirectoryFile> selected) {
  Navigator.push(
      context,
      DialogRoute(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
                "${AppLocalizations.of(context)!.tagDeleteDialogTitle} ${selected.length} ${selected.length == 1 ? AppLocalizations.of(context)!.itemSingular : AppLocalizations.of(context)!.itemPlural}?"),
            content:
                const Text("You can restore it from the trash"), // TODO: change
            actions: [
              TextButton(
                  onPressed: () {
                    PlatformFunctions.addToTrash(
                        selected.map((e) => e.originalUri).toList());
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.yes)),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.no))
            ],
          );
        },
      ));
}
