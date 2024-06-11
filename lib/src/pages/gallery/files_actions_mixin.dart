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
    final l10n = AppLocalizations.of(context)!;

    return Navigator.of(context, rootNavigator: true).push(
      DialogRoute(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              selected.length == 1
                  ? "${l10n.tagDeleteDialogTitle} ${selected.first.name}"
                  : "${l10n.tagDeleteDialogTitle}"
                      " ${selected.length}"
                      " ${l10n.elementPlural}",
            ),
            content: Text(l10n.youCanRestoreFromTrash),
            actions: [
              TextButton(
                onPressed: () {
                  GalleryManagementApi.current().trash.addAll(
                        selected.map((e) => e.originalUri).toList(),
                      );

                  StatisticsGalleryService.db()
                      .current
                      .add(deleted: selected.length)
                      .save();
                  Navigator.pop(context);
                },
                child: Text(l10n.yes),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(l10n.no),
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
        GalleryManagementApi.current().trash.removeAll(
              selected.map((e) => e.originalUri).toList(),
            );
      },
      false,
    );
  }

  GridAction<GalleryFile> saveTagsAction(
    GalleryPlug plug,
    PostTags postTags,
    LocalTagsService localTags,
    LocalTagDictionaryService localTagDictionary,
  ) {
    return GridAction(
      Icons.tag_rounded,
      (selected) {
        _saveTags(
          context,
          selected,
          plug,
          postTags,
          localTags,
          localTagDictionary,
          AppLocalizations.of(context)!,
        );
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
        openAddTagDialog(
          context,
          (v, delete) {
            if (delete) {
              localTags.removeSingle(selected.map((e) => e.name).toList(), v);
            } else {
              localTags.addMultiple(selected.map((e) => e.name).toList(), v);
            }

            refresh();
          },
          AppLocalizations.of(context)!,
        );
      },
      false,
    );
  }

  GridAction<GalleryFile> addToFavoritesAction(
    GalleryFile? f,
    FavoriteFileService favoriteFile,
  ) {
    final isFavorites =
        f != null && (favoriteFile.cachedValues.containsKey(f.id));

    return GridAction(
      isFavorites ? Icons.star_rounded : Icons.star_border_rounded,
      (selected) {
        favoriteOrUnfavorite(context, selected, favoriteFile);
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
    GalleryAPIDirectories providedApi,
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
          providedApi,
        );
      },
      false,
    );
  }

  GridAction<GalleryFile> moveAction(
    TagManager tagManager,
    FavoriteFileService favoriteFile,
    LocalTagsService localTags,
    GalleryAPIDirectories providedApi,
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
          providedApi,
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
    GalleryAPIDirectories providedApi,
  ) {
    PauseVideoNotifier.maybePauseOf(context, true);

    final List<String> searchPrefix = [];
    for (final tag in selected.first.tagsFlat.split(" ")) {
      if (tagManager.pinned.exists(tag)) {
        searchPrefix.add(tag);
      }
    }

    final l10n = AppLocalizations.of(context)!;

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return GalleryDirectories(
            showBackButton: true,
            wrapGridPage: true,
            providedApi: providedApi,
            db: DatabaseConnectionNotifier.of(context),
            callback: CallbackDescription(
              (chosen, volumeName, bucketId, newDir) {
                if (!newDir && bucketId == widget.bucketId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        move ? l10n.cantMoveSameDest : l10n.cantCopySameDest,
                      ),
                    ),
                  );
                  return Future.value();
                }

                if (chosen == "favorites") {
                  favoriteOrUnfavorite(context, selected, favoriteFile);
                } else if (chosen == "trash") {
                  if (!move) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          l10n.cantCopyToTrash,
                        ),
                      ),
                    );
                    return Future.value();
                  }

                  return _deleteDialog(context, selected);
                } else {
                  GalleryManagementApi.current()
                      .files
                      .copyMove(
                        chosen,
                        volumeName,
                        selected,
                        move: move,
                        newDir: newDir,
                      )
                      .catchError((dynamic e) {
                    if (this.context.mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            e is PlatformException ? e.code : e.toString(),
                          ),
                        ),
                      );
                    }
                  });

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
                preferredSize: Size.fromHeight(CopyMovePreview.size.toDouble()),
                child: CopyMovePreview(
                  files: selected,
                  icon: move ? Icons.forward_rounded : Icons.copy_rounded,
                  title: move ? l10n.moveTo : l10n.copyTo,
                ),
              ),
              joinable: false,
              suggestFor: searchPrefix,
            ),
            l10n: AppLocalizations.of(context)!,
          );
        },
      ),
    ).then((value) => PauseVideoNotifier.maybePauseOf(context, false));
  }

  static void favoriteOrUnfavorite(
    BuildContext context,
    List<GalleryFile> selected,
    FavoriteFileService favoriteFile,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final toDelete = <int>[];
    final toAdd = <int>[];

    for (final fav in selected) {
      if (favoriteFile.cachedValues.containsKey(fav.id)) {
        toDelete.add(fav.id);
      } else {
        toAdd.add(fav.id);
      }
    }

    if (toAdd.isNotEmpty) {
      favoriteFile.addAll(toAdd);
    }

    if (toDelete.isNotEmpty) {
      favoriteFile.deleteAll(toDelete);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deletedFromFavorites),
          action: SnackBarAction(
            label: l10n.undoLabel,
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
    LocalTagDictionaryService localTagDictionary,
    AppLocalizations l10n,
  ) async {
    if (_isSavingTags) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tagSavingInProgress),
        ),
      );
      return;
    }
    _isSavingTags = true;

    final notifi = await chooseNotificationPlug().newProgress(
      "${l10n.savingTagsSaving}"
          " ${selected.length == 1 ? '1 ${l10n.tagSingular}' : '${selected.length} ${l10n.tagPlural}'}",
      savingTagsNotifId,
      "Saving tags",
      l10n.savingTags,
    );
    notifi.setTotal(selected.length);

    for (final (i, elem) in selected.indexed) {
      notifi.update(i, "$i/${selected.length}");

      if (localTags.get(elem.name).isEmpty) {
        await postTags.getOnlineAndSaveTags(elem.name, localTagDictionary);
      }
    }
    notifi.done();
    plug.notify(null);
    _isSavingTags = false;
  }
}
