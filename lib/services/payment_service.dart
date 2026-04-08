import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static Future<String?> createPayment(int amount) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/payments/create-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}),
      );

      final data = jsonDecode(response.body);

      return data['clientSecret'];
    } catch (e) {
      print('Payment error: $e');
      return null;
    }
  }
}