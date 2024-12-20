// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "image_view.dart";

// class ImageViewBody extends StatelessWidget {
//   const ImageViewBody({
//     super.key,
//     required this.onPageChanged,
//     required this.pageController,
//     required this.builder,
//     required this.loadingBuilder,
//     required this.itemCount,
//     required this.onLongPress,
//     required this.onTap,
//     required this.onPressedLeft,
//     required this.onPressedRight, required this.countEvents,
//   });

//   final int itemCount;
//   final Stream<int> countEvents;

//   final PageController pageController;
//   final ContentIdxCallback onPageChanged;

//   final VoidCallback onTap;
//   final VoidCallback onLongPress;

//   final VoidCallback? onPressedRight;
//   final VoidCallback? onPressedLeft;

//   final PhotoViewGalleryPageOptions Function(BuildContext, int) builder;
//   final Widget Function(BuildContext, ImageChunkEvent?, int)? loadingBuilder;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDeadZones(
//       left: true,
//       right: true,
//       onPressedRight: onPressedRight,
//       onPressedLeft: onPressedLeft,
//       child: GestureDetector(
//         onLongPress: onLongPress,
//         onTap: onTap,
//         child: PhotoViewGallery.builder(
//           loadingBuilder: loadingBuilder,
//           enableRotation: true,
//           backgroundDecoration: BoxDecoration(
//             color: Theme.of(context).colorScheme.surface,
//           ),
//           onPageChanged: onPageChanged,
//           pageController: pageController,
//           itemCount: itemCount,
//           builder: builder,
//         ),
//       ),
//     );
//   }
// }

class ImageViewBody extends StatefulWidget {
  const ImageViewBody({
    super.key,
    required this.onPageChanged,
    required this.pageController,
    required this.builder,
    required this.loadingBuilder,
    required this.itemCount,
    required this.onLongPress,
    required this.onTap,
    required this.onPressedLeft,
    required this.onPressedRight,
    required this.countEvents,
  });

  final int itemCount;
  final Stream<int> countEvents;

  final PageController pageController;
  final ContentIdxCallback onPageChanged;

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  final VoidCallback? onPressedRight;
  final VoidCallback? onPressedLeft;

  final PhotoViewGalleryPageOptions Function(BuildContext, int) builder;
  final Widget Function(BuildContext, ImageChunkEvent?, int)? loadingBuilder;

  @override
  State<ImageViewBody> createState() => _ImageViewBodyState();
}

class _ImageViewBodyState extends State<ImageViewBody> {
  late final StreamSubscription<int> countEvents;

  int count = 0;

  @override
  void initState() {
    super.initState();

    count = widget.itemCount;

    countEvents = widget.countEvents.listen((newCount) {
      setState(() {
        count = newCount;
      });
    });
  }

  @override
  void dispose() {
    countEvents.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDeadZones(
      left: true,
      right: true,
      onPressedRight: widget.onPressedRight,
      onPressedLeft: widget.onPressedLeft,
      child: GestureDetector(
        onLongPress: widget.onLongPress,
        onTap: widget.onTap,
        child: PhotoViewGallery.builder(
          loadingBuilder: widget.loadingBuilder,
          enableRotation: true,
          backgroundDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          onPageChanged: widget.onPageChanged,
          pageController: widget.pageController,
          itemCount: count,
          builder: widget.builder,
        ),
      ),
    );
  }
}
