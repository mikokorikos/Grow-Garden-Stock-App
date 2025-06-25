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
            icon: Icon(CupertinoIcons.shopping_cart), // Icon puede ser const
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.scope), // Icon puede ser const
            label: 'Sniper',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings), // Icon puede ser const
            label: 'Ajustes',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        // Las pantallas (StockHostScreen, SniperScreen, SettingsScreen)
        // solo pueden ser const si sus propios constructores son const.
        // Asumiendo que no lo son por ahora, ya que no están en el scope de esta revisión.
        switch (index) {
          case 0:
            return CupertinoTabView(builder: (context) {
              return const StockHostScreen(); // Si StockHostScreen es const
            });
          case 1:
            return CupertinoTabView(builder: (context) {
              return const SniperScreen(); // Si SniperScreen es const
            });
          case 2:
            return CupertinoTabView(builder: (context) {
              return const SettingsScreen(); // Si SettingsScreen es const
            });
          default:
            return CupertinoTabView(builder: (context) {
              return const StockHostScreen(); // Si StockHostScreen es const
            });
        }
      },
    );
  }
}
