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

  Future<void> editar(String id, String nombreActual, double montoActual) async {
    nombre.text = nombreActual;
    monto.text = montoActual.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Concepto'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Obligatorio';
                  // VALIDACIÓN DE NOMBRE
                  if (!RegExp(r'^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(v)) return 'Solo letras y números';
                  return null;
                },
              ),
              TextFormField(
                controller: monto,
                decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                // VALIDACIÓN DE MONTO
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Obligatorio';
                  if (double.tryParse(v) == null) return 'Monto inválido';
                  if (double.parse(v) <= 0) return 'El monto debe ser mayor a 0';
                  if (double.parse(v) > 1000000) return 'Máximo \$1,000,000';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              await FirebaseFirestore.instance.collection('concepts').doc(id).update({
                'nombre': nombre.text.trim(),
                'monto': double.tryParse(monto.text) ?? 0,
              });
              nombre.clear();
              monto.clear();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> eliminar(String id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar concepto?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('concepts').doc(id).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'editar') editar(docs[i].id, nombreConcepto, montoSeguro);
                      if (value == 'eliminar') eliminar(docs[i].id);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'editar', child: Text('Editar')),
                      const PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          nombre.clear();
          monto.clear();
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
                        if (v == null || v.trim().isEmpty) return 'Obligatorio';
                        if (double.tryParse(v) == null) return 'Monto inválido';
                        if (double.parse(v) <= 0) return 'El monto debe ser mayor a 0';
                        if (double.parse(v) > 1000000) return 'Máximo \$1,000,000';
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