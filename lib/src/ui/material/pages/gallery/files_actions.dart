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
) {
  final l10n = context.l10n();

  void delete() {
    const GalleryService().trash.addAll(
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

SelectionBarAction _restoreFromTrashAction(GalleryTrash galleryTrash) {
  return SelectionBarAction(
    Icons.restore_from_trash,
    (selected) {
      galleryTrash.removeAll(
        selected.map((e) => (e as File).originalUri).toList(),
      );
    },
    false,
  );
}

SelectionBarAction _saveTagsAction(AppLocalizations l10n) {
  return SelectionBarAction(
    Icons.tag_rounded,
    (selected) {
      const TasksService().add<LocalTagsService>(
        () => _saveTags(selected.cast(), l10n),
      );
    },
    true,
    taskTag: LocalTagsService,
  );
}

SelectionBarAction _addTagAction(
  BuildContext context,
  void Function() refresh,
) {
  return SelectionBarAction(
    Icons.new_label_rounded,
    (selected) {
      openAddTagDialog(
        context,
        (v, delete) {
          if (delete) {
            const LocalTagsService().removeSingle(
              selected.map((e) => (e as File).name).toList(),
              v,
            );
          } else {
            const LocalTagsService().addMultiple(
              selected.map((e) => (e as File).name).toList(),
              v,
            );
          }

          refresh();
        },
        context.l10n(),
      );
    },
    false,
  );
}

SelectionBarAction _deleteAction(
  BuildContext context,
  DeleteDialogShow toShow,
  GalleryTrash galleryTrash,
) {
  return SelectionBarAction(
    Icons.delete,
    (selected) {
      deleteFilesDialog(
        context,
        selected.cast(),
        toShow,
      );
    },
    false,
  );
}

SelectionBarAction _copyAction(
  BuildContext context,
  String bucketId,
  Directories providedApi,
  DeleteDialogShow toShow,
) {
  return SelectionBarAction(
    Icons.copy,
    (selected) {
      moveOrCopyFnc(
        context,
        bucketId,
        selected.cast(),
        false,
        providedApi,
        toShow,
      );
    },
    false,
  );
}

SelectionBarAction _moveAction(
  BuildContext context,
  String bucketId,
  Directories providedApi,
  DeleteDialogShow toShow,
) {
  return SelectionBarAction(
    Icons.forward_rounded,
    (selected) {
      moveOrCopyFnc(
        context,
        bucketId,
        selected.cast(),
        true,
        providedApi,
        toShow,
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
  DeleteDialogShow toShow,
) {
  if (!FilesApi.available || !GalleryService.available) {
    return;
  }

  PauseVideoNotifier.maybePauseOf(topContext, true);

  final List<String> searchPrefix = [];
  for (final tag in const LocalTagsService().get(selected.first.name)) {
    if (const TagManagerService().pinned.exists(tag)) {
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
          );
        } else {
          const FilesApi()
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
  ).then((value) {
    if (topContext.mounted) {
      PauseVideoNotifier.maybePauseOf(topContext, false);
    }
  });
}

Future<void> _saveTags(
  List<File> selected,
  AppLocalizations l10n,
) async {
  if (!LocalTagsService.available) {
    return;
  }

  final handle = await const NotificationApi().show(
    title: l10n.savingTags,
    id: const NotificationChannels().savingTags,
    group: NotificationGroup.misc,
    channel: NotificationChannel.misc,
    body: "${l10n.savingTagsSaving}"
        " ${selected.length == 1 ? '1 ${l10n.tagSingular}' : '${selected.length} ${l10n.tagPlural}'}",
  );

  try {
    handle?.setTotal(selected.length);

    for (final (i, elem) in selected.indexed) {
      handle?.update(i, "$i/${selected.length}");

      if (const LocalTagsService().get(elem.name).isEmpty) {
        await const LocalTagsService().getOnlineAndSaveTags(elem.name);
      }
    }
  } catch (e, trace) {
    Logger.root.warning("Saving tags failed", e, trace);

    // TODO: add scaffold
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(l10n.tagSavingInProgress),
    //     ),
    //   );
  } finally {
    handle?.done();
    GalleryApi.safe()?.notify(null);
  }
}
