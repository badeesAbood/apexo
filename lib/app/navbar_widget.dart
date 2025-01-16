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
      height: 60,
      width: MediaQuery.of(context).size.width,
      child: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.05)))),
        child: Acrylic(
          elevation: 30,
          child: Padding(
            padding: const EdgeInsets.all(1),
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
      icon: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              color: active ? Colors.blue : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: active ? Colors.white : null,
              size: 18,
            ),
          ),
          Txt(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: active ? Colors.blue : null,
            ),
          ),
        ],
      ),
      onPressed: () => routes.navigate(routes.getByIdentifier(identifier)!),
    );
  }
}
