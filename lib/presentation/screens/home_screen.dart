import 'dart:ui'; // Para ImageFilter
import 'package:flutter/cupertino.dart';
import 'package:grow_garden_tracker/core/theme/app_theme.dart'; // Importar AppTheme
import 'package:grow_garden_tracker/features/settings/screens/settings_screen.dart';
import 'package:grow_garden_tracker/features/sniper/screens/sniper_screen.dart';
import 'package:grow_garden_tracker/features/stock/screens/stock_host_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Iconos actualizados para un look más moderno y minimalista, manteniendo la claridad.
  // CupertinoIcons.square_grid_2x2 (para Stock) es más ligero que rectangle_grid_2x2_fill.
  // CupertinoIcons.scope (para Sniper) ya es adecuado.
  // CupertinoIcons.settings (para Ajustes) es más ligero que settings_solid.
  static const IconData stockIcon = CupertinoIcons.square_grid_2x2;
  static const IconData sniperIcon = CupertinoIcons.scope;
  static const IconData settingsIcon = CupertinoIcons.settings;

  @override
  Widget build(BuildContext context) {
    // Obtener el color de fondo de la barra de pestañas del tema
    final tabBarBackgroundColor = AppTheme.cupertinoTheme.barBackgroundColor ?? AppTheme.glassBarBackgroundColor;
    final activeColor = AppTheme.cupertinoTheme.primaryColor ?? AppTheme.primaryAppColor;
    final inactiveColor = CupertinoColors.systemGrey; // Color estándar de iOS para iconos inactivos

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: tabBarBackgroundColor.withOpacity(0.9), // Aplicar opacidad para el efecto translúcido
        border: Border(top: BorderSide(color: AppTheme.glassBorderColor.withOpacity(0.5), width: 0.5)), // Borde sutil superior
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        // Efecto de desenfoque para la barra de pestañas, si se desea un efecto glass más pronunciado
        // Esto requiere que el widget que está detrás de la TabBar no sea completamente opaco.
        // Para un efecto completo, el contenido de las pestañas también debería estar bajo un BackdropFilter
        // o la TabBar debería estar flotante. Por ahora, solo aplicamos el color translúcido.
        // Si se quiere un blur directo en la TabBar, se tendría que construir una TabBar personalizada.
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(stockIcon),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(sniperIcon),
            label: 'Sniper',
          ),
          BottomNavigationBarItem(
            icon: Icon(settingsIcon),
            label: 'Ajustes',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        Widget? screen; // Usar Widget? como tipo para la pantalla
        switch (index) {
          case 0:
            screen = CupertinoTabView(builder: (context) {
              return const StockHostScreen();
            });
            break;
          case 1:
            screen = CupertinoTabView(builder: (context) {
              return const SniperScreen();
            });
            break;
          case 2:
            screen = CupertinoTabView(builder: (context) {
              return const SettingsScreen();
            });
            break;
        }
        // Devolver la pantalla seleccionada o la primera por defecto si algo sale mal.
        return screen ?? CupertinoTabView(builder: (context) => const StockHostScreen());
      },
    );
  }
}
