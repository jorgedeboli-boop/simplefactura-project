import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tema visual de Simple Factura.
/// Color de marca: #398bf7
class AppTheme {
  static const Color colorPrimario = Color(0xFF398BF7);
  static const Color colorNavBar = Color(0xFF2196F3);
  static const Color colorPanel = Color(0xFF3F4154);
  static const Color colorFondo = Color(0xFFF5F7FA);
  static const Color colorTexto = Color(0xFF1C2733);
  static const Color colorError = Color(0xFFD64545);
  static const Color colorExito = Color(0xFF2E9E5B);

  static const TextStyle textoDrawer = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    fontSize: 15,
    color: Colors.white,
  );

  static const TextStyle textoBotonAccion = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  static const TextStyle textoDropdown = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16,
    color: colorTexto,
  );

  static final TextStyle textoDrawerSecundario = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    fontSize: 13,
    color: Colors.white.withValues(alpha: 0.8),
  );

  static ThemeData get temaClaro {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colorPrimario,
      primary: colorPrimario,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorFondo,
      appBarTheme: const AppBarTheme(
        backgroundColor: colorNavBar,
        foregroundColor: Colors.white,
        elevation: 2,
        toolbarHeight: 56,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: colorNavBar,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimario,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: textoBotonAccion,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorNavBar,
          foregroundColor: Colors.white,
          textStyle: textoBotonAccion,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: colorPrimario, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE7EBF0)),
        ),
      ),
      fontFamily: 'Roboto',
    );
  }
}
