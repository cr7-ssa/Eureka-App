import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'alumnos_screen.dart';
import 'conceptos_screen.dart';
import 'cargos_screen.dart';
import 'login_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;
  final _pantallas = const [AlumnosScreen(), ConceptosScreen(), CargosScreen()];

  Future<void> _cerrarSesion(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: _pantallas[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people), label: 'Alumnos'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Conceptos'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Cargos'),
        ],
      ),
    );
  }
}