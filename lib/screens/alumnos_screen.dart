import 'package:flutter/material.dart';

import '../models/student.dart';
import '../services/student_service.dart';
import 'alumno_form_screen.dart';
import 'alumno_detalle_screen.dart';

class AlumnosScreen extends StatefulWidget {
  const AlumnosScreen({super.key});

  @override
  State<AlumnosScreen> createState() => _AlumnosScreenState();
}

class _AlumnosScreenState extends State<AlumnosScreen> {
  final StudentService _studentService = StudentService();
  String busqueda = '';
  String? filtroGrado;
  String? filtroGrupo;

  final grados = ['1ro', '2do', '3ro', '4to', '5to', '6to'];
  final grupos = ['A', 'B'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Directorio de Alumnos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar alumno...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => busqueda = v.toLowerCase().trim()),
            ),
          ),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: filtroGrado == null,
                  onSelected: (v) => setState(() { filtroGrado = null; filtroGrupo = null; }),
                ),
                const SizedBox(width: 8),
                ...grados.map((g) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(g),
                    selected: filtroGrado == g,
                    onSelected: (v) => setState(() => filtroGrado = v ? g : null),
                  ),
                )),
                const VerticalDivider(),
                const SizedBox(width: 8),
                ...grupos.map((g) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(g),
                    selected: filtroGrupo == g,
                    onSelected: (v) => setState(() => filtroGrupo = v ? g : null),
                  ),
                )),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Student>>(
              // AQUÍ USAMOS LA CAPA DE SERVICIOS
              stream: _studentService.getStudents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                // Filtrado en memoria (Capa de presentación)
                final alumnos = snapshot.data!.where((alumno) {
                  bool coincideTexto = alumno.nombre.toLowerCase().contains(busqueda) || 
                                       alumno.apellidos.toLowerCase().contains(busqueda) ||
                                       alumno.matricula.toLowerCase().contains(busqueda);
                  bool coincideGrado = filtroGrado == null || alumno.grado == filtroGrado;
                  bool coincideGrupo = filtroGrupo == null || alumno.grupo == filtroGrupo;

                  return coincideTexto && coincideGrado && coincideGrupo;
                }).toList();

                if (alumnos.isEmpty) return const Center(child: Text('No hay alumnos que coincidan'));

                return ListView.builder(
                  itemCount: alumnos.length,
                  itemBuilder: (context, i) {
                    final alumno = alumnos[i];
                    final inicial = alumno.nombre.isNotEmpty ? alumno.nombre[0].toUpperCase() : '?';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E6F5C),
                          child: Text(inicial, style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text('${alumno.nombre} ${alumno.apellidos}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${alumno.grado} "${alumno.grupo}" | Mat: ${alumno.matricula}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlumnoDetalleScreen(alumnoId: alumno.id))),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlumnoFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Alumno'),
      ),
    );
  }
}