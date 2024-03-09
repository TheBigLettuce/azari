// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery/main.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/db/tags/post_tags.dart';
import 'package:gallery/src/pages/home.dart';
import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:permission_handler/permission_handler.dart';

class AndroidPermissionsPage extends StatefulWidget {
  final bool doNotLaunchHome;

  const AndroidPermissionsPage({
    super.key,
    required this.doNotLaunchHome,
  });

  @override
  State<AndroidPermissionsPage> createState() => _AndroidPermissionsPageState();
}

class _AndroidPermissionsPageState extends State<AndroidPermissionsPage> {
  bool photoAndVideos = false;
  bool notifications = false;
  bool mediaLocation = false;
  bool storage = false;
  bool manageMedia = false;

  bool? manageMediaSupported;

  @override
  void initState() {
    super.initState();

    PlatformFunctions.manageMediaSupported().then(
      (value) => setState(() {
        manageMediaSupported = value;

        if (value) {
          PlatformFunctions.manageMediaStatus().then(
            (value) => setState(() {
              manageMedia = value;
            }),
          );
        }
      }),
    );

    Permission.notification.status.then((value) async {
      notifications = value.isGranted;
      photoAndVideos = await Permission.photos.isGranted &&
          await Permission.videos.isGranted;
      mediaLocation = await Permission.accessMediaLocation.isGranted;
      storage = await Permission.storage.isGranted;
      await Permission.storage.request();

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return _WrapPadding(
      title: "Permissions",
      explanation: "Photos and videos are mandatory",
      body: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilledButton.tonalIcon(
                onPressed: photoAndVideos
                    ? null
                    : () async {
                        final resultPhotos = await Permission.photos.request();
                        final resultVideos = await Permission.videos.request();

                        setState(() {
                          photoAndVideos =
                              resultVideos.isGranted && resultPhotos.isGranted;
                        });
                      },
                icon: photoAndVideos
                    ? const Icon(Icons.check_rounded)
                    : const Icon(Icons.photo),
                label: Text("Photos and videos"),
              ),
              const Padding(padding: EdgeInsets.only(top: 8)),
              FilledButton.tonalIcon(
                onPressed: mediaLocation
                    ? null
                    : () async {
                        final result =
                            await Permission.accessMediaLocation.request();

                        setState(() {
                          mediaLocation = result.isGranted;
                        });
                      },
                icon: mediaLocation
                    ? const Icon(Icons.check_rounded)
                    : const Icon(Icons.folder_copy),
                label: Text("Media location"),
              ),
              if (manageMediaSupported != null && manageMediaSupported!) ...[
                const Padding(padding: EdgeInsets.only(top: 8)),
                FilledButton.tonalIcon(
                  onPressed: manageMedia
                      ? null
                      : () async {
                          final result =
                              await PlatformFunctions.requestManageMedia();

                          setState(() {
                            manageMedia = result;
                          });
                        },
                  icon: manageMedia
                      ? const Icon(Icons.check_rounded)
                      : const Icon(Icons.perm_media),
                  label: Text("Manage media"),
                ),
              ],
              // const Padding(padding: EdgeInsets.only(top: 8)),
              // FilledButton.tonalIcon(
              //   onPressed: storage
              //       ? null
              //       : () async {
              //           final result = await Permission.storage.request();

              //           setState(() {
              //             storage = result.isGranted;
              //           });
              //         },
              //   icon: storage
              //       ? const Icon(Icons.check_rounded)
              //       : const Icon(Icons.storage_rounded),
              //   label: Text("Storage"),
              // ),
              const Padding(padding: EdgeInsets.only(top: 8)),
              FilledButton.tonalIcon(
                onPressed: notifications
                    ? null
                    : () async {
                        final result = await Permission.notification.request();

                        setState(() {
                          notifications = result.isGranted;
                        });
                      },
                icon: notifications
                    ? const Icon(Icons.check_rounded)
                    : const Icon(Icons.notifications_rounded),
                label: Text("Notifications"),
              ),
            ],
          ),
        ),
      ),
      buttons: [
        FilledButton.icon(
          icon: const Icon(Icons.navigate_next_rounded),
          onPressed: !photoAndVideos
              ? null
              : () {
                  Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (context) {
                      return CongratulationPage(
                        doNotLaunchHome: widget.doNotLaunchHome,
                      );
                    },
                  ));
                },
          label: Text("Next"),
        ),
      ],
    );
  }
}

