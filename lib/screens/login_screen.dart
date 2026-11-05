import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../admin_home.dart';
import '../cliente_home.dart';
import 'registro_screen.dart';

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

      // Verificación de correo (Eileen)
      if (!cred.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          error = '❌ Debes verificar tu correo antes de entrar.';
          cargando = false;
        });
        _mostrarDialogoReenviarCorreo(usuario);
        return;
      }

      _verificarRolYEntrar(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      // Manejo de errores de red vs credenciales (Eileen)
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          error = 'Correo o contraseña incorrectos.';
        } else if (e.code == 'network-request-failed') {
          error = 'Error de conexión. Revisa tu internet e intenta de nuevo.';
        } else {
          error = 'Error al iniciar sesión (${e.code}).';
        }
        cargando = false;
      });
    } catch (e) {
      setState(() { error = 'Error inesperado de conexión.'; cargando = false; });
    }
  }

  void _mostrarDialogoReenviarCorreo(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verifica tu correo'),
        content: Text('Enviamos un enlace a $email. Revisa tu bandeja de entrada o spam.'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Correo reenviado')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Espera un momento para reenviar.')));
                }
              }
            },
            child: const Text('Reenviar correo'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _recuperarPassword() async {
    final resetController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Escribe tu correo y te enviaremos un enlace para restablecerla.'),
            const SizedBox(height: 12),
            TextField(
              controller: resetController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo electrónico'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (resetController.text.trim().isEmpty) return;
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: resetController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Enlace enviado. Revisa tu correo.'), backgroundColor: Colors.green),
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
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
      setState(() { error = 'Error con Google: verifica tu conexión.'; cargando = false; });
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
      setState(() { error = 'Error al verificar perfil. Revisa tu conexión.'; cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E6F5C), Color(0xFF89C4B6)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school, size: 80, color: Color(0xFF1E6F5C)),
                      const SizedBox(height: 16),
                      const Text('EUREKA', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      const Text('Gestión Escolar', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 32),
                      
                      TextField(
                        controller: correoController,
                        decoration: const InputDecoration(labelText: 'Correo o Matrícula', prefixIcon: Icon(Icons.person)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
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
                      ),
                      
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _recuperarPassword,
                          child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(fontSize: 12)),
                        ),
                      ),

                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      ],
                      
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: FilledButton(
                          onPressed: cargando ? null : entrar,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: cargando 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text('INICIAR SESIÓN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("O", style: TextStyle(color: Colors.grey))),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton.icon(
                          onPressed: cargando ? null : entrarConGoogle,
                          icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google_%22G%22_Logo.svg/512px-Google_%22G%22_Logo.svg.png', height: 24),
                          label: const Text('Continuar con Google', style: TextStyle(color: Colors.black87, fontSize: 16)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroScreen())),
                        child: const Text('¿No tienes cuenta? Regístrate aquí', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}