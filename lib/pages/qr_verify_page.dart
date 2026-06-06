import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

class QrVerifyPage extends StatefulWidget {
  const QrVerifyPage({super.key});

  @override
  State<QrVerifyPage> createState() => _QrVerifyPageState();
}

class _QrVerifyPageState extends State<QrVerifyPage> {
  bool scanned = false;
  bool loading = false;
  Map<String, dynamic>? result;

  Future<void> verifyDocument(String url) async {
    if (scanned) return;

    setState(() {
      scanned = true;
      loading = true;
      result = null;
    });

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      setState(() {
        result = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        result = {
          'success': false,
          'valid': false,
          'message': 'Erreur vérification document',
        };
      });
    }
  }

  void resetScan() {
    setState(() {
      scanned = false;
      loading = false;
      result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isValid = result?['valid'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérifier document'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(
              onDetect: (capture) {
                final barcode = capture.barcodes.first;
                final value = barcode.rawValue;

                if (value != null) {
                  verifyDocument(value);
                }
              },
            ),
          ),

          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : result == null
                      ? const Center(
                          child: Text(
                            'Scannez le QR code du document FG Santé',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isValid
                                  ? Icons.verified
                                  : Icons.error_outline,
                              color: isValid ? Colors.green : Colors.red,
                              size: 55,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isValid
                                  ? 'Document authentique FG Santé'
                                  : 'Document invalide',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isValid ? Colors.green : Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              result?['message'] ?? '',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: resetScan,
                              child: const Text('Scanner un autre document'),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}