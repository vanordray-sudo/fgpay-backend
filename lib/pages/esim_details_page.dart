import 'package:flutter/material.dart';
import '../services/esim_service.dart';

class EsimDetailsPage extends StatefulWidget {
  final int lineId;

  const EsimDetailsPage({
    super.key,
    required this.lineId,
  });

  @override
  State<EsimDetailsPage> createState() => _EsimDetailsPageState();
}

class _EsimDetailsPageState extends State<EsimDetailsPage> {
  final EsimService _esimService = EsimService();

  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic>? line;

  @override
  void initState() {
    super.initState();
    loadLine();
  }

  Future<void> loadLine() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await _esimService.fetchLine(widget.lineId);

      if (!mounted) return;

      setState(() {
        line = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildInfoBox(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLine = line;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails eSIM'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : currentLine == null
                  ? const Center(
                      child: Text('Aucune donnée eSIM trouvée.'),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          (currentLine['plan_name'] ?? 'eSIM').toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (currentLine['country'] ?? '').toString(),
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        if ((currentLine['qr_code_url'] ?? '')
                            .toString()
                            .isNotEmpty)
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                currentLine['qr_code_url'].toString(),
                                height: 240,
                                width: 240,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return const Text(
                                    'Impossible de charger le QR code',
                                  );
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        buildInfoBox(
                          'Activation Code',
                          (currentLine['activation_code'] ?? '').toString(),
                        ),
                        buildInfoBox(
                          'Manual Code',
                          (currentLine['manual_code'] ?? '').toString(),
                        ),
                        buildInfoBox(
                          'SMDP Address',
                          (currentLine['smdp_address'] ?? '').toString(),
                        ),
                        buildInfoBox(
                          'ICCID',
                          (currentLine['provider_iccid'] ?? '').toString(),
                        ),
                        buildInfoBox(
                          'Status',
                          (currentLine['status'] ?? '').toString(),
                        ),
                        buildInfoBox(
                          'Data',
                          (currentLine['data_label'] ?? '').toString(),
                        ),
                        buildInfoBox(
                          'Validité',
                          '${(currentLine['validity_days'] ?? '').toString()} jours',
                        ),
                      ],
                    ),
    );
  }
}