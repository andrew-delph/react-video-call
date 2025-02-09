// Flutter imports:

// Dart imports:
import 'dart:developer';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';

// Project imports:
import 'package:flutter_app/widgets/page_container.dart';
import '../controllers/home_controller.dart';
import '../routes/app_pages.dart';
import '../services/auth_service.dart';
import 'notifications_button.dart';

class NavItem {
  final IconData iconData;
  final String route;
  final String header;

  NavItem({
    required this.iconData,
    required this.route,
    required this.header,
  });
}

final List<NavItem> navList = [
  NavItem(iconData: Icons.home, route: Routes.HOME, header: "Home"),
  NavItem(iconData: Icons.history, route: Routes.HISTORY, header: "History"),
  NavItem(iconData: Icons.chat_rounded, route: Routes.CHAT, header: "Chat"),
  NavItem(iconData: Icons.settings, route: Routes.OPTIONS, header: "Settings"),
];

class AppMenu extends GetResponsiveView {
  final Widget body;
  final String title;
  final AuthService authService = Get.find();

  RxBool displayMenu = true.obs;

  AppMenu(
      {super.key,
      required this.body,
      required this.title,
      super.alwaysUseBuilder = true});

  List<Widget> actions() {
    return <Widget>[
      if (authService.isAuthenticated()) const NotificationsButton(),
      authService.isAuthenticated()
          ? IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                Get.find<AuthService>().signOut();
              },
            )
          : Container(
              margin: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Get.theme.focusColor)),
                onPressed: () {
                  authService.signOut();
                },
                child: const Text('Sign In'),
              ))
    ];
  }

  @override
  Widget? builder() {
    try {
      HomeController homeController = Get.find<HomeController>();
      homeController.addListener(() {
        displayMenu(homeController.state == null);
      });
    } catch (_) {
      log("Could not find HomeController in App Menu");
    }
    return null;
  }

  @override
  Widget? desktop() {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(title),
          actions: actions(),
        ),
        body: Obx(
          () => Row(
            children: [
              if (displayMenu())
                Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: navList.map((navItem) {
                        return leftNavItem(navItem);
                      }).toList(),
                    )),
              if (displayMenu()) const VerticalDivider(),
              PageContainer(child: body)
            ],
          ),
        ));
  }

  @override
  Widget? tablet() {
    return Obx(() => Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(title),
            actions: actions(),
          ),
          body: Row(children: [PageContainer(child: body)]),
          bottomNavigationBar: (displayMenu())
              ? BottomNavigationBar(
                  currentIndex: navList.indexWhere(
                      (navItem) => navItem.route == Get.currentRoute),
                  onTap: (value) {
                    String route = navList[value].route;
                    Get.toNamed(route);
                  },
                  items: navList.map((navItem) {
                    return bottomNavItem(navItem);
                  }).toList(),
                )
              : null,
        ));
  }

  Widget leftNavItem(NavItem navItem) {
    return LeftNavWidget(navItem: navItem);
  }

  BottomNavigationBarItem bottomNavItem(NavItem navItem) {
    return BottomNavigationBarItem(
        icon: Icon(navItem.iconData), label: navItem.header);
  }
}

class LeftNavWidget extends StatelessWidget {
  final NavItem navItem;

  const LeftNavWidget({super.key, required this.navItem});

  @override
  Widget build(BuildContext context) {
    bool selected = navItem.route == Get.currentRoute;
    return InkWell(
        onTap: () {
          Get.toNamed(navItem.route);
        },
        hoverColor: Get.theme.hoverColor,
        child: Container(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color:
                      selected ? Get.theme.primaryColor : Get.theme.canvasColor,
                  width: 6.0,
                ),
              ),
            ),
            child: Row(children: [
              Icon(navItem.iconData),
              Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Text(navItem.header))
            ])));
  }
}
