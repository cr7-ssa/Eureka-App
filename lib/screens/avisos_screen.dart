import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AvisosScreen extends StatefulWidget {
  const AvisosScreen({super.key});

  @override
  State<AvisosScreen> createState() => _AvisosScreenState();
}

class _AvisosScreenState extends State<AvisosScreen> {
  final _formKey = GlobalKey<FormState>();
  final tituloController = TextEditingController();
  final mensajeController = TextEditingController();
  String? gradoSeleccionado; // null significa "Todos"
  String? grupoSeleccionado;
  bool cargando = false;

  final grados = ['1ro', '2do', '3ro', '4to', '5to', '6to'];
  final grupos = ['A', 'B'];

  Future<void> _crearAviso() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => cargando = true);

    try {
      await FirebaseFirestore.instance.collection('avisos').add({
        'titulo': tituloController.text.trim(),
        'mensaje': mensajeController.text.trim(),
        'grado': gradoSeleccionado, 
        'grupo': grupoSeleccionado,
        'fecha': FieldValue.serverTimestamp(),
        'autor': 'Administrador',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Aviso publicado'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Muro de Avisos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () => _mostrarFormularioAviso(),
                icon: const Icon(Icons.add_alert),
                label: const Text('Crear Nuevo Aviso'),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('avisos').orderBy('fecha', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final avisos = snapshot.data!.docs;

                if (avisos.isEmpty) return const Center(child: Text('No hay avisos publicados.'));

                return ListView.builder(
                  itemCount: avisos.length,
                  itemBuilder: (context, i) {
                    final data = avisos[i].data() as Map<String, dynamic>;
                    final fecha = (data['fecha'] as Timestamp?)?.toDate();
                    final grado = data['grado'];
                    final grupo = data['grupo'];
                    
                    String dirigidoA = 'Toda la escuela';
                    if (grado != null) dirigidoA = '$grado "${grupo ?? ''}"';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.campaign, color: Color(0xFF1E6F5C), size: 32),
                        title: Text(data['titulo'] ?? 'Sin título', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['mensaje'] ?? ''),
                            const SizedBox(height: 8),
                            Text('Para: $dirigidoA | ${fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : ''}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
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

  void _mostrarFormularioAviso() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Nuevo Aviso', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextFormField(
                  controller: tituloController,
                  decoration: const InputDecoration(labelText: 'Título del aviso'),
                  validator: (v) => v!.isEmpty ? 'Escribe un título' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: mensajeController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Mensaje'),
                  validator: (v) => v!.isEmpty ? 'Escribe el mensaje' : null,
                ),
                const SizedBox(height: 16),
                const Text('Dirigido a:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: gradoSeleccionado,
                        hint: const Text('Todos los grados'),
                        items: grados.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v) => setState(() => gradoSeleccionado = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: grupoSeleccionado,
                        hint: const Text('Todos'),
                        items: grupos.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v) => setState(() => grupoSeleccionado = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: cargando ? null : _crearAviso,
                    child: cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Publicar Aviso'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}