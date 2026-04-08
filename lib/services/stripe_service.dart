import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class StripeService {
  static Future<String?> createCheckoutSession({
    required String serviceName,
    required double amount,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/stripe/create-checkout-session';
      print('STRIPE REQUEST URL = $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'serviceName': serviceName,
          'amount': amount,
          'currency': 'eur',
        }),
      );

      print('STRIPE STATUS CODE = ${response.statusCode}');
      print('STRIPE RESPONSE BODY = ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['checkoutUrl'];
      }

      return null;
    } catch (e) {
      print('STRIPE SERVICE ERROR = $e');
      return null;
    }
  }
}