import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'conceptos_screen.dart'; // Para poder ir a crear un concepto si no hay

class CargosScreen extends StatefulWidget {
  const CargosScreen({super.key});

  @override
  State<CargosScreen> createState() => _CargosScreenState();
}

class _CargosScreenState extends State<CargosScreen> {
  String busqueda = '';
  final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de Cargos')),
      body: Column(
        children: [
          // Buscador de conceptos
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar concepto (ej. Colegiatura)...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => busqueda = v.toLowerCase().trim()),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Traemos la lista de CONCEPTOS, no de cargos de alumnos
              stream: FirebaseFirestore.instance.collection('concepts').where('activo', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final conceptos = snapshot.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final nombre = (data['nombre'] ?? '').toString().toLowerCase();
                  return nombre.contains(busqueda);
                }).toList();

                if (conceptos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No hay conceptos registrados.'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConceptosScreen())),
                          child: const Text('Ir a crear uno'),
                        )
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: conceptos.length,
                  itemBuilder: (context, i) {
                    final data = conceptos[i].data() as Map<String, dynamic>;
                    final nombre = data['nombre'] ?? 'Sin nombre';
                    
                    double montoSeguro = 0.0;
                    if (data['monto'] is num) montoSeguro = data['monto'].toDouble();
                    if (data['monto'] is String) montoSeguro = double.tryParse(data['monto']) ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE0F2F1),
                          child: Icon(Icons.receipt_long, color: Color(0xFF1E6F5C)),
                        ),
                        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Concepto de cobro'),
                        trailing: Text(
                          currencyFormat.format(montoSeguro),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}