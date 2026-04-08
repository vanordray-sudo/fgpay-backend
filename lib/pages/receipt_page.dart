import 'package:flutter/material.dart';
import '../services/pdf_service.dart';

class ReceiptPage extends StatelessWidget {
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final double amount;
  final String reference;
  final String date;


  // ✅ nouvo chan yo
  final String transactionType;
  final String description;
  final String senderNif;
  final String senderAddress;

  const ReceiptPage({
    super.key,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.amount,
    required this.reference,
    required this.date,
    required this.senderNif,
    required this.senderAddress,
    this.transactionType = 'transfer',
    this.description = '',
  });

  String safeValue(String? value, {String fallback = 'N/A'}) {
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }
    return value.trim();
  }

  String formatDate(String rawDate) {
    if (rawDate.trim().isEmpty) {
      return 'N/A';
    }

    try {
      final parsed = DateTime.parse(rawDate).toLocal();

      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      final year = parsed.year.toString();
      final hour = parsed.hour.toString().padLeft(2, '0');
      final minute = parsed.minute.toString().padLeft(2, '0');

      return '$day/$month/$year à $hour:$minute';
    } catch (_) {
      return rawDate;
    }
  }

  String get receiptTitle {
    if (transactionType == 'payment') {
      return 'Paiement réussi';
    }
    return 'Transfert réussi';
  }

  String get sectionTitle {
    if (transactionType == 'payment') {
      return 'Informations du paiement';
    }
    return 'Informations du transfert';
  }

  String get receiverLabel {
    if (transactionType == 'payment') {
      return 'Service / Marchand';
    }
    return 'Destinataire';
  }

  IconData get headerIcon {
    if (transactionType == 'payment') {
      return Icons.payment;
    }
    return Icons.check_circle;
  }

Widget _buildRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 15,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value.isEmpty ? 'N/A' : value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D6EFD),
          ),
        ),
      ),
    );
  }

  Widget buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EE),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Text(
        'Complété',
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> handlePrint(BuildContext context) async {
    try {
      await PdfService.printReceipt(
        senderName: safeValue(senderName),
        senderPhone: safeValue(senderPhone),
        receiverName: safeValue(receiverName),
        receiverPhone: safeValue(receiverPhone),
        amount: amount,
        reference: safeValue(reference),
        date: formatDate(date),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur PDF: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = formatDate(date);
    final safeReference = safeValue(reference);
    final safeSenderName = safeValue(senderName);
    final safeSenderPhone = safeValue(senderPhone);
    final safeReceiverName = safeValue(receiverName);
    final safeReceiverPhone = safeValue(receiverPhone);
    final safeDescription = safeValue(description, fallback: '-');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('FGPay Receipt'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 18,
                    spreadRadius: 2,
                    offset: Offset(0, 8),
                    color: Color.fromRGBO(0, 0, 0, 0.08),
                  ),
                ],
              ),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 22,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0D6EFD),
                              Color(0xFF3FA2FF),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 74,
                              height: 74,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                headerIcon,
                                size: 46,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'FGPay',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Digital Transaction Receipt',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              receiptTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${amount.toStringAsFixed(2)} HTG',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FBFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD7E8FF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Transaction Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Référence: $safeReference',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      buildSectionTitle(sectionTitle),
                      const Divider(height: 1),
                      buildInfoRow('Expéditeur', safeSenderName),
                       _buildRow('NIF expéditeur', senderNif),
                       _buildRow('Adresse expéditeur', senderAddress),
                      buildInfoRow('Téléphone expéditeur', safeSenderPhone),
                      buildInfoRow(receiverLabel, safeReceiverName),

                      if (transactionType != 'payment')
                        buildInfoRow(
                          'Téléphone destinataire',
                          safeReceiverPhone,
                        ),

                      if (transactionType == 'payment')
                        buildInfoRow('Description', safeDescription),

                      buildInfoRow('Référence', safeReference),
                      buildInfoRow('Date', formattedDate),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 4,
                              child: Text(
                                'Statut',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: buildStatusBadge(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 28),
                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => handlePrint(context),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text(
                            'Télécharger / Imprimer PDF',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6EFD),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.home),
                          label: const Text(
                            'Retour au dashboard',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Color(0xFFD0D7E2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),
                      const Divider(),
                      const SizedBox(height: 10),

                      const Text(
                        'FGPay — Digital Payments for Haiti',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Receipt generated successfully',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}