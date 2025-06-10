// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/search/fading_panel.dart";
import "package:azari/src/ui/material/widgets/empty_widget.dart";
import "package:azari/src/ui/material/widgets/shimmer_placeholders.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> with SettingsWatcherMixin {
  late final BooruComunnityAPI api;
  late final Dio client;

  @override
  void initState() {
    super.initState();

    client = BooruAPI.defaultClientForBooru(settings.selectedBooru);
    api = BooruComunnityAPI.fromEnum(settings.selectedBooru, client);
  }

  @override
  void dispose() {
    client.close(force: true);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: EmptyWidgetBackground(
        subtitle: "Not implemented", // TODO: change
      ),
    );
  }
}

class _PoolsBody extends StatefulWidget {
  const _PoolsBody({
    // super.key,
    required this.api,
  });

  final BooruPoolsAPI api;

  @override
  State<_PoolsBody> createState() => __PoolsBodyState();
}

class __PoolsBodyState extends State<_PoolsBody> {
  late final GenericListSource<BooruPool> source;
  final pageSaver = PageSaver.noPersist();

  @override
  void initState() {
    super.initState();

    source = GenericListSource(() => widget.api.search(pageSaver: pageSaver));
    source.clearRefresh();
  }

  @override
  void dispose() {
    source.destroy();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadingPanel(
      label: "Pools",
      source: source,
      enableHide: false,
      childSize: _PoolsPanelBody.size,
      child: _PoolsPanelBody(source: source),
    );
  }
}

class _PoolsPanelBody extends StatefulWidget {
  const _PoolsPanelBody({
    // super.key,
    required this.source,
  });

  final GenericListSource<BooruPool> source;

  static const Size size = Size(100, 100);

  @override
  State<_PoolsPanelBody> createState() => __PoolsPanelBodyState();
}

class __PoolsPanelBodyState extends State<_PoolsPanelBody> {
  late final StreamSubscription<void> events;

  @override
  void initState() {
    super.initState();

    events = widget.source.progress.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _PoolsPanelBody.size.height,
      child: switch (widget.source.progress.inRefreshing) {
        true => const ShimmerPlaceholdersHorizontal(
          childSize: _PoolsPanelBody.size,
        ),
        false => ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          scrollDirection: Axis.horizontal,
          itemCount: widget.source.count,
          itemBuilder: (context, index) {
            final pool = widget.source.backingStorage[index];

            return SizedBox(
              width: _PoolsPanelBody.size.width,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    // Expanded(
                    //     child: GridCellImage(
                    //         blur: false,
                    //         imageAlign: Alignment.topCenter,
                    //         thumbnail: CachedNetworkImageProvider())),
                    SizedBox(height: 20, child: Text(pool.name)),
                  ],
                ),
              ),
            );
          },
        ),
      },
    );
  }
}
