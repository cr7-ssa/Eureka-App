import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ClienteEstadoCuenta extends StatelessWidget {
  const ClienteEstadoCuenta({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Estado de Cuenta')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text('No se encontró tu perfil.'));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final studentId = userData['studentId'];

          if (studentId == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Tu cuenta aún no está vinculada a un alumno. Contacta a la escuela.', textAlign: TextAlign.center),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('charges').where('studentId', isEqualTo: studentId).snapshots(),
            builder: (context, chargesSnapshot) {
              if (!chargesSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              final cargos = chargesSnapshot.data!.docs;

              if (cargos.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                      SizedBox(height: 16),
                      Text('¡Todo al día! No tienes cargos pendientes.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }

              double totalPendiente = 0;
              double totalPagado = 0;

              for (var doc in cargos) {
                final data = doc.data() as Map<String, dynamic>;
                double monto = 0.0;
                if (data['monto'] is num) monto = data['monto'].toDouble();

                if (data['status'] == 'pagado') {
                  totalPagado += monto;
                } else {
                  totalPendiente += monto;
                }
              }

              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E6F5C),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('Saldo Total Pendiente', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(totalPendiente),
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text('Pagado', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text(currencyFormat.format(totalPagado), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Container(width: 1, height: 30, color: Colors.white30),
                            Column(
                              children: [
                                const Text('Cargos', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('${cargos.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Detalle de Cargos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: cargos.length,
                      itemBuilder: (context, i) {
                        final data = cargos[i].data() as Map<String, dynamic>;
                        final esPagado = data['status'] == 'pagado';
                        final fecha = (data['fechaVencimiento'] as Timestamp?)?.toDate();
                        
                        double monto = 0.0;
                        if (data['monto'] is num) monto = data['monto'].toDouble();

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                            leading: Icon(
                              esPagado ? Icons.check_circle : Icons.pending_actions,
                              color: esPagado ? Colors.green : Colors.orange,
                              size: 32,
                            ),
                            title: Text(data['conceptoNombre'] ?? 'Cargo', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Vence: ${fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : "-"}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(currencyFormat.format(monto), style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(esPagado ? 'Pagado' : 'Pendiente', style: TextStyle(color: esPagado ? Colors.green : Colors.red, fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}