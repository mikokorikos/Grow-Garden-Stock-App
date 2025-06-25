import 'package:flutter/cupertino.dart';
import 'package:grow_garden_tracker/features/settings/screens/settings_screen.dart';
import 'package:grow_garden_tracker/features/sniper/screens/sniper_screen.dart';
import 'package:grow_garden_tracker/features/stock/screens/stock_host_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.shopping_cart),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.scope),
            label: 'Sniper',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        switch (index) {
          case 0:
            return CupertinoTabView(builder: (context) {
              return const StockHostScreen();
            });
          case 1:
            return CupertinoTabView(builder: (context) {
              return const SniperScreen();
            });
          case 2:
            return CupertinoTabView(builder: (context) {
              return const SettingsScreen();
            });
          default:
            return CupertinoTabView(builder: (context) {
              return const StockHostScreen();
            });
        }
      },
    );
  }
}