class WelcomePage extends StatefulWidget {
  final bool doNotLaunchHome;

  const WelcomePage({super.key, this.doNotLaunchHome = false});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      changeSystemUiOverlay(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _WrapPadding(
      title: "Welcome",
      addCenteredIcon: true,
      body: Text(
        "Some settings before you continue... 🛠️",
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      buttons: [
        FilledButton.icon(
          icon: const Icon(Icons.navigate_next_rounded),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (context) {
                return PickFilePage(
                  doNotLaunchHome: widget.doNotLaunchHome,
                );
              },
            ));
          },
          label: Text("Next"),
        )
      ],
    );
  }
}

class CongratulationPage extends StatelessWidget {
  final bool doNotLaunchHome;

  const CongratulationPage({
    super.key,
    required this.doNotLaunchHome,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        _WrapPadding(
          addCenteredIcon: true,
          body: Center(
            child: Text(
              "Enjoy using Azari 🥳",
              style: theme.textTheme.bodyLarge,
            ),
          ),
          buttons: [
            FilledButton.icon(
              icon: const Icon(Icons.check_rounded),
              onPressed: () {
                Settings.fromDb().copy(showWelcomePage: false).save();
                initPostTags(context);

                if (doNotLaunchHome) {
                  Navigator.pop(context);

                  return;
                }

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const Home();
                    },
                  ),
                );
              },
              label: Text("Finish"),
            )
          ],
          title: "Done",
        )
      ],
    );
  }
}

class PickFilePage extends StatefulWidget {
  final bool doNotLaunchHome;

  const PickFilePage({
    super.key,
    required this.doNotLaunchHome,
  });

  @override
  State<PickFilePage> createState() => _PickFilePageState();
}

class _PickFilePageState extends State<PickFilePage> {
  late final StreamSubscription<void> watcher;
  Settings settings = Settings.fromDb();

  String? error;

  @override
  void initState() {
    super.initState();

    watcher = Settings.watch((s) {
      settings = s!;

      error = null;

      setState(() {});
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  void _nextPage() {
    if (Platform.isAndroid) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) {
          return AndroidPermissionsPage(
            doNotLaunchHome: widget.doNotLaunchHome,
          );
        },
      ));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) {
          return CongratulationPage(
            doNotLaunchHome: widget.doNotLaunchHome,
          );
        },
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _WrapPadding(
      title: "Download directory",
      explanation: "Download directory is used for multiple purposes",
      body: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledButton.tonalIcon(
              icon: settings.path.isNotEmpty
                  ? const Icon(Icons.check_rounded)
                  : const Icon(Icons.folder),
              onPressed: () {
                Settings.chooseDirectory((e) {
                  error = e;

                  setState(() {});
                });
              },
              label: Text(
                  settings.path.isEmpty ? "Pick" : settings.path.pathDisplay),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  error!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
          ],
        ),
      ),
      buttons: [
        FilledButton.icon(
          icon: const Icon(Icons.navigate_next_rounded),
          onPressed: settings.path.isEmpty ? null : _nextPage,
          label: const Text("Next"),
        )
      ],
    );
  }
}

class _WrapPadding extends StatelessWidget {
  final List<Widget> buttons;
  final String title;
  final Widget body;
  final String? explanation;
  final bool addCenteredIcon;

  const _WrapPadding({
    super.key,
    required this.body,
    required this.buttons,
    required this.title,
    this.explanation,
    this.addCenteredIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding:
            const EdgeInsets.only(top: 80, bottom: 40, left: 40, right: 40),
        child: Stack(
          children: [
            if (addCenteredIcon)
              Center(
                child: Transform.rotate(
                  angle: 0.4363323,
                  child: Icon(
                    const IconData(0x963F),
                    size: 78,
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    applyTextScaling: true,
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.headlineLarge,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: body,
                      ),
                    ],
                  ),
                ),
                explanation == null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: buttons,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: theme.colorScheme.secondary.withOpacity(0.8),
                            applyTextScaling: true,
                          ),
                          const Padding(padding: EdgeInsets.only(left: 8)),
                          Expanded(
                            child: Text(
                              explanation!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.8),
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Padding(padding: EdgeInsets.only(left: 8)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: buttons,
                          ),
                        ],
                      )
              ],
            )
          ],
        ),
      ),
    );
  }
}
