import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClienteEstadoCuenta extends StatelessWidget {
  const ClienteEstadoCuenta({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Estado de Cuenta')),
      body: FutureBuilder<DocumentSnapshot>(
        // 1. Buscamos el perfil del usuario para saber qué alumno es
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          final studentId = userData?['studentId'];

          if (studentId == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Tu cuenta aún no está vinculada a un alumno. Contacta al administrador.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // 2. Si tiene alumno, buscamos sus cargos
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('charges')
                .where('studentId', isEqualTo: studentId)
                .snapshots(),
            builder: (context, chargesSnapshot) {
              if (!chargesSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final cargos = chargesSnapshot.data!.docs;

              if (cargos.isEmpty) {
                return const Center(child: Text('No tienes cargos registrados.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cargos.length,
                itemBuilder: (context, i) {
                  final data = cargos[i].data() as Map<String, dynamic>;
                  final esPagado = data['status'] == 'pagado';
                  final fecha = (data['fechaVencimiento'] as Timestamp?)?.toDate();

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        esPagado ? Icons.check_circle : Icons.pending_actions,
                        color: esPagado ? Colors.green : Colors.orange,
                        size: 32,
                      ),
                      title: Text(data['conceptoNombre'] ?? 'Cargo'),
                      subtitle: Text(
                        'Vence: ${fecha != null ? "${fecha.day}/${fecha.month}/${fecha.year}" : "Sin fecha"}\n'
                        'Monto: \$${data['monto'] ?? 0}',
                      ),
                      isThreeLine: true,
                      trailing: Chip(
                        label: Text(esPagado ? 'Pagado' : 'Pendiente'),
                        backgroundColor: esPagado ? Colors.green.shade100 : Colors.orange.shade100,
                        side: BorderSide.none,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}