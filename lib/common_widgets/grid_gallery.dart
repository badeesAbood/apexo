import 'package:apexo/common_widgets/dialogs/loading_blocking.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/utils/imgs.dart';
import 'package:apexo/common_widgets/slideshow/slideshow.dart';
import 'package:fluent_ui/fluent_ui.dart';

class GridGallery extends StatelessWidget {
  final String rowId;
  final List<String> imgs;
  final void Function(String img)? onPressDelete;
  final int countPerLine;
  final double rowWidth;
  final double? size;
  final int clipCount;
  final bool progress;
  const GridGallery({
    super.key,
    required this.rowId,
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
          spacing: spacing,
          runSpacing: spacing,
          children: [
            ...List<Widget>.from(List.generate(imgs.length, (index) {
              if (clipCount > 0 && index >= clipCount) return null;
              return SizedBox(
                width: size ?? calculatedSized, // Adjust for desired column count
                height: size ?? calculatedSized,
                child: _buildSingleImage(context, index),
              );
            }).where((e) => e != null)),
            if (imgs.length > 1)
              SizedBox(
                width: size ?? calculatedSized, // Adjust for desired column count
                height: size ?? calculatedSized,
                child: FilledButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.grey.withValues(alpha: 0.8)),
                    foregroundColor: const WidgetStatePropertyAll(Colors.white),
                    elevation: const WidgetStatePropertyAll(5),
                  ),
                  onPressed: () => openSlideShow(context, imgs.first),
                  child: Icon(FluentIcons.play_resume, size: calculatedSized / 2),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildSingleImage(BuildContext context, int index) {
    final img = imgs[index];
    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<ImageProvider<Object>?>(
          future: getImage(rowId, img),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              return GestureDetector(
                onTap: () => openSingleImage(context, img),
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
              onTap: () => openSingleImage(context, imgs[index]),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
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

  void openSingleImage(BuildContext context, String img) async {
    showLoadingBlockingDialog(context, txt("gettingImages"));
    final ImageProvider provider;
    try {
      provider = await getImage(rowId, img, false) ?? const AssetImage("assets/images/missing.png");
    } finally {
      if (context.mounted) Navigator.of(context).pop();
    }
    if (context.mounted) {
      showImageViewer(
        context,
        provider,
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        doubleTapZoomable: true,
        immersive: false,
        swipeDismissible: true,
        closeButtonColor: Colors.white,
      );
    }
  }

  void openSlideShow(BuildContext context, String firstImg) async {
    showLoadingBlockingDialog(context, txt("gettingImages"));
    MultiImageProvider multiImageProvider;
    try {
      final List<ImageProvider<Object>> list = (await Future.wait(
              [firstImg, ...imgs.where((x) => x != firstImg)].map((img) => getImage(rowId, img, false)).toList()))
          .map((el) => el ?? const AssetImage("assets/images/missing.png"))
          .toList();
      multiImageProvider = MultiImageProvider(list);
    } finally {
      if (context.mounted) Navigator.of(context).pop();
    }

    if (context.mounted && multiImageProvider.imageCount > 0) {
      showImageViewerPager(
        context,
        multiImageProvider,
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        doubleTapZoomable: true,
        immersive: false,
        swipeDismissible: true,
        closeButtonColor: Colors.white,
        infinitelyScrollable: true,
      );
    }
  }
}
