//auth_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Logowanie
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        // Odśwież dane użytkownika
        await credential.user!.reload();
        final user = FirebaseAuth.instance.currentUser;
        
        // Sprawdź czy email jest zweryfikowany
        if (user != null && !user.emailVerified) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            _showVerificationDialog(user);
          }
          return;
        }
        
        debugPrint('✅ Logowanie pomyślne: ${user?.email}');
      } else {
        // Rejestracja
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        debugPrint('✅ Rejestracja pomyślna: ${credential.user?.email}');
        
        // Wyślij email weryfikacyjny z ActionCodeSettings
        final actionCodeSettings = ActionCodeSettings(
          url: 'xxxxx', //Zamień na swój URL z Firebase Console
          handleCodeInApp: false,
          androidPackageName: 'com.example.projekt',
          androidInstallApp: false,
        );
        
        try {
          await credential.user!.sendEmailVerification(actionCodeSettings);
          debugPrint('✅ Email weryfikacyjny wysłany na: ${_emailController.text.trim()}');
        } catch (emailError) {
          debugPrint('⚠️ Błąd wysyłania emaila: $emailError');
          // Kontynuuj mimo błędu - może email się wysłał
        }
        
        // Wyloguj użytkownika - musi najpierw zweryfikować email
        await FirebaseAuth.instance.signOut();
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('✉️ Sprawdź swoją skrzynkę'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Link aktywacyjny został wysłany na:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _emailController.text.trim(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'WAŻNE:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('• Sprawdź folder SPAM/Wiadomości-śmieci'),
                        const Text('• Email może przyjść po kilku minutach'),
                        const Text('• Sprawdź czy adres email jest poprawny'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Po kliknięciu w link w emailu, wróć tutaj i zaloguj się.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    setState(() => _isLogin = true);
                  },
                  child: const Text('OK, rozumiem'),
                ),
              ],
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'Ten email jest już zarejestrowany. Spróbuj się zalogować.';
            break;
          case 'weak-password':
            errorMessage = 'Hasło jest za słabe. Użyj minimum 6 znaków.';
            break;
          case 'invalid-email':
            errorMessage = 'Nieprawidłowy format adresu email.';
            break;
          case 'user-not-found':
            errorMessage = 'Nie znaleziono użytkownika o tym adresie email.';
            break;
          case 'wrong-password':
            errorMessage = 'Nieprawidłowe hasło.';
            break;
          case 'invalid-credential':
            errorMessage = 'Nieprawidłowy email lub hasło.';
            break;
          case 'too-many-requests':
            errorMessage = 'Zbyt wiele prób logowania. Spróbuj ponownie później.';
            break;
          default:
            errorMessage = e.message ?? 'Wystąpił błąd: ${e.code}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Nieoczekiwany błąd: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wystąpił nieoczekiwany błąd: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showVerificationDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Email nie zweryfikowany'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Twój email nie został jeszcze zweryfikowany.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Sprawdź skrzynkę pocztową (również SPAM) i kliknij w link aktywacyjny.'),
            const SizedBox(height: 12),
            Text(
              'Email: ${_emailController.text.trim()}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                // Zaloguj się ponownie żeby wysłać email
                final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: _emailController.text.trim(),
                  password: _passwordController.text,
                );
                
                // Wyślij email weryfikacyjny
                final actionCodeSettings = ActionCodeSettings(
                  url: 'xxxxx', //Zamień na swój URL z Firebase Console
                  handleCodeInApp: false,
                  androidPackageName: 'com.example.projekt',
                  androidInstallApp: false,
                );
                
                await credential.user!.sendEmailVerification(actionCodeSettings);
                await FirebaseAuth.instance.signOut();
                
                debugPrint('✅ Email weryfikacyjny wysłany ponownie');
                
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Link aktywacyjny został wysłany ponownie. Sprawdź skrzynkę (również SPAM).'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('❌ Błąd ponownego wysyłania: $e');
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Błąd: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Wyślij ponownie'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 123, 189, 243),
              Color.fromARGB(255, 0, 0, 0),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(Icons.map, size: 80, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _isLogin ? 'Zaloguj się' : 'Zarejestruj się',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.email, color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white54),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => v != null && v.contains('@') ? null : 'Podaj poprawny email',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Hasło',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white54),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => v != null && v.length >= 6 ? null : 'Minimum 6 znaków',
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_isLogin ? 'Zaloguj' : 'Zarejestruj', style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin ? 'Nie masz konta? Zarejestruj się' : 'Masz już konto? Zaloguj się',
                        style: const TextStyle(color: Colors.white),
                      ),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}