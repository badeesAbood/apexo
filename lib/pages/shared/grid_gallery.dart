import 'package:apexo/backend/utils/imgs.dart';
import 'package:apexo/pages/shared/slideshow/slideshow.dart';
import 'package:fluent_ui/fluent_ui.dart';

class GridGallery extends StatelessWidget {
  final List<String> imgs;
  final void Function(String img)? onPressDelete;
  final int countPerLine;
  final double rowWidth;
  final double? size;
  final int clipCount;
  final bool progress;
  const GridGallery({
    super.key,
    required this.imgs,
    required this.progress,
    this.onPressDelete,
    this.countPerLine = 3,
    this.rowWidth = 350,
    this.size,
    this.clipCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    const double spacing = 4;
    final double calculatedSized = ((rowWidth - (spacing * (countPerLine * 4))) / countPerLine);
    return SizedBox(
      width: rowWidth,
      child: Padding(
        padding: const EdgeInsets.all(spacing),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          spacing: spacing, // Horizontal space between items
          runSpacing: spacing, // Vertical space between rows
          children: List.generate(imgs.length, (index) {
            if (clipCount > 0 && index >= clipCount) return const SizedBox.shrink();
            return SizedBox(
              width: size ?? calculatedSized, // Adjust for desired column count
              height: size ?? calculatedSized,
              child: _buildSingleImage(context, index),
            );
          }),
        ),
      ),
    );
  }

  _buildSingleImage(BuildContext context, int index) {
    final img = imgs[index];
    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<ImageProvider<Object>>(
          future: getImage(img),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              return GestureDetector(
                onTap: () => showAllImages(context, img),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0), // Optional rounded corners
                  child: Image(
                    image: snapshot.data!,
                    fit: BoxFit.cover, // Crops the image to fit the space
                  ),
                ),
              );
            } else {
              return const Center(
                child: ProgressRing(), // Placeholder while loading
              );
            }
          },
        ),
        if (onPressDelete != null && progress == false)
          Positioned(
            top: 4,
            right: 4,
            child: Acrylic(
              elevation: 20,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
              child: IconButton(
                icon: const Icon(FluentIcons.delete),
                onPressed: () => onPressDelete?.call(img),
              ),
            ),
          ),
        if (index == clipCount - 1 && imgs.length > clipCount)
          SizedBox.expand(
            child: GestureDetector(
              onTap: () => showAllImages(context, imgs[0]),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: kElevationToShadow[1],
                  border: Border.all(color: Colors.white, width: 0.4),
                ),
                child: Center(
                  child: Text("+${(imgs.length - clipCount + 1).toString()}",
                      style: const TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ),
          )
      ],
    );
  }

  showAllImages(BuildContext context, String firstImg) async {
    final list = await Future.wait([firstImg, ...imgs.where((x) => x != firstImg)].map((e) => getImage(e)).toList());

    MultiImageProvider multiImageProvider = MultiImageProvider(list);

    if (context.mounted) {
      showImageViewerPager(
        context,
        multiImageProvider,
        backgroundColor: Colors.black.withOpacity(0.9),
        doubleTapZoomable: true,
        immersive: false,
        swipeDismissible: true,
        closeButtonColor: Colors.white,
        infinitelyScrollable: true,
      );
    }
  }
}
