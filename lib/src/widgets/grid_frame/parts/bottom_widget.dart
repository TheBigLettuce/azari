// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../grid_frame.dart";

class _BottomWidget extends StatefulWidget {
  const _BottomWidget({
    required this.progress,
    required this.child,
  });

  final RefreshingProgress progress;

  final Widget child;

  @override
  State<_BottomWidget> createState() => __BottomWidgetState();
}

class __BottomWidgetState extends State<_BottomWidget> {
  RefreshingProgress get progress => widget.progress;

  late final StreamSubscription<bool> _watcher;

  @override
  void initState() {
    _watcher = progress.watch((_) {
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return !progress.inRefreshing
        ? widget.child
        : const LinearProgressIndicator(
            year2023: false,
          );
  }
}
