import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String nombre;
  final String apellidos;
  final String matricula;
  final String grado;
  final String grupo;
  final String tutorEmail;

  Student({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.matricula,
    required this.grado,
    required this.grupo,
    required this.tutorEmail,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      apellidos: data['apellidos'] ?? '',
      matricula: data['matricula'] ?? '',
      grado: data['grado'] ?? '',
      grupo: data['grupo'] ?? '',
      tutorEmail: data['tutorEmail'] ?? '',
    );
  }
}