import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  void _vincularAlumno(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  const Text('Vincular a un Alumno', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('students').where('activo', isEqualTo: true).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final alumnos = snapshot.data!.docs;

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: alumnos.length,
                          itemBuilder: (context, i) {
                            final data = alumnos[i].data() as Map<String, dynamic>;
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.person, color: Color(0xFF1E6F5C))),
                                title: Text('${data['nombre']} ${data['apellidos']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${data['grado']} "${data['grupo']}"'),
                                onTap: () async {
                                  await FirebaseFirestore.instance.collection('users').doc(userId).update({
                                    'studentId': alumnos[i].id,
                                  });
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('✅ Alumno vinculado correctamente'), backgroundColor: Colors.green),
                                    );
                                  }
                                },
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios Registrados')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'cliente').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final usuarios = snapshot.data!.docs;

          if (usuarios.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay papás registrados.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: usuarios.length,
            itemBuilder: (context, i) {
              final data = usuarios[i].data() as Map<String, dynamic>;
              final userId = usuarios[i].id;
              final nombre = data['nombre'] ?? 'Sin nombre';
              final email = data['email'] ?? 'Sin correo';
              final studentId = data['studentId'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: studentId == null ? Colors.orange.shade100 : Colors.green.shade100,
                    child: Icon(studentId == null ? Icons.warning_amber : Icons.check_circle, color: studentId == null ? Colors.orange : Colors.green),
                  ),
                  title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(email),
                  trailing: studentId == null
                      ? ElevatedButton(
                          onPressed: () => _vincularAlumno(context, userId),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E6F5C), foregroundColor: Colors.white),
                          child: const Text('Vincular'),
                        )
                      : const Text('Vinculado', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}