import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'alumno_detalle_screen.dart';

class AlumnoFormScreen extends StatefulWidget {
  final String? id;
  const AlumnoFormScreen({super.key, this.id});

  @override
  State<AlumnoFormScreen> createState() => _AlumnoFormScreenState();
}

class _AlumnoFormScreenState extends State<AlumnoFormScreen> {
  final nombre = TextEditingController();
  final apellidos = TextEditingController();
  final matricula = TextEditingController();
  
  String? gradoSeleccionado;
  String? grupoSeleccionado;
  bool cargando = false;

  final List<String> grados = ['1ro', '2do', '3ro', '4to', '5to', '6to'];
  final List<String> grupos = ['A', 'B'];

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      FirebaseFirestore.instance.collection('students').doc(widget.id).get().then((doc) {
        if (doc.exists) {
          final d = doc.data()!;
          setState(() {
            nombre.text = d['nombre'] ?? '';
            apellidos.text = d['apellidos'] ?? '';
            matricula.text = d['matricula'] ?? '';
            gradoSeleccionado = d['grado'];
            grupoSeleccionado = d['grupo'];
          });
        }
      });
    }
  }

  Future<void> guardar() async {
    if (nombre.text.isEmpty || matricula.text.isEmpty || gradoSeleccionado == null || grupoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor llena todos los campos')));
      return;
    }

    setState(() => cargando = true);
    String nuevoId = widget.id ?? '';

    final data = {
      'nombre': nombre.text.trim(),
      'apellidos': apellidos.text.trim(),
      'matricula': matricula.text.trim(),
      'grado': gradoSeleccionado,
      'grupo': grupoSeleccionado,
      'activo': true,
    };

    if (widget.id == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
      final ref = await FirebaseFirestore.instance.collection('students').add(data);
      nuevoId = ref.id;
    } else {
      await FirebaseFirestore.instance.collection('students').doc(widget.id).update(data);
    }

    if (!mounted) return;
    // En lugar de regresar, nos manda al detalle del alumno
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AlumnoDetalleScreen(alumnoId: nuevoId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.id == null ? 'Nuevo Alumno' : 'Editar Alumno')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre(s)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: apellidos, decoration: const InputDecoration(labelText: 'Apellidos', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: matricula, decoration: const InputDecoration(labelText: 'Matrícula', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: gradoSeleccionado,
                    decoration: const InputDecoration(labelText: 'Grado', border: OutlineInputBorder()),
                    items: grados.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (v) => setState(() => gradoSeleccionado = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: grupoSeleccionado,
                    decoration: const InputDecoration(labelText: 'Grupo', border: OutlineInputBorder()),
                    items: grupos.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (v) => setState(() => grupoSeleccionado = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: cargando ? null : guardar,
                child: cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar y ver Estado de Cuenta'),
              ),
            )
          ],
        ),
      ),
    );
  }
}