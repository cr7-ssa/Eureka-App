import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'alumno_detalle_screen.dart';

class CargosScreen extends StatefulWidget {
  const CargosScreen({super.key});

  @override
  State<CargosScreen> createState() => _CargosScreenState();
}

class _CargosScreenState extends State<CargosScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  // --- FUNCIÓN PARA MOSTRAR EL COBRO MASIVO ---
  void _mostrarCobroMasivo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _FormularioCobroMasivo(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen de Cargos')),
      body: Column(
        children: [
          // BOTÓN DE COBRO MASIVO
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _mostrarCobroMasivo,
                icon: const Icon(Icons.campaign),
                label: const Text('Cobro Masivo por Grupo'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E6F5C),
                ),
              ),
            ),
          ),
          const Divider(),
          
          // LISTA DE ALUMNOS CON ADEUDOS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('students').where('activo', isEqualTo: true).snapshots(),
              builder: (context, studentSnapshot) {
                if (!studentSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final alumnos = studentSnapshot.data!.docs;

                if (alumnos.isEmpty) return const Center(child: Text('No hay alumnos registrados.'));

                return ListView.builder(
                  itemCount: alumnos.length,
                  itemBuilder: (context, i) {
                    final alumnoData = alumnos[i].data() as Map<String, dynamic>;
                    final alumnoId = alumnos[i].id;
                    
                    final nombre = alumnoData['nombre'] ?? 'Sin nombre';
                    final apellidos = alumnoData['apellidos'] ?? '';
                    final grado = alumnoData['grado'] ?? '-';
                    final grupo = alumnoData['grupo'] ?? '-';

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('charges')
                          .where('studentId', isEqualTo: alumnoId)
                          .snapshots(),
                      builder: (context, chargeSnapshot) {
                        if (!chargeSnapshot.hasData) return const SizedBox();

                        final cargos = chargeSnapshot.data!.docs;
                        
                        if (cargos.isEmpty) return const SizedBox();

                        double totalPendiente = 0;
                        int cargosPendientes = 0;

                        for (var cargo in cargos) {
                          final data = cargo.data() as Map<String, dynamic>;
                          if (data['status'] != 'pagado') {
                            double monto = 0.0;
                            if (data['monto'] is num) monto = data['monto'].toDouble();
                            if (data['monto'] is String) monto = double.tryParse(data['monto']) ?? 0.0;
                            
                            totalPendiente += monto;
                            cargosPendientes++;
                          }
                        }

                        if (cargosPendientes == 0) return const SizedBox();

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.shade100,
                              child: const Icon(Icons.warning, color: Colors.red),
                            ),
                            title: Text('$nombre $apellidos', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text('$grado "$grupo"\nTiene $cargosPendientes cargo(s) pendiente(s)', style: const TextStyle(height: 1.5)),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Debe:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  currencyFormat.format(totalPendiente),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (_) => AlumnoDetalleScreen(alumnoId: alumnoId))
                              );
                            },
                          ),
                        );
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
  }
}

// --- FORMULARIO DE COBRO MASIVO ---
class _FormularioCobroMasivo extends StatefulWidget {
  const _FormularioCobroMasivo();

  @override
  State<_FormularioCobroMasivo> createState() => _FormularioCobroMasivoState();
}

class _FormularioCobroMasivoState extends State<_FormularioCobroMasivo> {
  String? gradoSeleccionado;
  String? grupoSeleccionado;
  String? conceptoId;
  String? conceptoNombre;
  double monto = 0;
  DateTime fechaVencimiento = DateTime.now();
  bool cargando = false;
  String mensaje = '';

  final grados = ['1ro', '2do', '3ro', '4to', '5to', '6to'];
  final grupos = ['A', 'B'];

  Future<void> _generarCobros() async {
    if (gradoSeleccionado == null || grupoSeleccionado == null || conceptoId == null) {
      setState(() => mensaje = '❌ Selecciona grado, grupo y concepto.');
      return;
    }

    setState(() {
      cargando = true;
      mensaje = 'Buscando alumnos...';
    });

    try {
      final alumnos = await FirebaseFirestore.instance
          .collection('students')
          .where('grado', isEqualTo: gradoSeleccionado)
          .where('grupo', isEqualTo: grupoSeleccionado)
          .where('activo', isEqualTo: true)
          .get();

      if (alumnos.docs.isEmpty) {
        setState(() { mensaje = 'No hay alumnos en este grupo.'; cargando = false; });
        return;
      }

      setState(() => mensaje = 'Generando ${alumnos.docs.length} cargos...');

      final periodo = DateFormat('yyyy-MM').format(fechaVencimiento);
      final batch = FirebaseFirestore.instance.batch();

      for (var alumno in alumnos.docs) {
        final docId = '${alumno.id}_${conceptoId}_$periodo';
        final cargoRef = FirebaseFirestore.instance.collection('charges').doc(docId);

        batch.set(cargoRef, {
          'studentId': alumno.id,
          'conceptId': conceptoId,
          'conceptoNombre': conceptoNombre,
          'monto': monto,
          'fechaVencimiento': Timestamp.fromDate(fechaVencimiento),
          'status': 'pendiente',
          'periodo': periodo,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      setState(() {
        mensaje = '✅ ¡Éxito! Se generaron ${alumnos.docs.length} cargos.';
        cargando = false;
      });

    } catch (e) {
      setState(() { mensaje = 'Error: $e'; cargando = false; });
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Cobro Masivo por Grupo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Selecciona el salón y el concepto para generar los cargos de todos los alumnos de golpe.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Grado'),
                  items: grados.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => gradoSeleccionado = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Grupo'),
                  items: grupos.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => grupoSeleccionado = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          InkWell(
            onTap: _seleccionarConcepto,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Concepto', suffixIcon: Icon(Icons.search)),
              child: Text(conceptoNombre ?? 'Buscar concepto...', style: TextStyle(color: conceptoNombre == null ? Colors.grey : Colors.black)),
            ),
          ),
          const SizedBox(height: 16),

          ListTile(
            shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
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
          
          if (mensaje.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],

          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: cargando ? null : _generarCobros,
              child: cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Generar Cobros'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// --- REUTILIZAMOS EL BUSCADOR DE CONCEPTOS ---
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const Text('Selecciona un Concepto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
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
                        final nombre = data['nombre'] ?? 'Sin nombre';
                        final monto = (data['monto'] ?? 0).toDouble();

                        return ListTile(
                          title: Text(nombre),
                          trailing: Text('\$$monto', style: const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () {
                            widget.onSelected(conceptos[i].id, nombre, monto);
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