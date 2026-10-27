import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart';
import 'cliente_estado_cuenta.dart'; // <-- RUTA CORREGIDA
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

class ClienteHome extends StatefulWidget {
  const ClienteHome({super.key});

  @override
  State<ClienteHome> createState() => _ClienteHomeState();
}

class _ClienteHomeState extends State<ClienteHome> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? alumnoData;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    
    if (userDoc.exists) {
      userData = userDoc.data();
      final studentId = userData?['studentId'];
      
      if (studentId != null) {
        final alumnoDoc = await FirebaseFirestore.instance.collection('students').doc(studentId).get();
        if (alumnoDoc.exists) {
          alumnoData = alumnoDoc.data();
        }
      }
    }
    
    if (mounted) setState(() => cargando = false);
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final nombreTutor = userData?['nombre'] ?? 'Tutor';
    final telefono = userData?['telefono'] ?? 'Sin registrar';
    final nombreAlumno = alumnoData != null ? '${alumnoData!['nombre']} ${alumnoData!['apellidos']}' : 'Alumno no vinculado';
    final grado = alumnoData?['grado'] ?? '-';
    final grupo = alumnoData?['grupo'] ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Espacio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, $nombreTutor', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E6F5C))),
            Text('Teléfono: $telefono', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFFE0F2F1),
                      child: Icon(Icons.school, size: 35, color: Color(0xFF1E6F5C)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estudiante:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(nombreAlumno, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('$grado "$grupo"', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Text('Acciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: Color(0xFF1E6F5C), size: 30),
                title: const Text('Estado de Cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Revisa tus cargos y saldos pendientes'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ClienteEstadoCuenta()));
                },
              ),
            ),

            const SizedBox(height: 32),
            const Text('Avisos de la Escuela', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (alumnoData != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('avisos').orderBy('fecha', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  final avisos = snapshot.data!.docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final aGrado = data['grado'];
                    final aGrupo = data['grupo'];

                    if (aGrado == null) return true; 
                    return aGrado == grado && (aGrupo == null || aGrupo == grupo);
                  }).toList();

                  if (avisos.isEmpty) return const Text('No hay avisos por el momento.', style: TextStyle(color: Colors.grey));

                  return Column(
                    children: avisos.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final fecha = (data['fecha'] as Timestamp?)?.toDate();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.campaign, color: Colors.orange),
                          title: Text(data['titulo'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['mensaje'] ?? ''),
                              const SizedBox(height: 4),
                              Text(fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              )
            else
              const Text('Vincula a tu hijo para ver los avisos de su salón.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}