import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class WalletService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ✅ GET BALANCE
  static Future<double> getBalance() async {
  try {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/wallet/balance'),
      headers: headers,
    );

    print('BALANCE RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return (data['balance'] ?? 0).toDouble();
    }

    print('GetBalance failed: ${response.statusCode}');
    return 0;
  } catch (e) {
    print('GetBalance error: $e');
    return 0;
  }
}

  // ✅ GET TRANSACTIONS
  static Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final headers = await _headers();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/wallet/transactions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }

        if (data is Map && data['transactions'] is List) {
          return List<Map<String, dynamic>>.from(data['transactions']);
        }
      }

      print('GetTransactions failed: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      print('GetTransactions error: $e');
      return [];
    }
  }

  // ✅ TOP UP
 static Future<Map<String, dynamic>> topUp(double amount) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/topup'),
      headers: await _headers(),
      body: jsonEncode({'amount': amount}),
    );

    final data = jsonDecode(response.body);

    return {
      'success': data['success'] == true,
      'message': data['message'],
      'balance': data['balance'],
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Erreur topUp: $e',
    };
  }
}

  // ✅ PAY SUBSCRIPTION
  static Future<Map<String, dynamic>> paySubscription({
    required String serviceName,
    required double amount,
  }) async {
    try {
      final headers = await _headers();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/wallet/pay'),
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'description': serviceName,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Subscription paid successfully',
          'newBalance': (data['balance'] ?? 0).toDouble(),
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Payment failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur paiement abonnement: $e',
      };
    }
  }

  // ✅ QR PAY
  static Future<Map<String, dynamic>> qrPay({
    required int merchantId,
    required double amount,
    required String pin,
  }) async {
    try {
      final headers = await _headers();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/wallet/qr-pay'),
        headers: headers,
        body: jsonEncode({
          'merchantId': merchantId,
          'amount': amount,
          'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      return {
        'success': data['success'] == true,
        'message': data['message'] ?? 'Erreur QR Pay',
        'balance': data['balance'],
        'transaction': data['transaction'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur qrPay: $e',
      };
    }
  }

  // ✅ SIMPLE PAY
  static Future<Map<String, dynamic>> pay({
    required double amount,
    required String pin,
    String description = '',
  }) async {
    try {
      final headers = await _headers();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/wallet/pay'),
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'description': description,
          'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      return {
        'success': data['success'] == true,
        'message': data['message'] ?? 'Erreur paiement',
        'balance': data['balance'],
        'transaction': data['transaction'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur pay: $e',
      };
    }
  }

  // ✅ TRANSFER
  static Future<Map<String, dynamic>> transfer({
    required String receiverPhone,
    required double amount,
    required String pin,
  }) async {
    try {
      final headers = await _headers();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/wallet/transfer'),
        headers: headers,
        body: jsonEncode({
          'receiverPhone': receiverPhone,
          'amount': amount,
          'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      return {
        'success': data['success'] == true,
        'message': data['message'] ?? 'Erreur transfert',
        'reference': data['reference'],
        'transaction': data['transaction'],
        'balance': data['balance'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur transfert: $e',
      };
    }
  }

  // ✅ VERIFY NUMBER
  static Future<Map<String, dynamic>> verifyNumber(String phone) async {
    try {
      final headers = await _headers();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/wallet/verify-number'),
        headers: headers,
        body: jsonEncode({
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);

      return {
        'success': data['success'] == true,
        'message': data['message'] ?? '',
        'name': data['name'] ?? '',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur vérification: $e',
        'name': '',
      };
    }
  }
}