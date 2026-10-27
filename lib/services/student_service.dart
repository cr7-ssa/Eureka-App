import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class StudentService {
  final CollectionReference _studentsRef = FirebaseFirestore.instance.collection('students');

  // Obtener alumnos en tiempo real
  Stream<List<Student>> getStudents() {
    return _studentsRef.where('activo', isEqualTo: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();
    });
  }
}