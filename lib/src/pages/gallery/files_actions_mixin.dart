// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "files.dart";

mixin FilesActionsMixin on State<GalleryFiles> {
  Future<void> _deleteDialog(
    BuildContext context,
    List<GalleryFile> selected,
  ) {
    return Navigator.of(context, rootNavigator: true).push(
      DialogRoute(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              selected.length == 1
                  ? "${AppLocalizations.of(context)!.tagDeleteDialogTitle} ${selected.first.name}"
                  : "${AppLocalizations.of(context)!.tagDeleteDialogTitle}"
                      " ${selected.length}"
                      " ${AppLocalizations.of(context)!.itemPlural}",
            ),
            content: Text(AppLocalizations.of(context)!.youCanRestoreFromTrash),
            actions: [
              TextButton(
                onPressed: () {
                  GalleryManagementApi.current().addToTrash(
                    selected.map((e) => e.originalUri).toList(),
                  );

                  StatisticsGalleryService.db()
                      .current
                      .add(deleted: selected.length)
                      .save();
                  Navigator.pop(context);
                },
                child: Text(AppLocalizations.of(context)!.yes),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(AppLocalizations.of(context)!.no),
              ),
            ],
          );
        },
      ),
    );
  }

  GridAction<GalleryFile> restoreFromTrash() {
    return GridAction(
      Icons.restore_from_trash,
      (selected) {
        GalleryManagementApi.current().removeFromTrash(
          selected.map((e) => e.originalUri).toList(),
        );
      },
      false,
    );
  }

  GridAction<GalleryFile> bulkRename() {
    return GridAction(
      Icons.edit,
      (selected) {
        _changeName(context, selected);
      },
      false,
    );
  }

  GridAction<GalleryFile> saveTagsAction(
    GalleryPlug plug,
    PostTags postTags,
    LocalTagsService localTags,
  ) {
    return GridAction(
      Icons.tag_rounded,
      (selected) {
        _saveTags(context, selected, plug, postTags, localTags);
      },
      true,
    );
  }

  GridAction<GalleryFile> addTag(
    BuildContext context,
    void Function() refresh,
    LocalTagsService localTags,
  ) {
    return GridAction(
      Icons.new_label_rounded,
      (selected) {
        openAddTagDialog(context, (v, delete) {
          if (delete) {
            localTags.removeSingle(selected.map((e) => e.name).toList(), v);
          } else {
            localTags.addMultiple(selected.map((e) => e.name).toList(), v);
          }

          refresh();
        });
      },
      false,
    );
  }

  GridAction<GalleryFile> addToFavoritesAction(
    GalleryFile? f,
    FavoriteFileService favoriteFile,
  ) {
    final isFavorites = f != null && (favoriteFile.cachedValues[f.id] ?? false);

    return GridAction(
      isFavorites ? Icons.star_rounded : Icons.star_border_rounded,
      (selected) {
        _favoriteOrUnfavorite(context, selected, favoriteFile);
      },
      false,
      color: isFavorites ? Colors.yellow.shade900 : null,
      animate: f != null,
      play: !isFavorites,
    );
  }

  GridAction<GalleryFile> setFavoritesThumbnailAction(
    MiscSettingsService miscSettings,
  ) {
    return GridAction(
      Icons.image_outlined,
      (selected) {
        miscSettings.current.copy(favoritesThumbId: selected.first.id).save();
        setState(() {});
      },
      true,
      showOnlyWhenSingle: true,
    );
  }

  GridAction<GalleryFile> deleteAction() {
    return GridAction(
      Icons.delete,
      (selected) {
        _deleteDialog(context, selected);
      },
      false,
    );
  }

  GridAction<GalleryFile> copyAction(
    TagManager tagManager,
    FavoriteFileService favoriteFile,
    LocalTagsService localTags,
  ) {
    return GridAction(
      Icons.copy,
      (selected) {
        moveOrCopyFnc(
          context,
          selected,
          false,
          tagManager,
          favoriteFile,
          localTags,
        );
      },
      false,
    );
  }

  GridAction<GalleryFile> moveAction(
    TagManager tagManager,
    FavoriteFileService favoriteFile,
    LocalTagsService localTags,
  ) {
    return GridAction(
      Icons.forward_rounded,
      (selected) {
        moveOrCopyFnc(
          context,
          selected,
          true,
          tagManager,
          favoriteFile,
          localTags,
        );
      },
      false,
    );
  }

  GridAction<GalleryFile> chooseAction() {
    return GridAction(
      Icons.check,
      (selected) {
        widget.callback!(selected.first);
        if (widget.callback!.returnBack) {
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
        }
      },
      false,
    );
  }

  void moveOrCopyFnc(
    BuildContext context,
    List<GalleryFile> selected,
    bool move,
    TagManager tagManager,
    FavoriteFileService favoriteFile,
    LocalTagsService localTags,
  ) {
    PauseVideoNotifier.maybePauseOf(context, true);

    final List<String> searchPrefix = [];
    for (final tag in localTags.cachedValues[selected.first.bucketId] ??
        const <String>[]) {
      if (tagManager.pinned.exists(tag)) {
        searchPrefix.add(tag);
      }
    }

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return GalleryDirectories(
            showBackButton: true,
            procPop: (_) {},
            wrapGridPage: true,
            db: DatabaseConnectionNotifier.of(context),
            callback: CallbackDescription(
              icon: move ? Icons.forward_rounded : Icons.copy_rounded,
              move
                  ? AppLocalizations.of(context)!.chooseMoveDestination
                  : AppLocalizations.of(context)!.chooseCopyDestination,
              (chosen, newDir) {
                if (chosen == null && newDir == null) {
                  throw "both are empty";
                }

                if (chosen != null && chosen.bucketId == widget.bucketId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        move
                            ? AppLocalizations.of(context)!.cantMoveSameDest
                            : AppLocalizations.of(context)!.cantCopySameDest,
                      ),
                    ),
                  );
                  return Future.value();
                }

                if (chosen?.bucketId == "favorites") {
                  _favoriteOrUnfavorite(context, selected, favoriteFile);
                } else if (chosen?.bucketId == "trash") {
                  if (!move) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.cantCopyToTrash,
                        ),
                      ),
                    );
                    return Future.value();
                  }

                  return _deleteDialog(context, selected);
                } else {
                  GalleryManagementApi.current().copyMoveFiles(
                    chosen?.relativeLoc,
                    chosen?.volumeName,
                    selected,
                    move: move,
                    newDir: newDir,
                  );

                  if (move) {
                    StatisticsGalleryService.db()
                        .current
                        .add(moved: selected.length)
                        .save();
                  } else {
                    StatisticsGalleryService.db()
                        .current
                        .add(copied: selected.length)
                        .save();
                  }
                }

                return Future.value();
              },
              preview: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: CopyMovePreview(
                  files: selected,
                  size: 52,
                ),
              ),
              joinable: false,
              suggestFor: searchPrefix,
            ),
          );
        },
      ),
    ).then((value) => PauseVideoNotifier.maybePauseOf(context, false));
  }

  void _favoriteOrUnfavorite(
    BuildContext context,
    List<GalleryFile> selected,
    FavoriteFileService favoriteFile,
  ) {
    throw "";

    final toDelete = <int>[];
    final toAdd = <int>[];

    // for (final fav in selected) {
    //   if (fav.isFavorite) {
    //     toDelete.add(fav.id);
    //   } else {
    //     toAdd.add(fav.id);
    //   }
    // }

    if (toAdd.isNotEmpty) {
      favoriteFile.addAll(toAdd);
    }

    if (toDelete.isNotEmpty) {
      favoriteFile.deleteAll(toDelete);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deletedFromFavorites),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.undoLabel,
            onPressed: () {
              favoriteFile.addAll(toDelete);
            },
          ),
        ),
      );
    }
  }

  Future<void> _saveTags(
    BuildContext context,
    List<GalleryFile> selected,
    GalleryPlug plug,
    PostTags postTags,
    LocalTagsService localTags,
  ) async {
    if (_isSavingTags) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.tagSavingInProgress),
        ),
      );
      return;
    }
    _isSavingTags = true;

    final notifi = await chooseNotificationPlug().newProgress(
      "${AppLocalizations.of(context)!.savingTagsSaving}"
          " ${selected.length == 1 ? '1 ${AppLocalizations.of(context)!.tagSingular}' : '${selected.length} ${AppLocalizations.of(context)!.tagPlural}'}",
      savingTagsNotifId,
      "Saving tags",
      AppLocalizations.of(context)!.savingTags,
    );
    notifi.setTotal(selected.length);

    for (final (i, elem) in selected.indexed) {
      notifi.update(i, "$i/${selected.length}");

      if (localTags.get(elem.name).isEmpty) {
        await postTags.getOnlineAndSaveTags(elem.name);
      }
    }
    notifi.done();
    plug.notify(null);
    _isSavingTags = false;
  }

  void _changeName(
    BuildContext context,
    List<GalleryFile> selected,
  ) {
    if (selected.isEmpty) {
      return;
    }
    Navigator.of(context, rootNavigator: true).push(
      DialogRoute<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.bulkRenameTitle),
            content: TextFormField(
              autofocus: true,
              initialValue: "*",
              autovalidateMode: AutovalidateMode.always,
              validator: (value) {
                if (value == null) {
                  return AppLocalizations.of(context)!.valueIsNull;
                }
                if (value.isEmpty) {
                  return AppLocalizations.of(context)!.newNameShouldntBeEmpty;
                }

                if (!value.contains("*")) {
                  return AppLocalizations.of(context)!
                      .newNameShouldIncludeOneStar;
                }

                return null;
              },
              onFieldSubmitted: (value) async {
                if (value.isEmpty) {
                  return;
                }
                final idx = value.indexOf("*");
                if (idx == -1) {
                  return;
                }

                final matchBefore = value.substring(0, idx);
                final api = GalleryManagementApi.current();

                for (final (i, e) in selected.indexed) {
                  await api.rename(
                    e.originalUri,
                    "$matchBefore${e.name}",
                    i == selected.length - 1,
                  );
                }

                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }
}
