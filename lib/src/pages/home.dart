// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/pages/anime/anime.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/pages/gallery/callback_description_nested.dart";
import "package:gallery/src/pages/gallery/directories.dart";
import "package:gallery/src/pages/glue_bottom_app_bar.dart";
import "package:gallery/src/pages/manga/manga_page.dart";
import "package:gallery/src/pages/more/more_page.dart";
import "package:gallery/src/pages/more/settings/settings_widget.dart";
import "package:gallery/src/plugs/network_status.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue_state.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/notifiers/selection_count.dart";
import "package:gallery/src/widgets/skeletons/home.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

part "home/animated_icons_mixin.dart";
part "home/before_you_continue_dialog_mixin.dart";
part "home/change_page_mixin.dart";
part "home/icons/anime_icon.dart";
part "home/icons/booru_icon.dart";
part "home/icons/gallery_icon.dart";
part "home/icons/manga_icon.dart";
part "home/navigator_shell.dart";

enum BooruSubPage {
  booru(
    icon: Icons.photo_outlined,
    selectedIcon: Icons.photo_rounded,
  ),
  favorites(
    icon: Icons.favorite_outline_rounded,
    selectedIcon: Icons.favorite_rounded,
  ),
  bookmarks(
    icon: Icons.bookmarks_outlined,
    selectedIcon: Icons.bookmarks_rounded,
  ),
  hiddenPosts(
    icon: Icons.hide_image_outlined,
    selectedIcon: Icons.hide_image_rounded,
  );

  const BooruSubPage({
    required this.icon,
    required this.selectedIcon,
  });

  factory BooruSubPage.fromIdx(int idx) => switch (idx) {
        0 => booru,
        1 => favorites,
        2 => bookmarks,
        3 => hiddenPosts,
        int() => booru,
      };

  final IconData icon;
  final IconData selectedIcon;

  String translatedString(AppLocalizations l10n) => switch (this) {
        BooruSubPage.booru => l10n.booruLabel,
        BooruSubPage.favorites => l10n.favoritesLabel,
        BooruSubPage.bookmarks => l10n.bookmarksPageName,
        BooruSubPage.hiddenPosts => l10n.hiddenPostsPageName,
      };

  static Widget wrap(ValueNotifier<BooruSubPage> notifier, Widget child) =>
      _SelectedBooruPage(notifier: notifier, child: child);

  static BooruSubPage of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_SelectedBooruPage>();

    return widget!.notifier!.value;
  }

  static void selectOf(BuildContext context, BooruSubPage page) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_SelectedBooruPage>();

    widget!.notifier!.value = page;
  }
}

enum GallerySubPage {
  gallery(
    icon: Icons.collections_outlined,
    selectedIcon: Icons.collections_rounded,
  ),
  blacklisted(
    icon: Icons.folder_off_outlined,
    selectedIcon: Icons.folder_off_rounded,
  );

  const GallerySubPage({
    required this.icon,
    required this.selectedIcon,
  });

  factory GallerySubPage.fromIdx(int idx) => switch (idx) {
        0 => gallery,
        1 => blacklisted,
        int() => gallery,
      };

  final IconData icon;
  final IconData selectedIcon;

  String translatedString(AppLocalizations l10n) => switch (this) {
        GallerySubPage.gallery => l10n.galleryLabel,
        GallerySubPage.blacklisted => l10n.blacklistedFoldersPage,
      };

  static Widget wrap(ValueNotifier<GallerySubPage> notifier, Widget child) =>
      _SelectedGalleryPage(notifier: notifier, child: child);

  static GallerySubPage of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_SelectedGalleryPage>();

    return widget!.notifier!.value;
  }

  static void selectOf(BuildContext context, GallerySubPage page) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_SelectedGalleryPage>();

    widget!.notifier!.value = page;
  }
}

enum MoreSubPage {
  more(
    icon: Icons.more_horiz_outlined,
    selectedIcon: Icons.more_horiz_rounded,
  ),
  dashboard(
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  );

  const MoreSubPage({
    required this.icon,
    required this.selectedIcon,
  });

  factory MoreSubPage.fromIdx(int idx) => switch (idx) {
        0 => more,
        1 => dashboard,
        int() => more,
      };

  final IconData icon;
  final IconData selectedIcon;

  String translatedString(AppLocalizations l10n) => switch (this) {
        MoreSubPage.more => l10n.more,
        MoreSubPage.dashboard => l10n.dashboardPage,
      };

