import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'alumno_form_screen.dart';

class AlumnoDetalleScreen extends StatefulWidget {
  final String alumnoId;
  const AlumnoDetalleScreen({super.key, required this.alumnoId});

  @override
  State<AlumnoDetalleScreen> createState() => _AlumnoDetalleScreenState();
}

class _AlumnoDetalleScreenState extends State<AlumnoDetalleScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  // Variable para guardar los datos del alumno
  Map<String, dynamic>? alumnoData;

  @override
  void initState() {
    super.initState();
    _cargarAlumno();
  }

  // Función para traer los datos del alumno desde Firebase
  Future<void> _cargarAlumno() async {
    final doc = await FirebaseFirestore.instance.collection('students').doc(widget.alumnoId).get();
    if (doc.exists && mounted) {
      setState(() {
        alumnoData = doc.data();
      });
    }
  }

  // Ventana para asignar un cargo
  void _mostrarDialogoCargo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _FormularioCargo(alumnoId: widget.alumnoId),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (alumnoData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Estado de Cuenta')),
      body: Column(
        children: [
          // Tarjeta con datos del alumno
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('${alumnoData!['nombre']} ${alumnoData!['apellidos']}', 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Matrícula: ${alumnoData!['matricula']} | ${alumnoData!['grado']} "${alumnoData!['grupo']}"'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AlumnoFormScreen(id: widget.alumnoId)))
                              .then((_) => _cargarAlumno()); // Recarga al volver
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _mostrarDialogoCargo,
                        icon: const Icon(Icons.add_card),
                        label: const Text('Asignar Cargo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E6F5C), 
                          foregroundColor: Colors.white
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          
          const Divider(),
          const Text('Historial de Cargos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),

          // Lista de cargos en tiempo real
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('charges')
                  .where('studentId', isEqualTo: widget.alumnoId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final cargos = snapshot.data!.docs;
                
                if (cargos.isEmpty) return const Center(child: Text('No hay cargos registrados.'));

                return ListView.builder(
                  itemCount: cargos.length,
                  itemBuilder: (context, i) {
                    final d = cargos[i].data() as Map<String, dynamic>;
                    final pagado = d['status'] == 'pagado';
                    final fecha = (d['fechaVencimiento'] as Timestamp?)?.toDate();

                    return ListTile(
                      leading: Icon(pagado ? Icons.check_circle : Icons.warning, 
                          color: pagado ? Colors.green : Colors.orange),
                      title: Text(d['conceptoNombre'] ?? 'Cargo'),
                      subtitle: Text('Vence: ${fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : "-"}'),
                      trailing: Text(
                        currencyFormat.format(d['monto'] ?? 0),
                        style: TextStyle(fontWeight: FontWeight.bold, color: pagado ? Colors.grey : Colors.red),
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

// --- FORMULARIO PARA ASIGNAR CARGO ---
class _FormularioCargo extends StatefulWidget {
  final String alumnoId;
  const _FormularioCargo({required this.alumnoId});

  @override
  State<_FormularioCargo> createState() => _FormularioCargoState();
}

class _FormularioCargoState extends State<_FormularioCargo> {
  String? conceptoId;
  String? conceptoNombre;
  double monto = 0;
  DateTime fechaVencimiento = DateTime.now();
  bool cargando = false;

  Future<void> _guardarCargo() async {
    if (conceptoId == null) return;
    setState(() => cargando = true);

    try {
      final periodo = DateFormat('yyyy-MM').format(fechaVencimiento);
      // ID único para evitar que se duplique el mismo cargo en el mismo mes
      final docId = '${widget.alumnoId}_${conceptoId}_$periodo';

      await FirebaseFirestore.instance.collection('charges').doc(docId).set({
        'studentId': widget.alumnoId,
        'conceptId': conceptoId,
        'conceptoNombre': conceptoNombre,
        'monto': monto,
        'fechaVencimiento': Timestamp.fromDate(fechaVencimiento),
        'status': 'pendiente',
        'periodo': periodo,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context); // Cierra la ventanita
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Asignar Nuevo Cargo', 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), 
            textAlign: TextAlign.center),
          const SizedBox(height: 16),
          
          // Selector de Concepto
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('concepts').where('activo', isEqualTo: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final conceptos = snapshot.data!.docs;
              
              if (conceptos.isEmpty) return const Text('Primero crea un concepto en la pestaña "Conceptos"');

              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Selecciona el concepto', border: OutlineInputBorder()),
                items: conceptos.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text('${data['nombre']} (\$${data['monto']})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    final doc = conceptos.firstWhere((c) => c.id == val);
                    final data = doc.data() as Map<String, dynamic>;
                    setState(() {
                      conceptoId = doc.id;
                      conceptoNombre = data['nombre'];
                      monto = (data['monto'] ?? 0).toDouble();
                    });
                  }
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Selector de Fecha
          ListTile(
            shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
            title: const Text('Fecha de Vencimiento'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(fechaVencimiento)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: fechaVencimiento,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => fechaVencimiento = picked);
            },
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: cargando ? null : _guardarCargo,
              child: cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar Cargo'),
            ),
          ),
        ],
      ),
    );
  }
}