import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'alumno_form_screen.dart';

class AlumnoDetalleScreen extends StatefulWidget {
  final String alumnoId;
  const AlumnoDetalleScreen({super.key, required this.alumnoId});

  @override
  State<AlumnoDetalleScreen> createState() => _AlumnoDetalleScreenState();
}

class _AlumnoDetalleScreenState extends State<AlumnoDetalleScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  Map<String, dynamic>? alumnoData;
  bool creandoCuenta = false;

  @override
  void initState() {
    super.initState();
    _cargarAlumno();
  }

  Future<void> _cargarAlumno() async {
    final doc = await FirebaseFirestore.instance.collection('students').doc(widget.alumnoId).get();
    if (doc.exists && mounted) {
      setState(() {
        alumnoData = doc.data();
      });
    }
  }

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

  void _mostrarDialogoNota() {
    final notaController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Observación'),
        content: TextField(
          controller: notaController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Escribe una nota (ej. Prórroga, conducta)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (notaController.text.trim().isEmpty) return;
              await FirebaseFirestore.instance.collection('notes').add({
                'studentId': widget.alumnoId,
                'texto': notaController.text.trim(),
                'fecha': FieldValue.serverTimestamp(),
                'autor': FirebaseAuth.instance.currentUser!.email,
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _crearCuentaCliente() async {
    final email = alumnoData!['tutorEmail']?.toString().trim() ?? '';
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Primero edita al alumno y agrégale un correo'), backgroundColor: Colors.red));
      return;
    }

    setState(() => creandoCuenta = true);
    const passwordDefault = '123456';

    try {
      FirebaseApp app = await Firebase.initializeApp(name: 'App_${widget.alumnoId}', options: Firebase.app().options);
      UserCredential cred = await FirebaseAuth.instanceFor(app: app).createUserWithEmailAndPassword(email: email, password: passwordDefault);

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'nombre': '${alumnoData!['nombre']} ${alumnoData!['apellidos']}',
        'email': email,
        'role': 'cliente',
        'studentId': widget.alumnoId,
        'activo': true,
      });

      await app.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Cuenta creada.\nCorreo: $email\nContraseña: $passwordDefault'), backgroundColor: Colors.green, duration: const Duration(seconds: 5)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => creandoCuenta = false);
    }
  }

  Future<void> _marcarComoPagado(String chargeId) async {
    try {
      await FirebaseFirestore.instance.collection('charges').doc(chargeId).update({
        'status': 'pagado',
        'marcadoPagadoPor': FirebaseAuth.instance.currentUser!.uid,
        'marcadoPagadoEn': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Cargo marcado como pagado'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _revertirAPendiente(String chargeId) async {
    try {
      await FirebaseFirestore.instance.collection('charges').doc(chargeId).update({
        'status': 'pendiente',
        'marcadoPagadoPor': null,
        'marcadoPagadoEn': null,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔄 Cargo revertido a Pendiente'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (alumnoData == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final nombre = alumnoData!['nombre'] ?? 'Sin nombre';
    final apellidos = alumnoData!['apellidos'] ?? '';
    final matricula = alumnoData!['matricula'] ?? 'Sin matrícula';
    final grado = alumnoData!['grado'] ?? '-';
    final grupo = alumnoData!['grupo'] ?? '-';
    final correo = alumnoData!['tutorEmail']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Expediente del Alumno')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('$nombre $apellidos', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Matrícula: $matricula | $grado "$grupo"'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AlumnoFormScreen(id: widget.alumnoId))).then((_) => _cargarAlumno());
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _mostrarDialogoCargo,
                        icon: const Icon(Icons.add_card),
                        label: const Text('Cargo'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E6F5C), foregroundColor: Colors.white),
                      ),
                      ElevatedButton.icon(
                        onPressed: _mostrarDialogoNota,
                        icon: const Icon(Icons.note_add),
                        label: const Text('Nota'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  if (correo.isEmpty)
                    const Text('⚠️ Sin correo registrado. Edita al alumno para agregarlo.', style: TextStyle(color: Colors.orange, fontSize: 13))
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: creandoCuenta ? null : _crearCuentaCliente,
                        icon: creandoCuenta ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.person_add),
                        label: Text(creandoCuenta ? 'Creando...' : 'Crear Acceso con: $correo'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Observaciones Recientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade700)),
            ),
          ),
          SizedBox(
            height: 80,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('notes').where('studentId', isEqualTo: widget.alumnoId).orderBy('fecha', descending: true).limit(3).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final notas = snapshot.data!.docs;
                if (notas.isEmpty) return const Center(child: Text('Sin observaciones', style: TextStyle(color: Colors.grey, fontSize: 12)));

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notas.length,
                  itemBuilder: (context, i) {
                    final data = notas[i].data() as Map<String, dynamic>;
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 8, bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.yellow.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.yellow.shade200)),
                      child: Text(data['texto'] ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(),
          
          const Text('Historial de Cargos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('charges').where('studentId', isEqualTo: widget.alumnoId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final cargos = snapshot.data!.docs;
                
                if (cargos.isEmpty) return const Center(child: Text('No hay cargos registrados.'));

                return ListView.builder(
                  itemCount: cargos.length,
                  itemBuilder: (context, i) {
                    final d = cargos[i].data() as Map<String, dynamic>;
                    final nombreConcepto = d['conceptoNombre'] ?? 'Cargo';
                    final pagado = d['status'] == 'pagado';
                    
                    double montoSeguro = 0.0;
                    if (d['monto'] != null) {
                      if (d['monto'] is num) montoSeguro = d['monto'].toDouble();
                      if (d['monto'] is String) montoSeguro = double.tryParse(d['monto']) ?? 0.0;
                    }
                    final fecha = (d['fechaVencimiento'] as Timestamp?)?.toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(pagado ? Icons.check_circle : Icons.warning, color: pagado ? Colors.green : Colors.orange),
                        title: Text(nombreConcepto, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Vence: ${fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : "Sin fecha"}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(currencyFormat.format(montoSeguro), style: TextStyle(fontWeight: FontWeight.bold, color: pagado ? Colors.grey : Colors.red)),
                            const SizedBox(width: 8),
                            if (!pagado)
                              IconButton(icon: const Icon(Icons.payments, color: Colors.green), tooltip: 'Registrar Pago', onPressed: () => _marcarComoPagado(cargos[i].id))
                            else
                              IconButton(icon: const Icon(Icons.undo, color: Colors.red), tooltip: 'Revertir a Pendiente', onPressed: () => _revertirAPendiente(cargos[i].id)),
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
    if (conceptoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor selecciona un concepto')));
      return;
    }
    setState(() => cargando = true);

    try {
      final periodo = DateFormat('yyyy-MM').format(fechaVencimiento);
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

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  void _seleccionarConcepto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _BuscadorConceptos(
          onSelected: (id, nombre, montoSel) {
            setState(() {
              conceptoId = id;
              conceptoNombre = nombre;
              monto = montoSel;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Asignar Nuevo Cargo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          InkWell(
            onTap: _seleccionarConcepto,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Concepto', border: OutlineInputBorder(), suffixIcon: Icon(Icons.search)),
              child: Text(conceptoNombre ?? 'Toca aquí para buscar un concepto', style: TextStyle(color: conceptoNombre == null ? Colors.grey : Colors.black)),
            ),
          ),
          const SizedBox(height: 16),
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

// --- PANTALLA DEL BUSCADOR DE CONCEPTOS ---
class _BuscadorConceptos extends StatefulWidget {
  final Function(String id, String nombre, double monto) onSelected;
  const _BuscadorConceptos({required this.onSelected});

  @override
  State<_BuscadorConceptos> createState() => _BuscadorConceptosState();
}

class _BuscadorConceptosState extends State<_BuscadorConceptos> {
  String busqueda = '';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              const Text('Selecciona un Concepto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(hintText: 'Buscar...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                onChanged: (v) => setState(() => busqueda = v.toLowerCase()),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('concepts').where('activo', isEqualTo: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final conceptos = snapshot.data!.docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final nombre = (data['nombre'] ?? '').toString().toLowerCase();
                      return nombre.contains(busqueda);
                    }).toList();

                    if (conceptos.isEmpty) return const Center(child: Text('No se encontraron conceptos'));

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: conceptos.length,
                      itemBuilder: (context, i) {
                        final data = conceptos[i].data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['nombre'] ?? 'Sin nombre'),
                          trailing: Text('\$${data['monto'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () {
                            widget.onSelected(conceptos[i].id, data['nombre'], (data['monto'] ?? 0).toDouble());
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}