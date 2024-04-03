// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'files.dart';

mixin _FilesActionsMixin on State<GalleryFiles> {
  Future<void> _deleteDialog(
      BuildContext context, List<SystemGalleryDirectoryFile> selected) {
    return Navigator.of(context, rootNavigator: true).push(DialogRoute(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(selected.length == 1
              ? "${AppLocalizations.of(context)!.tagDeleteDialogTitle} ${selected.first.name}"
              : "${AppLocalizations.of(context)!.tagDeleteDialogTitle}"
                  " ${selected.length}"
                  " ${AppLocalizations.of(context)!.itemPlural}"),
          content: Text(AppLocalizations.of(context)!.youCanRestoreFromTrash),
          actions: [
            TextButton(
                onPressed: () {
                  PlatformFunctions.addToTrash(
                      selected.map((e) => e.originalUri).toList());
                  StatisticsGallery.addDeleted(selected.length);
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

  GridAction _restoreFromTrash() {
    return GridAction(
      Icons.restore_from_trash,
      (selected) {
        PlatformFunctions.removeFromTrash(selected
            .cast<SystemGalleryDirectoryFile>()
            .map((e) => e.originalUri)
            .toList());
      },
      false,
    );
  }

  GridAction _bulkRename() {
    return GridAction(
      Icons.edit,
      (selected) {
        _changeName(context, selected.cast());
      },
      false,
    );
  }

  GridAction _saveTagsAction(GalleryPlug plug) {
    return GridAction(
      Icons.tag_rounded,
      (selected) {
        _saveTags(context, selected.cast(), plug);
      },
      true,
    );
  }

  GridAction _addTag(BuildContext context, void Function() refresh) {
    return GridAction(
      Icons.new_label_rounded,
      (selected) {
        openAddTagDialog(context, (v, delete) {
          if (delete) {
            PostTags.g.removeTag(
                selected
                    .cast<SystemGalleryDirectoryFile>()
                    .map((e) => e.name)
                    .toList(),
                v);
          } else {
            PostTags.g.addTag(
                selected
                    .cast<SystemGalleryDirectoryFile>()
                    .map((e) => e.name)
                    .toList(),
                v);
          }

          refresh();
        });
      },
      false,
    );
  }

  GridAction _addToFavoritesAction(
      SystemGalleryDirectoryFile? f, GalleryPlug plug) {
    final isFavorites = f != null && f.isFavorite;

    return GridAction(
        isFavorites ? Icons.star_rounded : Icons.star_border_rounded,
        (selected) {
      _favoriteOrUnfavorite(context, selected.cast(), plug);
    }, false,
        color: isFavorites ? Colors.yellow.shade900 : null,
        animate: f != null,
        play: !isFavorites);
  }

  GridAction _setFavoritesThumbnailAction() {
    return GridAction(Icons.image_outlined, (selected) {
      MiscSettings.setFavoritesThumbId(
          (selected.first as SystemGalleryDirectoryFile).id);
      setState(() {});
    }, true, showOnlyWhenSingle: true);
  }

  GridAction _deleteAction() {
    return GridAction(
      Icons.delete,
      (selected) {
        _deleteDialog(context, selected.cast());
      },
      false,
    );
  }

  GridAction _copyAction(
      GridSkeletonStateFilter<SystemGalleryDirectoryFile> state,
      GalleryPlug plug) {
    return GridAction(
      Icons.copy,
      (selected) {
        _moveOrCopy(context, selected.cast(), false, state, plug);
      },
      false,
    );
  }

  GridAction _moveAction(
      GridSkeletonStateFilter<SystemGalleryDirectoryFile> state,
      GalleryPlug plug) {
    return GridAction(
      Icons.forward_rounded,
      (selected) {
        _moveOrCopy(context, selected.cast(), true, state, plug);
      },
      false,
    );
  }

  GridAction _chooseAction() {
    return GridAction(
      Icons.check,
      (selected) {
        widget.callback!(selected.first as SystemGalleryDirectoryFile);
        if (widget.callback!.returnBack) {
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
        }
      },
      false,
    );
  }

  void _moveOrCopy(
      BuildContext context,
      List<SystemGalleryDirectoryFile> selected,
      bool move,
      GridSkeletonStateFilter<SystemGalleryDirectoryFile> state,
      GalleryPlug plug) {
    state.imageViewKey.currentState?.wrapNotifiersKey.currentState
        ?.pauseVideo();

    final List<String> searchPrefix = [];
    for (final tag in selected.first.tagsFlat.split(" ")) {
      if (PinnedTag.isPinned(tag)) {
        searchPrefix.add(tag);
      }
    }

    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      builder: (context) {
        return GalleryDirectories(
          showBackButton: true,
          procPop: (_) {},
          wrapGridPage: true,
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
                return Future.value();
              }

              if (chosen?.bucketId == "favorites") {
                _favoriteOrUnfavorite(context, selected, plug);
              } else if (chosen?.bucketId == "trash") {
                if (!move) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                    AppLocalizations.of(context)!.cantCopyToTrash,
                  )));
                  return Future.value();
                }

                return _deleteDialog(context, selected);
              } else {
                PlatformFunctions.copyMoveFiles(
                    chosen?.relativeLoc, chosen?.volumeName, selected,
                    move: move, newDir: newDir);

                if (move) {
                  StatisticsGallery.addMoved(selected.length);
                } else {
                  StatisticsGallery.addCopied(selected.length);
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
    )).then((value) => state
        .imageViewKey.currentState?.wrapNotifiersKey.currentState
        ?.unpauseVideo());
  }

  void _favoriteOrUnfavorite(BuildContext context,
      List<SystemGalleryDirectoryFile> selected, GalleryPlug plug) {
    final toDelete = <int>[];
    final toAdd = <int>[];

    for (final fav in selected) {
      if (fav.isFavorite) {
        toDelete.add(fav.id);
      } else {
        toAdd.add(fav.id);
      }
    }

    if (toAdd.isNotEmpty) {
      FavoriteBooruPost.addAll(toAdd);
    }

    plug.notify(null);

    if (toDelete.isNotEmpty) {
      FavoriteBooruPost.deleteAll(toDelete);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.deletedFromFavorites),
        action: SnackBarAction(
            label: AppLocalizations.of(context)!.undoLabel,
            onPressed: () {
              FavoriteBooruPost.addAll(toDelete);

              plug.notify(null);
            }),
      ));
    }
  }

  void _saveTags(BuildContext context,
      List<SystemGalleryDirectoryFile> selected, GalleryPlug plug) async {
    if (_isSavingTags) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.tagSavingInProgress)));
      return;
    }
    _isSavingTags = true;

    final notifi = await chooseNotificationPlug().newProgress(
        "${AppLocalizations.of(context)!.savingTagsSaving}"
            " ${selected.length == 1 ? '1 ${AppLocalizations.of(context)!.tagSingular}' : '${selected.length} ${AppLocalizations.of(context)!.tagPlural}'}",
        savingTagsNotifId,
        "Saving tags",
        AppLocalizations.of(context)!.savingTags);
    notifi.setTotal(selected.length);

    for (final (i, elem) in selected.indexed) {
      notifi.update(i, "$i/${selected.length}");

      if (PostTags.g.getTagsPost(elem.name).isEmpty) {
        await PostTags.g.getOnlineAndSaveTags(elem.name);
      }
    }
    notifi.done();
    plug.notify(null);
    _isSavingTags = false;
  }

  void _changeName(
      BuildContext context, List<SystemGalleryDirectoryFile> selected) {
    if (selected.isEmpty) {
      return;
    }
    Navigator.of(context, rootNavigator: true).push(DialogRoute(
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

              for (final (i, e) in selected.indexed) {
                PlatformFunctions.rename(e.originalUri, "$matchBefore${e.name}",
                    notify: i == selected.length - 1);
              }

              Navigator.pop(context);
            },
          ),
        );
      },
    ));
  }
}
