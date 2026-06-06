import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyQrPage extends StatelessWidget {
  const MyQrPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 Egzanp QR (ou ka mete userId pita)
    final qrData = 'merchant:FGPAY_USER|amount:0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon QR Pay'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                blurRadius: 6,
                offset: Offset(0, 2),
                color: Color(0x14000000),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scanner pou peye',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'FGPay Merchant',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: qrData,
                size: 200,
              ),
            ],
          ),
        ),
      ),
    );
  }
}