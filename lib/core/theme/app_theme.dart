import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Necesario para Colors

class AppTheme {
  // Paleta de colores vibrantes
  static const Color electricBlue = Color(0xFF007BFF); // Azul eléctrico
  static const Color neonPurple = Color(0xFFBF00FF); // Púrpura neón
  static const Color cyberOrange = Color(0xFFFFA500); // Naranja cyber

  // Colores base para tema claro
  static const Color primaryAppColor = electricBlue; // Color primario de la app
  static const Color lightScaffoldBackgroundColor = Color(0xFFFFFFFF); // Blanco puro
  static const Color darkTextColor = Color(0xFF000000); // Texto oscuro para contraste
  static const Color lightTextColor = Color(0xFFFFFFFF); // Texto claro para fondos oscuros

  // Colores para Glassmorphism
  // Un blanco ligeramente translúcido para el fondo de elementos glass
  static const Color glassBackgroundColor = Color.fromRGBO(255, 255, 255, 0.65);
  // Color para bordes sutiles en elementos glass
  static const Color glassBorderColor = Color.fromRGBO(255, 255, 255, 0.3);
  // Color para barras (Navigation/Tab bar) con efecto glass
  static const Color glassBarBackgroundColor = Color.fromRGBO(245, 245, 245, 0.85); // Un poco más opaco para legibilidad

  // Tipografía (usaremos la fuente por defecto de Cupertino que es SF Pro)
  static const String appFontFamily = 'SF-Pro-Display';

  static const CupertinoThemeData cupertinoTheme = CupertinoThemeData(
    brightness: Brightness.light, // Tema claro
    primaryColor: primaryAppColor,
    scaffoldBackgroundColor: lightScaffoldBackgroundColor,
    // Fondo de barras translúcido para efecto glass
    // Se usa un color semi-transparente. El efecto blur se aplicará directamente en los widgets de barra si es posible.
    barBackgroundColor: glassBarBackgroundColor,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(
        color: darkTextColor,
        fontFamily: appFontFamily,
        fontSize: 17, // Tamaño base
      ),
      actionTextStyle: TextStyle(
        color: primaryAppColor,
        fontFamily: appFontFamily,
        fontSize: 17,
      ),
      navTitleTextStyle: TextStyle(
        color: darkTextColor,
        fontFamily: appFontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 17,
      ),
      navLargeTitleTextStyle: TextStyle(
        color: darkTextColor,
        fontFamily: appFontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 34,
      ),
      pickerTextStyle: TextStyle(
        color: darkTextColor,
        fontFamily: appFontFamily,
        fontSize: 21,
      ),
      dateTimePickerTextStyle: TextStyle(
        color: darkTextColor,
        fontFamily: appFontFamily,
        fontSize: 21,
      ),
    ),
  );

  // Estilos de texto adicionales para consistencia
  static const TextStyle headlineStyle = TextStyle(
    color: darkTextColor,
    fontFamily: appFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    color: darkTextColor,
    fontFamily: appFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle captionTextStyle = TextStyle(
    color: Colors.black54, // Un gris para textos secundarios
    fontFamily: appFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  // Gradientes suaves
  static LinearGradient primaryGradient = LinearGradient(
    colors: [electricBlue, neonPurple.withOpacity(0.8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient secondaryGradient = LinearGradient(
    colors: [cyberOrange, electricBlue.withOpacity(0.7)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
}
