import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import 'professional_pending_page.dart';
import 'health_page.dart';
import 'create_professional_profile_page.dart';
import 'fgsante_subscription_page.dart';
import 'health_professional_pro_page.dart';
import '../config/api_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;
  bool isCheckingSession = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final loggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
  builder: (_) => const HealthPage(),
)
      );
      return;
    }

    setState(() {
      isCheckingSession = false;
    });
  }

  Future<void> handleLogin() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phoneController.text.trim(),
          'password': passwordController.text.trim(),
        }),
      );
 print('RAW RESPONSE = ${response.body}');

      final data = jsonDecode(response.body);

      print('LOGIN RESPONSE = $data');
print('USER RESPONSE = ${data['user']}');

    if (response.statusCode == 200 && data['success'] == true) {

 
  // 🔥 SAVE TOKEN DIRÈK

  print('TOKEN SAVED: ${data['token']}');

print('LOGIN RESPONSE = $data');
print('USER RESPONSE = ${data['user']}');

 await AuthService.saveSession(
  data['token'],
  Map<String, dynamic>.from(data['user']),
);

final user =
    Map<String, dynamic>.from(data['user']);

final subscriptionResponse = await http.get(
  Uri.parse(
    '${ApiConfig.baseUrl}/api/fgsante/subscriptions/me',
  ),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${data['token']}',
  },
);

print(
  'SUBSCRIPTION STATUS CODE = '
  '${subscriptionResponse.statusCode}',
);

print(
  'SUBSCRIPTION RESPONSE = '
  '${subscriptionResponse.body}',
);

bool subscriptionIsActive = false;

if (subscriptionResponse.statusCode == 200) {
  final subscriptionData =
      jsonDecode(subscriptionResponse.body);

  final subscription =
      subscriptionData['subscription'];

  subscriptionIsActive =
      subscription != null &&
      subscription['status'] == 'active';
}

if (!mounted) return;

if (subscriptionIsActive) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const HealthPage(),
    ),
  );
} else {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const FgSanteSubscriptionPage(),
    ),
  );
}

return;





print('HEALTH ROLE = ${user['health_role']}');
print('PRO STATUS = ${user['professional_status']}');
print('VERIFIED = ${user['is_verified_professional']}');

if (
    user['health_role'] == 'doctor' &&
    user['professional_status'] != 'approved'
) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const ProfessionalPendingPage(),
    ),
  );
  return;
}
if (
    user['health_role'] == 'doctor' &&
    user['professional_status'] == 'approved' &&
    user['subscription_status'] != 'active'
) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) =>  FgSanteSubscriptionPage(),
    ),
  );
  return;
}
if (!mounted) return;

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => const HealthPage(),
  ),
);

} else {
  setState(() {
    errorMessage = data['message'] ?? 'Login echwe';
  });
} 
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur login: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }
Widget buildHeader() {
  return Column(
    children: [
      Image.asset(
        'assets/fgsante_logo.png',
        width: 110,
        height: 110,
        fit: BoxFit.contain,
      ),

      const SizedBox(height: 20),

      const Text(
        'Bienvenue sur FG Santé\nWelcome to FG Santé',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),

      const SizedBox(height: 8),

      const Text(
        'Connectez-vous pour accéder à votre espace santé\n'
        'Sign in to access your health space',
        style: TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );
}
 
  Widget buildPhoneField() {
    return TextField(
      controller: phoneController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'Téléphone',
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget buildPasswordField() {
    return TextField(
      controller: passwordController,
      obscureText: obscurePassword,
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              obscurePassword = !obscurePassword;
            });
          },
          icon: Icon(
            obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

 Widget buildLoginButton() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3FA2FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Login',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),

      const SizedBox(height: 12),

      OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateProfessionalProfilePage(),
            ),
          );
        },
        child: const Text(
          'Ouvrir un compte professionnel',
        ),
      ),

      const SizedBox(height: 8),

      TextButton(
       onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const FgSanteSubscriptionPage(),
    ),
  );
},
        child: const Text(
          'Choisir mon abonnement FG Santé',
        ),
      ),
    ],
  );
}

  Widget buildDemoUsers() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E8FF)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test users',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10),
          Text('50911111111 / 123456'),
          SizedBox(height: 4),
          Text('50922222222 / 123456'),
          SizedBox(height: 4),
          Text('50933333333 / 123456'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isCheckingSession) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7FB),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5EAF1)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 18,
                    offset: Offset(0, 8),
                    color: Color.fromRGBO(0, 0, 0, 0.06),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildHeader(),
                  const SizedBox(height: 28),
                  buildPhoneField(),
                  const SizedBox(height: 16),
                  buildPasswordField(),
                  const SizedBox(height: 16),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  buildLoginButton(),
                  const SizedBox(height: 24),
                  buildDemoUsers(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}