  static Widget wrap(ValueNotifier<MoreSubPage> notifier, Widget child) =>
      _SelectedMorePage(notifier: notifier, child: child);

  static MoreSubPage of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_SelectedMorePage>();

    return widget!.notifier!.value;
  }

  static void selectOf(BuildContext context, MoreSubPage page) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_SelectedMorePage>();

    widget!.notifier!.value = page;
  }
}

class Home extends StatefulWidget {
  const Home({super.key, this.callback});
  final CallbackDescriptionNested? callback;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>
    with
        TickerProviderStateMixin,
        _ChangePageMixin,
        _AnimatedIconsMixin,
        _BeforeYouContinueDialogMixin {
  late final StreamSubscription<void> _settingsSubscription;

  final _booruPageNotifier = ValueNotifier<BooruSubPage>(BooruSubPage.booru);
  final _galleryPageNotifier =
      ValueNotifier<GallerySubPage>(GallerySubPage.gallery);
  final _morePageNotifier = ValueNotifier<MoreSubPage>(MoreSubPage.more);

  final state = SkeletonState();
  final settings = SettingsService.db().current;

  bool isRefreshing = false;

  bool hideNavBar = false;
  late bool showAnimeMangaPages = settings.showAnimeMangaPages;

  @override
  void initState() {
    super.initState();

    _settingsSubscription = settings.s.watch((s) {
      if (showAnimeMangaPages != s!.showAnimeMangaPages) {
        setState(() {
          showAnimeMangaPages = s.showAnimeMangaPages;
          if (showAnimeMangaPages &&
              currentRoute == _ChangePageMixin.kMangaPageRoute) {
            currentRoute = _ChangePageMixin.kMorePageRoute;
          } else if (!showAnimeMangaPages &&
              currentRoute == _ChangePageMixin.kMorePageRoute) {
            currentRoute = _ChangePageMixin.kMangaPageRoute;
          }
        });
      }
    });

    initChangePage(this, settings);
    initIcons(this);

    maybeBeforeYouContinueDialog(context, settings);

    NetworkStatus.g.notify = () {
      try {
        setState(() {});
      } catch (_) {}
    };
  }

  @override
  void dispose() {
    _morePageNotifier.dispose();
    _galleryPageNotifier.dispose();
    _booruPageNotifier.dispose();
    _settingsSubscription.cancel();
    disposeIcons();
    disposeChangePage();

    NetworkStatus.g.notify = null;

    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SelectedMorePage(
      notifier: _morePageNotifier,
      child: _SelectedGalleryPage(
        notifier: _galleryPageNotifier,
        child: _SelectedBooruPage(
          notifier: _booruPageNotifier,
          child: PopScope(
            canPop: widget.callback != null,
            onPopInvoked: (pop) =>
                _procPopAll(_galleryPageNotifier, _morePageNotifier, this, pop),
            child: Builder(
              builder: (context) {
                return _SelectionHolder(
                  hide: hide,
                  defaultPreferences: widget.callback != null
                      ? {}
                      : {GluePreferences.persistentBarHeight},
                  child: HomeSkeleton(
                    state,
                    (context) => _currentPage(
                      context,
                      _galleryPageNotifier,
                      _morePageNotifier,
                      _booruPageNotifier,
                      this,
                      showAnimeMangaPages,
                    ),
                    navBar: _NavBar(
                      noNavigationIcons: widget.callback != null,
                      icons: this,
                      child: Builder(
                        builder: (context) => NavigationBar(
                          labelBehavior: NavigationDestinationLabelBehavior
                              .onlyShowSelected,
                          backgroundColor: theme.colorScheme.surfaceContainer
                              .withOpacity(0.95),
                          selectedIndex: currentRoute,
                          onDestinationSelected: (route) {
                            if (route == 0 && currentRoute == 0) {
                              Scaffold.of(context).openDrawer();
                            } else if (route == 1 && currentRoute == 1) {
                              _galleryPageNotifier.value =
                                  _galleryPageNotifier.value ==
                                          GallerySubPage.gallery
                                      ? GallerySubPage.blacklisted
                                      : GallerySubPage.gallery;
                            } else if (settings.showAnimeMangaPages
                                ? route == _ChangePageMixin.kMorePageRoute &&
                                    currentRoute ==
                                        _ChangePageMixin.kMorePageRoute
                                : route == _ChangePageMixin.kMangaPageRoute &&
                                    currentRoute ==
                                        _ChangePageMixin.kMangaPageRoute) {
                              _morePageNotifier.value =
                                  _morePageNotifier.value == MoreSubPage.more
                                      ? MoreSubPage.dashboard
                                      : MoreSubPage.more;
                            } else {
                              _switchPage(this, route, showAnimeMangaPages);
                            }
                          },
                          destinations: widget.callback != null
                              ? const []
                              : icons(
                                  context,
                                  currentRoute,
                                  settings,
                                  showAnimeMangaPages,
                                ),
                        ),
                      ),
                    ),
                    extendBody: true,
                    noNavBar: widget.callback != null,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.icons,
    required this.noNavigationIcons,
    required this.child,
  });

  final bool noNavigationIcons;
  final _AnimatedIconsMixin icons;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glueState = _GlueStateProvider.of(context);
    SelectionCountNotifier.countOf(context);

    return noNavigationIcons
        ? Animate(
            controller: icons.controllerNavBar,
            target: glueState.actions?.$1 == null ? 0 : 1,
            effects: [
              MoveEffect(
                duration: 220.ms,
                curve: Easing.emphasizedDecelerate,
                end: Offset.zero,
                begin:
                    Offset(0, 100 + MediaQuery.viewPaddingOf(context).bottom),
              ),
            ],
            child: GlueBottomAppBar(glueState),
          )
        : Animate(
            controller: icons.controllerNavBar,
            target: glueState.actions != null ? 1 : 0,
            effects: [
              const MoveEffect(
                curve: Easing.emphasizedAccelerate,
                begin: Offset.zero,
                end: Offset(0, 100),
              ),
              SwapEffect(
                builder: (context, _) {
                  return glueState.actions != null
                      ? Animate(
                          effects: [
                            MoveEffect(
                              duration: 100.ms,
                              curve: Easing.emphasizedDecelerate,
                              begin: const Offset(0, 100),
                              end: Offset.zero,
                            ),
                          ],
                          child: GlueBottomAppBar(glueState),
                        )
                      : const Padding(padding: EdgeInsets.zero);
                },
              ),
            ],
            child: child,
          );
  }
}

class _SelectionHolder extends StatefulWidget {
  const _SelectionHolder({
    required this.hide,
    required this.defaultPreferences,
    required this.child,
  });
  final Widget child;
  final Set<GluePreferences> defaultPreferences;

  final void Function(bool backward) hide;

  @override
  State<_SelectionHolder> createState() => __SelectionHolderState();
}

class __SelectionHolderState extends State<_SelectionHolder> {
  late final SelectionGlueState glueState;

  @override
  void initState() {
    super.initState();

    glueState = SelectionGlueState(hide: widget.hide);
  }

  SelectionGlue _generate([Set<GluePreferences> set = const {}]) {
    final s = set.isNotEmpty ? set : widget.defaultPreferences;

    return glueState.glue(
      keyboardVisible,
      setState,
      () => s.contains(GluePreferences.zeroSize) ? 0 : 80,
      s.contains(GluePreferences.persistentBarHeight),
    );
  }

  bool keyboardVisible() => MediaQuery.viewInsetsOf(context).bottom != 0;

  @override
  Widget build(BuildContext context) {
    return _GlueStateProvider(
      state: glueState,
      child: SelectionCountNotifier(
        count: glueState.count,
        countUpdateTimes: glueState.countUpdateTimes,
        child: GlueProvider(
          generate: _generate,
          child: widget.child,
        ),
      ),
    );
  }
}

class _GlueStateProvider extends InheritedWidget {
  const _GlueStateProvider({
    required this.state,
    required super.child,
  });
  final SelectionGlueState state;

  static SelectionGlueState of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_GlueStateProvider>();

    return widget!.state;
  }

  @override
  bool updateShouldNotify(_GlueStateProvider oldWidget) {
    return state != oldWidget.state;
  }
}

class _SelectedBooruPage
    extends InheritedNotifier<ValueNotifier<BooruSubPage>> {
  const _SelectedBooruPage({
    required ValueNotifier<BooruSubPage> notifier,
    required super.child,
  }) : super(notifier: notifier);
}

class _SelectedGalleryPage
    extends InheritedNotifier<ValueNotifier<GallerySubPage>> {
  const _SelectedGalleryPage({
    required ValueNotifier<GallerySubPage> notifier,
    required super.child,
  }) : super(notifier: notifier);
}

class _SelectedMorePage extends InheritedNotifier<ValueNotifier<MoreSubPage>> {
  const _SelectedMorePage({
    required ValueNotifier<MoreSubPage> notifier,
    required super.child,
  }) : super(notifier: notifier);
}
