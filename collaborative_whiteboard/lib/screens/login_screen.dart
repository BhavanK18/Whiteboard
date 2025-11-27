import 'package:flutter/material.dart';import 'package:flutter/material.dart';import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../services/auth_service.dart';import 'package:provider/provider.dart';import 'package:provider/provider.dart';

import '../utils/demo_mode_banner.dart';

import '../utils/firebase_status.dart';import '../services/auth_service.dart';import '../services/auth_service.dart';

import 'dashboard_screen.dart';

import 'register_screen.dart';import '../utils/demo_mode_banner.dart';import '../utils/demo_mode_banner.dart';

import 'forgot_password_screen.dart';

import '../utils/firebase_status.dart';import '../utils/firebase_status.dart';

class LoginScreen extends StatefulWidget {

  const LoginScreen({super.key});import 'dashboard_screen.dart';import 'dashboard_screen.dart';



  @overrideimport 'register_screen.dart';import 'register_screen.dart';

  State<LoginScreen> createState() => _LoginScreenState();

}import 'forgot_password_screen.dart';import 'forgot_password_screen.dart';



class _LoginScreenState extends State<LoginScreen> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();class LoginScreen extends StatefulWidget {class LoginScreen extends StatefulWidget {

  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;  const LoginScreen({super.key});  const LoginScreen({super.key});

  String? _errorMessage;



  @override

