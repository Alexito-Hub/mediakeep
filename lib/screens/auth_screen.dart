import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/responsive.dart';
import '../widgets/auth/google_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // We no longer directly reference FirebaseAuth or GoogleSignIn here;
  // AuthService encapsulates the interactions for clean separation.
  bool _isLoading = false;
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Por favor ingresa correo y contraseña.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await AuthService.signInWithEmail(email: email, password: password);
      } else {
        final credential = await AuthService.registerWithEmail(
          email: email,
          password: password,
        );
        if (credential.user != null) {
          await FirestoreService.initializeUser(credential.user!);
        }
      }

      if (mounted) {
        Navigator.pop(context); // Return to previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isLogin ? 'Sesión iniciada' : 'Cuenta creada exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Error de autenticación.');
    } catch (e) {
      _showError('Error inesperado.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Por favor ingresa tu correo para restablecer la contraseña.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correo de recuperación enviado. Revisa tu bandeja.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Error al enviar correo de recuperación.');
    } catch (e) {
      _showError('Error inesperado.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await AuthService.signInWithGoogle();
      if (userCredential?.user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesión iniciada con Google exitosamente.'),
              backgroundColor: Colors.green,
            ),
          );
          if (Navigator.canPop(context)) Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Error autenticando con Google.');
    } catch (e) {
      _showError('Error inesperado al conectar con Google.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Iniciar Sesión' : 'Crear Cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: Responsive.getContentPadding(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                _isLogin ? 'Ingresar' : 'Registrarse',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('O'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    buildGoogleSignInButton(
                      isLoading: _isLoading,
                      onPressed: _signInWithGoogle,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin
                            ? '¿No tienes cuenta? Regístrate.'
                            : '¿Ya tienes cuenta? Inicia sesión.',
                      ),
                    ),
                    if (_isLogin)
                      TextButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
