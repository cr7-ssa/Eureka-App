import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../admin_home.dart';
import '../cliente_home.dart';
import 'registro_screen.dart'; // <-- Importamos el registro

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final correoController = TextEditingController();
  final passController = TextEditingController();
  bool cargando = false;
  bool verPassword = false;
  String? error;

  Future<void> entrar() async {
    setState(() { cargando = true; error = null; });
    try {
      String usuario = correoController.text.trim();
      if (!usuario.contains('@')) usuario = '$usuario@eureka.com';

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: usuario,
        password: passController.text.trim(),
      );

      _verificarRolYEntrar(cred.user!.uid);
    } catch (e) {
      setState(() { error = 'Correo o contraseña incorrectos'; cargando = false; });
    }
  }

  Future<void> entrarConGoogle() async {
    setState(() { cargando = true; error = null; });
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); 

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() { cargando = false; });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      _verificarRolYEntrar(cred.user!.uid);

    } catch (e) {
      setState(() { error = 'Error con Google: ${e.toString()}'; cargando = false; });
    }
  }

  Future<void> _verificarRolYEntrar(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
        setState(() { error = '❌ Tu correo no está registrado en la escuela.'; cargando = false; });
        return;
      }

      final rol = userDoc.data()?['role'];
      if (!mounted) return;

      if (rol == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHome()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ClienteHome()));
      }
    } catch (e) {
      setState(() { error = 'Error al verificar perfil.'; cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school, size: 80, color: Color(0xFF1E6F5C)),
                const SizedBox(height: 16),
                const Text('EUREKA', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextField(
                  controller: correoController,
                  decoration: const InputDecoration(labelText: 'Correo o Matrícula', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passController,
                  obscureText: !verPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(verPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => verPassword = !verPassword),
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: cargando ? null : entrar,
                    child: cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Entrar'),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("O")),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: cargando ? null : entrarConGoogle,
                    icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google_%22G%22_Logo.svg/512px-Google_%22G%22_Logo.svg.png', height: 24),
                    label: const Text('Continuar con Google', style: TextStyle(color: Colors.black)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 32),
                // BOTÓN DE REGISTRO MANTENIDO
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroScreen())),
                  child: const Text('¿No tienes cuenta? Regístrate aquí', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}