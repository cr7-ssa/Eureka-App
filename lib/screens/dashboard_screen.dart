import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onIrAAlumnos; // <-- NUEVA FUNCIÓN PARA CAMBIAR DE PESTAÑA

  const DashboardScreen({super.key, required this.onIrAAlumnos});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalAlumnos = 0;
  double totalCobradoMes = 0;
  double totalPendiente = 0;
  bool cargando = true;

  final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  @override
  void initState() {
    super.initState();
    _cargarMetricas();
  }

  Future<void> _cargarMetricas() async {
    try {
      final alumnos = await FirebaseFirestore.instance.collection('students').where('activo', isEqualTo: true).get();
      final cargos = await FirebaseFirestore.instance.collection('charges').get();
      
      double cobrado = 0;
      double pendiente = 0;

      for (var doc in cargos.docs) {
        final data = doc.data();
        double monto = 0;
        if (data['monto'] is num) monto = data['monto'].toDouble();

        if (data['status'] == 'pagado') {
          cobrado += monto;
        } else {
          pendiente += monto;
        }
      }

      setState(() {
        totalAlumnos = alumnos.docs.length;
        totalCobradoMes = cobrado;
        totalPendiente = pendiente;
        cargando = false;
      });
    } catch (e) {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _cargarMetricas,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen General',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E6F5C)),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _tarjetaMetrica(
                    titulo: 'Alumnos Activos',
                    valor: totalAlumnos.toString(),
                    icono: Icons.people,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _tarjetaMetrica(
                    titulo: 'Total Cobrado',
                    valor: currencyFormat.format(totalCobradoMes),
                    icono: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _tarjetaMetrica(
                    titulo: 'Por Cobrar',
                    valor: currencyFormat.format(totalPendiente),
                    icono: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Text(
              'Accesos Rápidos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // BOTÓN DE GESTIÓN ESCOLAR CORREGIDO
            Card(
              child: ListTile(
                leading: const Icon(Icons.school, color: Color(0xFF1E6F5C)),
                title: const Text('Gestión Escolar'),
                subtitle: const Text('Ir a la lista de alumnos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onIrAAlumnos, // <-- AQUÍ SE EJECUTA LA ACCIÓN
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaMetrica({required String titulo, required String valor, required IconData icono, required Color color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color, size: 30),
            const SizedBox(height: 12),
            Text(titulo, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}