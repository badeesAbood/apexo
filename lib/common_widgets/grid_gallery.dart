import 'package:apexo/common_widgets/dialogs/loading_blocking.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/utils/imgs.dart';
import 'package:apexo/common_widgets/slideshow/slideshow.dart';
import 'package:fluent_ui/fluent_ui.dart';

class GridGallery extends StatefulWidget {
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
  State<GridGallery> createState() => _GridGalleryState();
}

class _GridGalleryState extends State<GridGallery> {
  final Set<ImageProvider> _imageProviders = {};

  @override
  void dispose() {
    super.dispose();
    for (final imageProvider in _imageProviders) {
      imageProvider.evict();
    }
  }

  @override
  Widget build(BuildContext context) {
    const double spacing = 4;
    final double calculatedSized = ((widget.rowWidth - (spacing * (widget.countPerLine * 4))) / widget.countPerLine);
    return SizedBox(
      width: widget.rowWidth,
      child: Padding(
        padding: const EdgeInsets.all(spacing),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          spacing: spacing,
          runSpacing: spacing,
          children: [
            ...List<Widget>.from(List.generate(widget.imgs.length, (index) {
              if (widget.clipCount > 0 && index >= widget.clipCount) return null;
              return SizedBox(
                width: widget.size ?? calculatedSized, // Adjust for desired column count
                height: widget.size ?? calculatedSized,
                child: _buildSingleImage(context, index),
              );
            }).where((e) => e != null)),
            if (widget.imgs.length > 1)
              SizedBox(
                width: widget.size ?? calculatedSized, // Adjust for desired column count
                height: widget.size ?? calculatedSized,
                child: FilledButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.grey.withValues(alpha: 0.8)),
                    foregroundColor: const WidgetStatePropertyAll(Colors.white),
                    elevation: const WidgetStatePropertyAll(5),
                  ),
                  onPressed: () => openSlideShow(context, widget.imgs.first),
                  child: Icon(FluentIcons.play_resume, size: calculatedSized / 2),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildSingleImage(BuildContext context, int index) {
    final img = widget.imgs[index];
    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<ImageProvider<Object>?>(
          future: getImage(widget.rowId, img),
          builder: (context, snapshot) {
            if (snapshot.data != null) {
              _imageProviders.add(snapshot.data!);
            }
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
        if (widget.onPressDelete != null && widget.progress == false)
          Positioned(
            top: 4,
            right: 4,
            child: Acrylic(
              elevation: 20,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
              child: IconButton(
                icon: const Icon(FluentIcons.delete),
                onPressed: () => widget.onPressDelete?.call(img),
              ),
            ),
          ),
        if (index == widget.clipCount - 1 && widget.imgs.length > widget.clipCount)
          SizedBox.expand(
            child: GestureDetector(
              onTap: () => openSingleImage(context, widget.imgs[index]),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: kElevationToShadow[1],
                  border: Border.all(color: Colors.white, width: 0.4),
                ),
                child: Center(
                  child: Text("+${(widget.imgs.length - widget.clipCount + 1).toString()}",
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
      provider = await getImage(widget.rowId, img, false) ?? const AssetImage("assets/images/missing.png");
    } finally {
      if (context.mounted) Navigator.of(context).pop();
    }
    if (context.mounted) {
      _imageProviders.add(provider);
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
      final List<ImageProvider<Object>> list = (await Future.wait([firstImg, ...widget.imgs.where((x) => x != firstImg)]
              .map((img) => getImage(widget.rowId, img, false))
              .toList()))
          .map((el) => el ?? const AssetImage("assets/images/missing.png"))
          .toList();
      multiImageProvider = MultiImageProvider(list);
    } finally {
      if (context.mounted) Navigator.of(context).pop();
    }

    if (context.mounted && multiImageProvider.imageCount > 0) {
      _imageProviders.addAll(multiImageProvider.imageProviders);
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
