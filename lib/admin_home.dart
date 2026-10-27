import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'screens/alumnos_screen.dart';
import 'screens/conceptos_screen.dart';
import 'screens/cargos_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/usuarios_screen.dart';
import 'screens/avisos_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;

  // Lista de pantallas para la navegación
  late final List<Widget> _pantallas = [
    DashboardScreen(onIrAAlumnos: () => setState(() => _index = 1)),
    const AlumnosScreen(),
    const ConceptosScreen(),
    const CargosScreen(),
    const AvisosScreen(),
  ];

  Future<void> _cerrarSesion(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (_) => const LoginScreen()), 
      (route) => false
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EUREKA Admin'),
        actions: [
          // Botón para ver los papás registrados y vincularlos
          IconButton(
            icon: const Icon(Icons.manage_accounts),
            tooltip: 'Usuarios Registrados',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsuariosScreen())),
          ),
          // Botón para cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: _pantallas[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Alumnos'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Conceptos'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Cargos'),
          NavigationDestination(icon: Icon(Icons.campaign), label: 'Avisos'),
        ],
      ),
    );
  }
}