import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';


class WalletService {
   
 
static Future<Map<String, dynamic>> subscribe({
  required String service,
  required String plan,
  required double amount,
  required String pin,
}) async {
 final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('token') ?? '';



print('TOKEN SUBSCRIBE: $token');


final res = await http.post(
  Uri.parse('${ApiConfig.baseUrl}/api/subscription/subscribe'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({
    'service': service,
    'plan': plan,
    'amount': amount,
    'pin': pin,
  }),
);

  return jsonDecode(res.body);
}

  
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

static Future<void> saveFcmToken(String token) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/wallet/save-fcm-token'),
      headers: await _headers(),
      body: jsonEncode({
        'token': token,
      }),
    );

    print('FCM SAVE RESPONSE: ${response.body}');
  } catch (e) {
    print('FCM SAVE ERROR: $e');
  }
}

static Future<Map<String, dynamic>> getAdminPayments() async {
  final token = await AuthService.getToken();

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/admin/manual-payments'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  // DEBUG
  print(response.body);

  return jsonDecode(response.body);
}

static Future<List<dynamic>> getAdminManualPayments() async {
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/services/admin/manual-payments'),
    headers: await _headers(),
  );

  final data = jsonDecode(response.body);

  if (data is Map && data['payments'] is List) {
    return data['payments'];
  }

  return [];
}



static Future<List<dynamic>> getNotifications() async {
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/services/notifications'),
    headers: await _headers(),
  );

  final data = jsonDecode(response.body);

  if (data is Map && data['notifications'] is List) {
    return data['notifications'];
  }

  return [];
}

static Future<int> getUnreadNotificationCount() async {
  final notifications = await getNotifications();
  return notifications.where((n) => n['is_read'] == false).length;
}

  static Future<double?> getBalance() async {
  try {
    final token = await AuthService.getToken();
print('JWT FGPAY TOKEN: $token');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/wallet/balance'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );


print('BALANCE STATUS = ${response.statusCode}');
print('BALANCE BODY = ${response.body}');

final data = jsonDecode(response.body);
    

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['balance'] as num).toDouble();
    }

    return null;
  } catch (e) {
    print('GET BALANCE ERROR: $e');
    return null;
  }
}

  static Future<List<dynamic>> getTransactions() async {
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/wallet/transactions'),
    headers: await _headers(),
  );

  final data = jsonDecode(response.body);

  if (data is List) {
    return data;
  }

  if (data is Map && data['transactions'] is List) {
    return data['transactions'];
  }

  return [];
}

static Future<Map<String, dynamic>> manualTopup({
  required double amount,
  required String method,
}) async {
  final token = await AuthService.getToken();

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/wallet/manual-topup'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'amount': amount,
      'method': method,
    }),
  );

  return jsonDecode(response.body);
}

  static Future<Map<String, dynamic>> topUp({
  required double amount,
  required String pin,
}) async {
  try {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'message': 'Utilisateur non connecté',
      };
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/wallet/topup'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': amount,
        'pin': pin,
      }),
    );

    print('TOPUP STATUS: ${response.statusCode}');
    print('TOPUP BODY: ${response.body}');

    return jsonDecode(response.body);
  
  } catch (e) {
    return {
      'success': false,
      'message': 'Erreur topup: $e',
    };
  }
}

  static Future<Map<String, dynamic>> pay({
    required double amount,
    required String pin,
    String? description,
    int? merchantId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/wallet/pay'),
      headers: await _headers(),
      body: jsonEncode({
        'amount': amount,
        'pin': pin,
        'description': description ?? 'Paiement service',
        'merchantId': merchantId,
      }),
    );

    return jsonDecode(response.body);
  }
  
static Future<Map<String, dynamic>> approveManualPayment({
  required int paymentId,
}) async {
  final token = await AuthService.getToken();

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/admin/transactions/$paymentId/approve'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  return jsonDecode(response.body);
}

  static Future<Map<String, dynamic>> manualPayment({
  required String method,
  required double amount,
  required String reference,
  required String pin,
}) async {
  try {
    final token = await AuthService.getToken();

    final response = await http.post(
  Uri.parse('${ApiConfig.baseUrl}/api/wallet/manual-payment'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },

  
  body: jsonEncode({
    'method': method,
    'amount': amount,
    'reference': reference,
    'pin': pin,
  }),
);

 

    print("RESPONSE: ${response.body}");

    return jsonDecode(response.body);
  } catch (e) {
    return {
      'success': false,
      'message': 'Erreur: $e',
    };
  }
}
static Future<Map<String, dynamic>> getManualPayments() async {
  final token = await AuthService.getToken();

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/admin/manual-payments'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print('ADMIN STATUS: ${response.statusCode}');
  print('ADMIN BODY: ${response.body}');

  return jsonDecode(response.body);
}

 static Future<Map<String, dynamic>> transfer({
  required String receiverPhone,
  required double amount,
  required String pin,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/wallet/transfer'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
   body: jsonEncode({
  'receiverPhone': receiverPhone,
  'amount': amount,
  'pin': pin,
}),

  );
final data = jsonDecode(response.body);
return data;

  print("TRANSFER STATUS: ${response.statusCode}");
  print("TRANSFER BODY: ${response.body}");

  return jsonDecode(response.body);
}
 
static Future<Map<String, dynamic>> validateManualPayment({
  required int paymentId,
}) async {
  final token = await AuthService.getToken();

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/admin/manual-payments/$paymentId/validate'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  return jsonDecode(response.body);
}

static Future<Map<String, dynamic>> rejectManualPayment({
  required int paymentId,
}) async {
  final token = await AuthService.getToken();

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/admin/manual-payments/$paymentId/reject'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  return jsonDecode(response.body);
}

}


