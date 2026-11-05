import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();
  
  bool cargando = false;
  bool verPassword = false;
  bool verConfirmPassword = false;
  String? error;

  Future<void> registrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (passController.text != confirmPassController.text) {
      setState(() => error = '❌ Las contraseñas no coinciden.');
      return;
    }

    setState(() { cargando = true; error = null; });

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: correoController.text.trim(),
        password: passController.text.trim(),
      );

      await cred.user!.sendEmailVerification();

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'nombre': nombreController.text.trim(),
        'email': correoController.text.trim(),
        'role': 'cliente',
        'activo': true,
        'studentId': null, 
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Cuenta creada. Revisa tu correo y la carpeta de SPAM para verificarla.'), 
          backgroundColor: Colors.green, 
          duration: Duration(seconds: 6)
        ),
      );

      Navigator.pop(context); 

    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          error = '❌ Este correo ya está registrado.';
        } else if (e.code == 'weak-password') {
          error = '❌ La contraseña es muy débil.';
        } else {
          error = '❌ Error: ${e.message}';
        }
        cargando = false;
      });
    } catch (e) {
      setState(() { error = 'Error de conexión.'; cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add, size: 70, color: Color(0xFF1E6F5C)),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person)),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Escribe tu nombre';
                      if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(v)) return 'Solo se permiten letras';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email)),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Escribe tu correo';
                      // VALIDACIÓN ESTRICTA DE CORREO
                      if (!RegExp(r'^[a-zA-Z0-9._%+-]{3,}@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(v)) {
                        return 'Correo inválido (ej. nombre@dominio.com)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: passController,
                    obscureText: !verPassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(verPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => verPassword = !verPassword),
                      ),
                    ),
                    onChanged: (v) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Escribe una contraseña';
                      if (v.length < 8) return 'Mínimo 8 caracteres';
                      if (!v.contains(RegExp(r'[A-Z]'))) return 'Falta una mayúscula';
                      if (!v.contains(RegExp(r'[a-z]'))) return 'Falta una minúscula';
                      if (!v.contains(RegExp(r'[0-9]'))) return 'Falta un número';
                      if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return 'Falta un símbolo (!@#\$)';
                      return null;
                    },
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _textoRequisito('Mínimo 8 caracteres', passController.text.length >= 8),
                        _textoRequisito('Una letra mayúscula', passController.text.contains(RegExp(r'[A-Z]'))),
                        _textoRequisito('Una letra minúscula', passController.text.contains(RegExp(r'[a-z]'))),
                        _textoRequisito('Un número', passController.text.contains(RegExp(r'[0-9]'))),
                        _textoRequisito('Un símbolo (!@#\$%)', passController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: confirmPassController,
                    obscureText: !verConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(verConfirmPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => verConfirmPassword = !verConfirmPassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                      return null;
                    },
                  ),
                  
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Text(error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: cargando ? null : registrar,
                      child: cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Registrarme'),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Ya tengo cuenta, iniciar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textoRequisito(String texto, bool cumplido) {
    return Row(
      children: [
        Icon(cumplido ? Icons.check_circle : Icons.circle_outlined, size: 16, color: cumplido ? Colors.green : Colors.grey),
        const SizedBox(width: 8),
        Text(texto, style: TextStyle(color: cumplido ? Colors.green : Colors.grey, fontSize: 12)),
      ],
    );
  }
}