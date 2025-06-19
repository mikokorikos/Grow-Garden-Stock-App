import 'package:flutter/cupertino.dart';

class AppTheme {
  static const Color primary = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF5F5F5);
  static const Color textColor = Color(0xFF212121);

  static const CupertinoThemeData cupertinoTheme = CupertinoThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    barBackgroundColor: Color.fromARGB(240, 250, 250, 250),
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(color: textColor, fontFamily: 'SF-Pro-Display'),
    ),
  );
}
