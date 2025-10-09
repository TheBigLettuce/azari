// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "main.dart";

/// Entrypoint for the second Android's Activity.
/// Picks a file and returns to the app requested.
@pragma("vm:entry-point")
Future<void> mainPickfile() async {
  await initMain(AppInstanceType.pickFile);

  final accentColor = const AppApi().accentColor;

  final actions = SelectionActions();

  runApp(
    injectWidgetEvents(
      PinnedTagsHolder(
        pinnedTags: TagManagerService.safe()?.pinned,
        child: actions.inject(
          MaterialApp(
            title: "Azari",
            themeAnimationCurve: Easing.standard,
            themeAnimationDuration: const Duration(milliseconds: 300),
            darkTheme: buildTheme(Brightness.dark, accentColor),
            theme: buildTheme(Brightness.light, accentColor),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: _ScaffoldSelectionBarInherited(
              child: Builder(
                builder: (context) => DirectoriesPage(
                  selectionController: SelectionActions.controllerOf(context),
                  callback: ReturnFileCallback(
                    choose: (chosen, [_]) {
                      const AppApi().close(chosen.originalUri);

                      return Future.value();
                    },
                    preview: PreferredSize(
                      preferredSize: Size.fromHeight(
                        CopyMovePreview.size.toDouble(),
                      ),
                      child: IgnorePointer(
                        child: Builder(
                          builder: (context) {
                            final l10n = context.l10n();

                            return CopyMovePreview(
                              files: null,
                              title: l10n.pickFileNotice,
                              icon: Icons.file_open_rounded,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ScaffoldSelectionBarInherited extends StatelessWidget {
  const _ScaffoldSelectionBarInherited({
    // super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion(
      value: makeSystemUiOverlayStyle(theme),
      child: Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: SelectionBar(
          actions: SelectionActions.of(context),
        ),
        body: GestureDeadZones(
          left: true,
          right: true,
          child: Builder(
            builder: (buildContext) {
              final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

              final data = MediaQuery.of(buildContext);

              return MediaQuery(
                data: data.copyWith(
                  viewPadding:
                      data.viewPadding + EdgeInsets.only(bottom: bottomPadding),
                ),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}