  void dispose() {  @override  @override

    _emailController.dispose();

    _passwordController.dispose();  State<LoginScreen> createState() => _LoginScreenState();  State<LoginScreen> createState() => _LoginScreenState();

    super.dispose();

  }}}



  Future<void> _signIn() async {

    if (!_formKey.currentState!.validate()) {

      return;class _LoginScreenState extends State<LoginScreen> {class _LoginScreenState extends State<LoginScreen> {

    }

  final _formKey = GlobalKey<FormState>();  final _formKey = GlobalKey<FormState>();

    setState(() {

      _isLoading = true;  final TextEditingController _emailController = TextEditingController();  final TextEditingController _emailController = TextEditingController();

      _errorMessage = null;

    });  final TextEditingController _passwordController = TextEditingController();  final TextEditingController _passwordController = TextEditingController();



    try {  bool _isLoading = false;  bool _isLoading = false;

      final authService = Provider.of<AuthService>(context, listen: false);

      await authService.signInWithEmail(  String? _errorMessage;  String? _errorMessage;

        _emailController.text.trim(), 

        _passwordController.text,

      );

        @override  @override

      if (!mounted) return;

      Navigator.of(context).pushReplacement(  void dispose() {  void dispose() {

        MaterialPageRoute(builder: (context) => const DashboardScreen()),

      );    _emailController.dispose();    _emailController.dispose();

    } catch (e) {

      if (!mounted) return;    _passwordController.dispose();    _passwordController.dispose();

      

      setState(() {    super.dispose();    super.dispose();

        _isLoading = false;

        _errorMessage = FirebaseStatus.isDemoMode  }  }

            ? "This is demo mode. Login simulation complete."

            : "Failed to sign in: ${e.toString()}";

      });

    }  Future<void> _signIn() async {  Future<void> _signIn() async {

  }

    if (!_formKey.currentState!.validate()) {    if (!_formKey.currentState!.validate()) {

  Future<void> _signInWithGoogle() async {

    setState(() {      return;      return;

      _isLoading = true;

      _errorMessage = null;    }    }

    });



    try {

      if (FirebaseStatus.isDemoMode) {    setState(() {    setState(() {

        // Simulate delay in demo mode

        await Future.delayed(const Duration(seconds: 1));      _isLoading = true;      _isLoading = true;

        throw Exception("Google Sign-In is disabled in demo mode");

      }      _errorMessage = null;      _errorMessage = null;

      

      final authService = Provider.of<AuthService>(context, listen: false);    });    });

      await authService.signInWithGoogle();

      

      if (!mounted) return;

      Navigator.of(context).pushReplacement(    try {    try {

        MaterialPageRoute(builder: (context) => const DashboardScreen()),

      );      final authService = Provider.of<AuthService>(context, listen: false);      final authService = Provider.of<AuthService>(context, listen: false);

    } catch (e) {

      if (!mounted) return;      await authService.signInWithEmail(      await authService.signInWithEmail(

      

      setState(() {        _emailController.text.trim(),         _emailController.text.trim(), 

        _isLoading = false;

        _errorMessage = FirebaseStatus.isDemoMode        _passwordController.text,        _passwordController.text,

            ? "Google Sign-In is disabled in demo mode."

            : "Failed to sign in with Google: ${e.toString()}";      );      );

      });

    }            

  }

      if (!mounted) return;      if (!mounted) return;

  @override

  Widget build(BuildContext context) {      Navigator.of(context).pushReplacement(      Navigator.of(context).pushReplacement(

    return Scaffold(

      appBar: AppBar(        MaterialPageRoute(builder: (context) => const DashboardScreen()),        MaterialPageRoute(builder: (context) => const DashboardScreen()),

        title: const Text('Login'),

      ),      );      );

      body: Stack(

        children: [    } catch (e) {    } catch (e) {

          if (FirebaseStatus.isDemoMode) const DemoModeBanner(),

          Center(      if (!mounted) return;      setState(() {

            child: SingleChildScrollView(

              padding: const EdgeInsets.all(16.0),              _errorMessage = _handleAuthError(e.toString());

              child: Card(

                elevation: 4.0,      setState(() {      });

                shape: RoundedRectangleBorder(

                  borderRadius: BorderRadius.circular(16.0),        _isLoading = false;    } finally {

                ),

                child: Padding(        _errorMessage = FirebaseStatus.isDemoMode      if (mounted) {

                  padding: const EdgeInsets.all(24.0),

                  child: Column(            ? "This is demo mode. Login simulation complete."        setState(() {

                    mainAxisSize: MainAxisSize.min,

                    children: [            : "Failed to sign in: ${e.toString()}";          _isLoading = false;

                      const Icon(

                        Icons.edit_square,      });        });

                        size: 80,

                        color: Colors.blue,    }      }

                      ),

                      const SizedBox(height: 16),  }    }

                      const Text(

                        'Collaborative Whiteboard',  }

                        style: TextStyle(

                          fontSize: 24,  Future<void> _signInWithGoogle() async {

                          fontWeight: FontWeight.bold,

                        ),    setState(() {  Future<void> _signInWithGoogle() async {

                      ),

                      const SizedBox(height: 8),      _isLoading = true;    setState(() {

                      Text(

                        'Sign in to continue',      _errorMessage = null;      _isLoading = true;

                        style: TextStyle(color: Colors.grey.shade600),

                      ),    });      _errorMessage = null;

                      const SizedBox(height: 32),

                      Form(    });

                        key: _formKey,

                        child: Column(    try {

                          children: [

                            TextFormField(      if (FirebaseStatus.isDemoMode) {    try {

                              controller: _emailController,

                              keyboardType: TextInputType.emailAddress,        // Simulate delay in demo mode      final authService = Provider.of<AuthService>(context, listen: false);

                              decoration: InputDecoration(

                                labelText: 'Email',        await Future.delayed(const Duration(seconds: 1));      await authService.signInWithGoogle();

                                prefixIcon: const Icon(Icons.email_outlined),

                                border: OutlineInputBorder(        throw Exception("Google Sign-In is disabled in demo mode");      

                                  borderRadius: BorderRadius.circular(12),

                                ),      }      if (!mounted) return;

                              ),

                              validator: (value) {            Navigator.of(context).pushReplacement(

                                if (value == null || value.isEmpty) {

                                  return 'Please enter your email';      final authService = Provider.of<AuthService>(context, listen: false);        MaterialPageRoute(builder: (context) => const DashboardScreen()),

                                }

                                final emailRegex = RegExp(      await authService.signInWithGoogle();      );

                                  r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',

                                );          } catch (e) {

                                if (!emailRegex.hasMatch(value)) {

                                  return 'Please enter a valid email';      if (!mounted) return;      setState(() {

                                }

                                return null;      Navigator.of(context).pushReplacement(        _errorMessage = _handleAuthError(e.toString());

                              },

                            ),        MaterialPageRoute(builder: (context) => const DashboardScreen()),      });

                            const SizedBox(height: 16),

                            TextFormField(      );    } finally {

                              controller: _passwordController,

                              obscureText: true,    } catch (e) {      if (mounted) {

                              decoration: InputDecoration(

                                labelText: 'Password',      if (!mounted) return;        setState(() {

                                prefixIcon: const Icon(Icons.lock_outline),

                                border: OutlineInputBorder(                _isLoading = false;

                                  borderRadius: BorderRadius.circular(12),

                                ),      setState(() {        });

                              ),

                              validator: (value) {        _isLoading = false;      }

                                if (value == null || value.isEmpty) {

                                  return 'Please enter your password';        _errorMessage = FirebaseStatus.isDemoMode    }

                                }

                                return null;            ? "Google Sign-In is disabled in demo mode."  }

                              },

                            ),            : "Failed to sign in with Google: ${e.toString()}";

                            Align(

                              alignment: Alignment.centerRight,      });  String _handleAuthError(String error) {

                              child: TextButton(

                                onPressed: () {    }    debugPrint('Raw login error: $error');

                                  Navigator.of(context).push(

                                    MaterialPageRoute(  }    

                                      builder: (context) => const ForgotPasswordScreen(),

                                    ),    if (error.contains('api-key-not-valid')) {

                                  );

                                },  @override      return 'Demo mode: Firebase not properly configured with valid API keys.\n\n'

                                child: const Text('Forgot password?'),

                              ),  Widget build(BuildContext context) {             'This app is currently running with placeholder Firebase credentials. '

                            ),

                            const SizedBox(height: 8),    return Scaffold(             'To enable login features, proper Firebase configuration is required.';

                            if (_errorMessage != null)

                              Container(      appBar: AppBar(    } else if (error.contains('user-not-found')) {

                                width: double.infinity,

                                padding: const EdgeInsets.all(12),        title: const Text('Login'),      return 'No user found with this email address';

                                decoration: BoxDecoration(

                                  color: Colors.red.shade50,      ),    } else if (error.contains('wrong-password')) {

                                  borderRadius: BorderRadius.circular(8),

                                  border: Border.all(color: Colors.red.shade200),      body: Stack(      return 'Wrong password';

                                ),

                                child: Text(        children: [    } else if (error.contains('network-request-failed')) {

                                  _errorMessage!,

                                  style: TextStyle(color: Colors.red.shade700),          if (FirebaseStatus.isDemoMode) const DemoModeBanner(),      return 'Network error. Please check your connection';

                                ),

                              ),          Center(    } else if (error.contains('PERMISSION_DENIED')) {

                            const SizedBox(height: 16),

                            SizedBox(            child: SingleChildScrollView(      return 'Permission denied';

                              width: double.infinity,

                              height: 50,              padding: const EdgeInsets.all(16.0),    } else if (error.contains('FirebaseApp')) {

                              child: ElevatedButton(

                                onPressed: _isLoading ? null : _signIn,              child: Card(      return 'Firebase not properly configured. This is a development issue.';

                                style: ElevatedButton.styleFrom(

                                  backgroundColor: Colors.blue,                elevation: 4.0,    } else if (error.contains('UnimplementedError')) {

                                  foregroundColor: Colors.white,

                                  shape: RoundedRectangleBorder(                shape: RoundedRectangleBorder(      return 'Google Sign-In is temporarily disabled in this version';

                                    borderRadius: BorderRadius.circular(12),

                                  ),                  borderRadius: BorderRadius.circular(16.0),    } else {

                                ),

                                child: _isLoading                ),      // Include part of the original error for debugging

                                    ? const CircularProgressIndicator(color: Colors.white)

                                    : const Text(                child: Padding(      String truncatedError = error.length > 100 ? '${error.substring(0, 100)}...' : error;

                                        'Sign In',

                                        style: TextStyle(                  padding: const EdgeInsets.all(24.0),      return 'Authentication failed: $truncatedError';

                                          fontSize: 16,

                                          fontWeight: FontWeight.bold,                  child: Column(    }

                                        ),

                                      ),                    mainAxisSize: MainAxisSize.min,  }

                              ),

                            ),                    children: [

                            const SizedBox(height: 16),

                            Row(                      const Icon(  @override

                              children: [

                                Expanded(                        Icons.edit_square,  Widget build(BuildContext context) {

                                  child: Divider(

                                    color: Colors.grey.shade300,                        size: 80,    return Scaffold(

                                    thickness: 1,

                                  ),                        color: Colors.blue,      body: Column(

                                ),

                                Padding(                      ),        children: [

                                  padding: const EdgeInsets.symmetric(horizontal: 16),

                                  child: Text(                      const SizedBox(height: 16),          // Show demo mode banner if Firebase is not configured

                                    'OR',

                                    style: TextStyle(                      const Text(          if (!FirebaseStatus.isConfigured) 

                                      color: Colors.grey.shade600,

                                      fontWeight: FontWeight.bold,                        'Collaborative Whiteboard',            const DemoModeBanner(),

                                    ),

                                  ),                        style: TextStyle(          Expanded(

                                ),

                                Expanded(                          fontSize: 24,            child: Center(

                                  child: Divider(

                                    color: Colors.grey.shade300,                          fontWeight: FontWeight.bold,              child: SingleChildScrollView(

                                    thickness: 1,

                                  ),                        ),                child: Padding(

                                ),

                              ],                      ),                  padding: const EdgeInsets.all(24.0),

                            ),

                            const SizedBox(height: 16),                      const SizedBox(height: 8),                  child: Column(

                            SizedBox(

                              width: double.infinity,                      Text(                    mainAxisAlignment: MainAxisAlignment.center,

                              height: 50,

                              child: OutlinedButton.icon(                        'Sign in to continue',                    children: [

                                onPressed: _isLoading ? null : _signInWithGoogle,

                                icon: Image.network(                        style: TextStyle(color: Colors.grey.shade600),                      // App logo or icon

                                  'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',

                                  height: 24,                      ),                      Container(

                                ),

                                label: const Text(                      const SizedBox(height: 32),                        width: 100,

                                  'Sign in with Google',

                                  style: TextStyle(                      Form(                        height: 100,

                                    fontSize: 16,

                                    fontWeight: FontWeight.bold,                        key: _formKey,                        decoration: BoxDecoration(

                                    color: Colors.black87,

                                  ),                        child: Column(                          color: Theme.of(context).colorScheme.primary,

                                ),

                                style: OutlinedButton.styleFrom(                          children: [                          shape: BoxShape.circle,

                                  side: BorderSide(color: Colors.grey.shade300),

                                  shape: RoundedRectangleBorder(                            TextFormField(                        ),

                                    borderRadius: BorderRadius.circular(12),

                                  ),                              controller: _emailController,                        child: const Icon(

                                ),

                              ),                              keyboardType: TextInputType.emailAddress,                          Icons.draw,

                            ),

                          ],                              decoration: InputDecoration(                          size: 50,

                        ),

                      ),                                labelText: 'Email',                          color: Colors.white,

                      const SizedBox(height: 24),

                      Row(                                prefixIcon: const Icon(Icons.email_outlined),                        ),

                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [                                border: OutlineInputBorder(                      ),

                          Text(

                            "Don't have an account?",                                  borderRadius: BorderRadius.circular(12),                      const SizedBox(height: 24),

                            style: TextStyle(color: Colors.grey.shade600),

                          ),                                ),                      Text(

                          TextButton(

                            onPressed: () {                              ),                        'Collaborative Whiteboard',

                              Navigator.of(context).push(

                                MaterialPageRoute(                              validator: (value) {                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(

                                  builder: (context) => const RegisterScreen(),

                                ),                                if (value == null || value.isEmpty) {                              fontWeight: FontWeight.bold,

                              );

                            },                                  return 'Please enter your email';                            ),

                            child: const Text('Sign Up'),

                          ),                                }                        textAlign: TextAlign.center,

                        ],

                      ),                                final emailRegex = RegExp(                      ),

                    ],

                  ),                                  r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',                      const SizedBox(height: 8),

                ),

              ),                                );                      Text(

            ),

          ),                                if (!emailRegex.hasMatch(value)) {                        'Sign in to continue',

        ],

      ),                                  return 'Please enter a valid email';                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(

    );

  }                                }                              color: Colors.grey,

}
                                return null;                            ),

                              },                      ),

                            ),                      const SizedBox(height: 32),

                            const SizedBox(height: 16),                      if (_errorMessage != null) ...[

                            TextFormField(                        Container(

                              controller: _passwordController,                          padding: const EdgeInsets.all(12),

                              obscureText: true,                          decoration: BoxDecoration(

                              decoration: InputDecoration(                            color: Colors.red.withOpacity(0.1),

                                labelText: 'Password',                            borderRadius: BorderRadius.circular(8),

                                prefixIcon: const Icon(Icons.lock_outline),                          ),

                                border: OutlineInputBorder(                          child: Row(

                                  borderRadius: BorderRadius.circular(12),                            crossAxisAlignment: CrossAxisAlignment.start,

                                ),                            children: [

                              ),                              const Icon(Icons.error_outline, color: Colors.red),

                              validator: (value) {                              const SizedBox(width: 12),

                                if (value == null || value.isEmpty) {                              Expanded(

                                  return 'Please enter your password';                                child: Text(

                                }                                  _errorMessage!,

                                return null;                                  style: const TextStyle(color: Colors.red),

                              },                                ),

                            ),                              ),

                            Align(                            ],

                              alignment: Alignment.centerRight,                          ),

                              child: TextButton(                        ),

                                onPressed: () {                        const SizedBox(height: 24),

                                  Navigator.of(context).push(                      ],

                                    MaterialPageRoute(                      Form(

                                      builder: (context) => const ForgotPasswordScreen(),                        key: _formKey,

                                    ),                        child: Column(

                                  );                          children: [

                                },                            TextFormField(

                                child: const Text('Forgot password?'),                              controller: _emailController,

                              ),                              decoration: const InputDecoration(

                            ),                                labelText: 'Email',

                            const SizedBox(height: 8),                                hintText: 'Enter your email',

                            if (_errorMessage != null)                                prefixIcon: Icon(Icons.email),

                              Container(                              ),

                                width: double.infinity,                              keyboardType: TextInputType.emailAddress,

                                padding: const EdgeInsets.all(12),                              validator: (value) {

                                decoration: BoxDecoration(                                if (value == null || value.isEmpty) {

                                  color: Colors.red.shade50,                                  return 'Please enter your email';

                                  borderRadius: BorderRadius.circular(8),                                }

                                  border: Border.all(color: Colors.red.shade200),                                return null;

                                ),                              },

                                child: Text(                            ),

                                  _errorMessage!,                            const SizedBox(height: 16),

                                  style: TextStyle(color: Colors.red.shade700),                            TextFormField(

                                ),                              controller: _passwordController,

                              ),                              decoration: const InputDecoration(

                            const SizedBox(height: 16),                                labelText: 'Password',

                            SizedBox(                                hintText: 'Enter your password',

                              width: double.infinity,                                prefixIcon: Icon(Icons.lock),

                              height: 50,                              ),

                              child: ElevatedButton(                              obscureText: true,

                                onPressed: _isLoading ? null : _signIn,                              validator: (value) {

                                style: ElevatedButton.styleFrom(                                if (value == null || value.isEmpty) {

                                  backgroundColor: Colors.blue,                                  return 'Please enter your password';

                                  foregroundColor: Colors.white,                                }

                                  shape: RoundedRectangleBorder(                                return null;

                                    borderRadius: BorderRadius.circular(12),                              },

                                  ),                            ),

                                ),                            Align(

                                child: _isLoading                              alignment: Alignment.centerRight,

                                    ? const CircularProgressIndicator(color: Colors.white)                              child: TextButton(

                                    : const Text(                                onPressed: () {

                                        'Sign In',                                  Navigator.of(context).push(

                                        style: TextStyle(                                    MaterialPageRoute(

                                          fontSize: 16,                                      builder: (context) => const ForgotPasswordScreen(),

                                          fontWeight: FontWeight.bold,                                    ),

                                        ),                                  );

                                      ),                                },

                              ),                                child: const Text('Forgot Password?'),

                            ),                              ),

                            const SizedBox(height: 16),                            ),

                            Row(                            const SizedBox(height: 24),

                              children: [                            SizedBox(

                                Expanded(                              width: double.infinity,

                                  child: Divider(                              child: ElevatedButton(

                                    color: Colors.grey.shade300,                                onPressed: _isLoading ? null : _signIn,

                                    thickness: 1,                                style: ElevatedButton.styleFrom(

                                  ),                                  padding: const EdgeInsets.symmetric(vertical: 12),

                                ),                                ),

                                Padding(                                child: _isLoading

                                  padding: const EdgeInsets.symmetric(horizontal: 16),                                    ? const SizedBox(

                                  child: Text(                                        height: 20,

                                    'OR',                                        width: 20,

                                    style: TextStyle(                                        child: CircularProgressIndicator(

                                      color: Colors.grey.shade600,                                          strokeWidth: 2,

                                      fontWeight: FontWeight.bold,                                          color: Colors.white,

                                    ),                                        ),

                                  ),                                      )

                                ),                                    : const Text('Sign In'),

                                Expanded(                              ),

                                  child: Divider(                            ),

                                    color: Colors.grey.shade300,                            const SizedBox(height: 16),

                                    thickness: 1,                            const Row(

                                  ),                              children: [

                                ),                                Expanded(child: Divider()),

                              ],                                Padding(

                            ),                                  padding: EdgeInsets.symmetric(horizontal: 16),

                            const SizedBox(height: 16),                                  child: Text('OR'),

                            SizedBox(                                ),

                              width: double.infinity,                                Expanded(child: Divider()),

                              height: 50,                              ],

                              child: OutlinedButton.icon(                            ),

                                onPressed: _isLoading ? null : _signInWithGoogle,                            const SizedBox(height: 16),

                                icon: Image.network(                            SizedBox(

                                  'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',                              width: double.infinity,

                                  height: 24,                              child: OutlinedButton.icon(

                                ),                                onPressed: _isLoading ? null : _signInWithGoogle,

                                label: const Text(                                icon: Image.network(

                                  'Sign in with Google',                                  'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/google/google-original.svg',

                                  style: TextStyle(                                  height: 20,

                                    fontSize: 16,                                  width: 20,

                                    fontWeight: FontWeight.bold,                                ),

                                    color: Colors.black87,                                label: const Text('Sign in with Google'),

                                  ),                                style: OutlinedButton.styleFrom(

                                ),                                  padding: const EdgeInsets.symmetric(vertical: 12),

                                style: OutlinedButton.styleFrom(                                ),

                                  side: BorderSide(color: Colors.grey.shade300),                              ),

                                  shape: RoundedRectangleBorder(                            ),

                                    borderRadius: BorderRadius.circular(12),                          ],

                                  ),                        ),

                                ),                      ),

                              ),                      const SizedBox(height: 24),

                            ),                      Row(

                          ],                        mainAxisAlignment: MainAxisAlignment.center,

                        ),                        children: [

                      ),                          Text(

                      const SizedBox(height: 24),                            "Don't have an account?",

                      Row(                            style: TextStyle(color: Colors.grey.shade600),

                        mainAxisAlignment: MainAxisAlignment.center,                          ),

                        children: [                          TextButton(

                          Text(                            onPressed: () {

                            "Don't have an account?",                              Navigator.of(context).push(

                            style: TextStyle(color: Colors.grey.shade600),                                MaterialPageRoute(

                          ),                                  builder: (context) => const RegisterScreen(),

                          TextButton(                                ),

                            onPressed: () {                              );

                              Navigator.of(context).push(                            },

                                MaterialPageRoute(                            child: const Text('Sign Up'),

                                  builder: (context) => const RegisterScreen(),                          ),

                                ),                        ],

                              );                      ),

                            },                    ],

                            child: const Text('Sign Up'),                  ),

                          ),                ),

                        ],              ),

                      ),            ),

                    ],          ),

                  ),        ],

                ),      ),

              ),    );

            ),  }

          ),}

        ],import 'package:provider/provider.dart';

      ),import '../services/auth_service.dart';

    );import '../utils/demo_mode_banner.dart';

  }import '../utils/firebase_status.dart';

}import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = _handleAuthError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithGoogle();
      
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = _handleAuthError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _handleAuthError(String error) {
    debugPrint('Raw login error: $error');
    
    if (error.contains('api-key-not-valid') || error.contains('API key not valid')) {
      return 'Firebase API key error: Please check Firebase configuration. '
             'The API keys in the Firebase configuration may be invalid or restricted. '
             'Ensure you have the correct Firebase project configuration for this app.';
    } else if (error.contains('user-not-found')) {
      return 'No user found with this email address';
    } else if (error.contains('wrong-password')) {
      return 'Wrong password';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Please check your connection';
    } else if (error.contains('PERMISSION_DENIED')) {
      return 'Permission denied';
    } else if (error.contains('FirebaseApp')) {
      return 'Firebase not properly configured. This is a development issue.';
    } else if (error.contains('UnimplementedError')) {
      return 'Google Sign-In is temporarily disabled in this version';
    } else {
      // Include part of the original error for debugging
      String truncatedError = error.length > 100 ? '${error.substring(0, 100)}...' : error;
      return 'Authentication failed: $truncatedError';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Show demo mode banner if Firebase is not configured
          if (!FirebaseStatus.isConfigured) 
            const DemoModeBanner(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                // App logo or icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.draw,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Collaborative Whiteboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Forgot password functionality
                          },
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signInWithEmail,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: Image.network(
                            'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/google/google-original.svg',
                            height: 20,
                            width: 20,
                          ),
                          label: const Text('Sign in with Google'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}