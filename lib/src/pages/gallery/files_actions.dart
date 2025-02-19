// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "files.dart";

class DeleteDialogShow {
  bool show = true;
}

class DeleteDialogShowNotifier extends InheritedWidget {
  const DeleteDialogShowNotifier({
    super.key,
    required this.toShow,
    required super.child,
  });

  final DeleteDialogShow toShow;

  static DeleteDialogShow? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<DeleteDialogShowNotifier>();

    return widget?.toShow;
  }

  @override
  bool updateShouldNotify(DeleteDialogShowNotifier oldWidget) =>
      toShow != oldWidget.toShow;
}

Future<void> deleteFilesDialog(
  BuildContext context,
  List<File> selected,
  DeleteDialogShow toShow,
  GalleryTrash galleryTrash,
) {
  final l10n = context.l10n();

  void delete() {
    galleryTrash.addAll(
      selected.map((e) => e.originalUri).toList(),
    );

    StatisticsGalleryService.addDeleted(selected.length);
  }

  if (!toShow.show) {
    delete();
    return Future.value();
  }

  return Navigator.of(context, rootNavigator: true).push(
    DialogRoute(
      context: context,
      builder: (context) {
        final text = selected.length == 1
            ? "${l10n.tagDeleteDialogTitle} ${selected.first.name}"
            : "${l10n.tagDeleteDialogTitle}"
                " ${selected.length}"
                " ${l10n.elementPlural}";

        return AlertDialog(
          title: Text(text),
          content: Text(l10n.youCanRestoreFromTrash),
          actions: [
            TextButton(
              onPressed: () {
                delete();
                toShow.show = false;
                Navigator.pop(context);
              },
              child: Text(l10n.yesHide),
            ),
            TextButton(
              onPressed: () {
                delete();
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

GridAction<File> _restoreFromTrashAction(GalleryTrash galleryTrash) {
  return GridAction(
    Icons.restore_from_trash,
    (selected) {
      galleryTrash.removeAll(
        selected.map((e) => e.originalUri).toList(),
      );
    },
    false,
  );
}

GridAction<File> _saveTagsAction(
  BuildContext context, {
  required LocalTagsService localTags,
  required GalleryService galleryService,
}) {
  return GridAction(
    Icons.tag_rounded,
    (selected) {
      _saveTags(
        context,
        selected,
        context.l10n(),
        localTags: localTags,
        galleryService: galleryService,
      );
    },
    true,
  );
}

GridAction<File> _addTagAction(
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
        context.l10n(),
      );
    },
    false,
  );
}

GridAction<File> _setFavoritesThumbnailAction(
  MiscSettingsService miscSettings,
) {
  return GridAction(
    Icons.image_outlined,
    (selected) {
      miscSettings.current
          .copy(favoritesThumbId: selected.first.id)
          .maybeSave();
    },
    true,
    showOnlyWhenSingle: true,
  );
}

GridAction<File> _deleteAction(
  BuildContext context,
  DeleteDialogShow toShow,
  GalleryTrash galleryTrash,
) {
  return GridAction(
    Icons.delete,
    (selected) {
      deleteFilesDialog(
        context,
        selected,
        toShow,
        galleryTrash,
      );
    },
    false,
  );
}

GridAction<File> _copyAction(
  BuildContext context,
  String bucketId,
  Directories providedApi,
  DeleteDialogShow toShow, {
  required GalleryService galleryService,
  required TagManagerService tagManager,
  required LocalTagsService localTags,
}) {
  return GridAction(
    Icons.copy,
    (selected) {
      moveOrCopyFnc(
        context,
        bucketId,
        selected,
        false,
        providedApi,
        toShow,
        galleryService: galleryService,
        tagManager: tagManager,
        localTags: localTags,
      );
    },
    false,
  );
}

GridAction<File> _moveAction(
  BuildContext context,
  String bucketId,
  Directories providedApi,
  DeleteDialogShow toShow, {
  required GalleryService galleryService,
  required TagManagerService tagManager,
  required LocalTagsService localTags,
}) {
  return GridAction(
    Icons.forward_rounded,
    (selected) {
      moveOrCopyFnc(
        context,
        bucketId,
        selected,
        true,
        providedApi,
        toShow,
        galleryService: galleryService,
        tagManager: tagManager,
        localTags: localTags,
      );
    },
    false,
  );
}

void moveOrCopyFnc(
  BuildContext topContext,
  String originalBucketId,
  List<File> selected,
  bool move,
  Directories providedApi,
  DeleteDialogShow toShow, {
  required GalleryService galleryService,
  required TagManagerService tagManager,
  required LocalTagsService localTags,
}) {
  PauseVideoNotifier.maybePauseOf(topContext, true);

  final List<String> searchPrefix = [];
  for (final tag in localTags.get(selected.first.name)) {
    if (tagManager.pinned.exists(tag)) {
      searchPrefix.add(tag);
    }
  }

  final l10n = AppLocalizations.of(topContext)!;

  DirectoriesPage.open(
    topContext,
    showBackButton: true,
    wrapGridPage: true,
    providedApi: providedApi,
    callback: ReturnDirectoryCallback(
      choose: (value, newDir) {
        if (!newDir && value.bucketId == originalBucketId) {
          ScaffoldMessenger.of(topContext).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(
                move ? l10n.cantMoveSameDest : l10n.cantCopySameDest,
              ),
            ),
          );
          return Future.value();
        }

        if (value.bucketId == "trash") {
          if (!move) {
            ScaffoldMessenger.of(topContext).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(
                  l10n.cantCopyToTrash,
                ),
              ),
            );
            return Future.value();
          }

          return deleteFilesDialog(
            topContext,
            selected,
            toShow,
            galleryService.trash,
          );
        } else {
          galleryService.files
              .copyMove(
            value.path,
            value.volumeName,
            selected,
            move: move,
            newDir: newDir,
          )
              .catchError((dynamic e) {
            if (topContext.mounted) {
              ScaffoldMessenger.of(topContext).showSnackBar(
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
            StatisticsGalleryService.addMoved(selected.length);
          } else {
            StatisticsGalleryService.addCopied(selected.length);
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
    l10n: topContext.l10n(),
  ).then((value) {
    if (topContext.mounted) {
      PauseVideoNotifier.maybePauseOf(topContext, false);
    }
  });
}

extension SaveTagsGlobalNotifier on GlobalProgressTab {
  ValueNotifier<Future<void>?> saveTags() {
    return get("saveTags", () => ValueNotifier(null));
  }
}

Future<void> _saveTags(
  BuildContext context,
  List<File> selected,
  AppLocalizations l10n, {
  required LocalTagsService localTags,
  required GalleryService galleryService,
}) async {
  final notifier = GlobalProgressTab.maybeOf(context)?.saveTags();
  if (notifier == null) {
    return;
  } else if (notifier.value != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.tagSavingInProgress),
      ),
    );

    return;
  }

  final notifi = await NotificationApi().show(
    title: l10n.savingTags,
    id: NotificationApi.savingTagsId,
    group: NotificationGroup.misc,
    channel: NotificationChannel.misc,
    body: "${l10n.savingTagsSaving}"
        " ${selected.length == 1 ? '1 ${l10n.tagSingular}' : '${selected.length} ${l10n.tagPlural}'}",
  );

  return notifier.value = Future(() async {
    notifi.setTotal(selected.length);

    for (final (i, elem) in selected.indexed) {
      notifi.update(i, "$i/${selected.length}");

      if (localTags.get(elem.name).isEmpty) {
        await localTags.getOnlineAndSaveTags(elem.name);
      }
    }
  }).onError((e, trace) {
    Logger.root.warning("Saving tags failed", e, trace);
    return null;
  }).whenComplete(() {
    notifi.done();
    galleryService.notify(null);

    return notifier.value = null;
  });
}
