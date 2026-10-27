import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ConceptosScreen extends StatefulWidget {
  const ConceptosScreen({super.key});

  @override
  State<ConceptosScreen> createState() => _ConceptosScreenState();
}

class _ConceptosScreenState extends State<ConceptosScreen> {
  final _formKey = GlobalKey<FormState>();
  final nombre = TextEditingController();
  final monto = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  Future<void> agregar() async {
    if (!_formKey.currentState!.validate()) return;

    final existe = await FirebaseFirestore.instance.collection('concepts').where('nombre', isEqualTo: nombre.text.trim()).get();

    if (existe.docs.isNotEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Ya existe un concepto con ese nombre'), backgroundColor: Colors.red));
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
              final nombreConcepto = d['nombre'] ?? 'Sin nombre';
              double montoSeguro = 0.0;
              if (d['monto'] is num) montoSeguro = d['monto'].toDouble();
              if (d['monto'] is String) montoSeguro = double.tryParse(d['monto']) ?? 0.0;
              
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
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nombre, 
                      decoration: const InputDecoration(labelText: 'Nombre del concepto'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Obligatorio';
                        if (!RegExp(r'^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(v)) return 'Solo letras y números';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: monto, 
                      decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ '), 
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obligatorio';
                        if (double.tryParse(v) == null) return 'Monto inválido';
                        return null;
                      },
                    ),
                  ],
                ),
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