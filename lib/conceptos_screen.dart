import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ConceptosScreen extends StatefulWidget {
  const ConceptosScreen({super.key});

  @override
  State<ConceptosScreen> createState() => _ConceptosScreenState();
}

class _ConceptosScreenState extends State<ConceptosScreen> {
  final nombre = TextEditingController();
  final monto = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  Future<void> agregar() async {
    if (nombre.text.isEmpty || monto.text.isEmpty) return;

    final existe = await FirebaseFirestore.instance
        .collection('concepts').where('nombre', isEqualTo: nombre.text.trim()).get();

    if (existe.docs.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(' Ya existe un concepto con ese nombre'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    await FirebaseFirestore.instance.collection('concepts').add({
      'nombre': nombre.text.trim(),
      'monto': double.tryParse(monto.text) ?? 0,
      'activo': true,
    });
    
    nombre.clear();
    monto.clear();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de Conceptos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('concepts').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          
          if (docs.isEmpty) return const Center(child: Text('No hay conceptos registrados'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              
              // PROTECCIÓN CONTRA NULLS Y TEXTOS RAROS
              final nombreConcepto = d['nombre'] ?? 'Sin nombre';
              double montoSeguro = 0.0;
              if (d['monto'] != null) {
                if (d['monto'] is num) {
                  montoSeguro = d['monto'].toDouble();
                } else if (d['monto'] is String) {
                  montoSeguro = double.tryParse(d['monto']) ?? 0.0;
                }
              }
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.receipt, color: Color(0xFF1E6F5C)),
                  title: Text(nombreConcepto, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Monto: ${currencyFormat.format(montoSeguro)}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Nuevo Concepto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre del concepto')),
                  TextField(controller: monto, decoration: const InputDecoration(labelText: 'Monto (solo números)', prefixText: '\$ '), keyboardType: TextInputType.number),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                TextButton(onPressed: agregar, child: const Text('Guardar')),
              ],
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Concepto'),
      ),
    );
  }
}