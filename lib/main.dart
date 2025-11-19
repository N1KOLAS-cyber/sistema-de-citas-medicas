// MAIN.DART - PUNTO DE ENTRADA PRINCIPAL DE LA APLICACIÓN
//
// Este archivo es el punto de entrada principal de la aplicación Flutter.
// Configura Firebase, inicializa la aplicación y define el tema global.
//
// FUNCIONALIDADES:
// - Inicialización de Firebase
// - Creación automática del usuario administrador
// - Configuración del tema de la aplicación
// - Definición de la página de inicio (SimpleLoginPage)
//
// ESTRUCTURA:
// - main(): Función principal que inicializa la app
// - MyApp: Widget raíz con configuración de tema
// - Configuración de colores y estilos globales
//
// VISUALIZACIÓN: Aplicación con tema médico azul, navegación
// intuitiva y diseño moderno.

import 'package:flutter/material.dart';
import 'tabs/simple_login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/admin_service.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Función principal de la aplicación.
/// Inicializa Firebase y crea el usuario administrador por defecto.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es');
  
  // Crear usuario administrador si no existe
  await AdminService.createAdminUser();
  
  runApp(const MyApp());
}

/// Widget raíz de la aplicación.
/// Configura el tema global y define la página de inicio.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Construye la aplicación con configuración de tema médico.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'MedCitas - Sistema de Citas Médicas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1976D2), // Azul médico
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 4,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF1976D2),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const SimpleLoginPage(),
    );
  }
}
