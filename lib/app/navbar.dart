import 'package:apexo/app/routes.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:fluent_ui/fluent_ui.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      height: 73,
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Acrylic(
          elevation: 20,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: StreamBuilder(
                stream: routes.currentRouteIndex.stream,
                builder: (context, snapshot) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ...routes.allRoutes.where((r) => r.navbarTitle.isNotEmpty).map((r) => BottomNavBarButton(
                            icon: r.icon,
                            identifier: r.identifier,
                            title: r.navbarTitle,
                            active: r.identifier == routes.currentRoute.identifier,
                          )),
                      const Divider(direction: Axis.vertical),
                      FlyoutTarget(
                        controller: routes.bottomNavFlyoutController,
                        child: IconButton(
                          icon: const Icon(FluentIcons.more),
                          onPressed: () => routes.bottomNavFlyoutController.showFlyout(
                            dismissWithEsc: true,
                            builder: (context) => MenuFlyout(items: [
                              for (var route in routes.allRoutes.where((r) => r.navbarTitle.isEmpty))
                                MenuFlyoutItem(
                                  leading: Icon(route.icon),
                                  text: Txt(route.title),
                                  onPressed: () => routes.navigate(routes.getByIdentifier(route.identifier)!),
                                  closeAfterClick: true,
                                )
                            ]),
                          ),
                        ),
                      )
                    ],
                  );
                }),
          ),
        ),
      ),
    );
  }
}

class BottomNavBarButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final String identifier;
  final bool active;
  const BottomNavBarButton({
    super.key,
    required this.title,
    required this.icon,
    required this.identifier,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      style: active
          ? ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.blue.withValues(alpha: 0.05)),
              shape: WidgetStatePropertyAll(
                RoundedRectangleGradientBorder(
                  borderRadius: BorderRadius.circular(7),
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [Colors.blue, Colors.blue.withValues(alpha: 0.3), Colors.blue],
                  ),
                  width: 0.3,
                  strokeAlign: 1,
                ),
              ),
            )
          : null,
      icon: Column(
        children: [
          Icon(icon, color: active ? Colors.blue : null),
          Txt(title, style: TextStyle(fontSize: 11, color: active ? Colors.blue : null)),
        ],
      ),
      onPressed: () => routes.navigate(routes.getByIdentifier(identifier)!),
    );
  }
}
