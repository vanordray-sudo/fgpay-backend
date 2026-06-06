import 'package:flutter/material.dart';
import '../services/esim_service.dart';
import 'esim_details_page.dart';

class MyEsimPage extends StatefulWidget {
  const MyEsimPage({super.key});

  @override
  State<MyEsimPage> createState() => _MyEsimPageState();
}

class _MyEsimPageState extends State<MyEsimPage> {
  final EsimService _esimService = EsimService();

  bool isLoading = true;
  String errorMessage = '';
  List<dynamic> lines = [];

  @override
  void initState() {
    super.initState();
    loadLines();
  }

  Future<void> loadLines() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await _esimService.fetchMyLines();

      if (!mounted) return;

      setState(() {
        lines = result;
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'ready':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  Widget buildLineCard(Map<String, dynamic> line) {
    final id = line['id'];
    final planName = (line['plan_name'] ?? 'eSIM').toString();
    final country = (line['country'] ?? '').toString();
    final dataLabel = (line['data_label'] ?? '').toString();
    final validityDays = (line['validity_days'] ?? '').toString();
    final status = (line['status'] ?? 'unknown').toString();
    final createdAt = (line['created_at'] ?? '').toString();
    final qrCodeUrl = (line['qr_code_url'] ?? '').toString();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF5FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.sim_card,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (country.isNotEmpty)
                        Text(
                          country,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _badge(dataLabel.isEmpty ? 'N/A' : dataLabel),
                          _badge('$validityDays jours'),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (createdAt.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Créée le: $createdAt',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ),
            if (qrCodeUrl.isNotEmpty) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    qrCodeUrl,
                    height: 110,
                    width: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EsimDetailsPage(
                        lineId: int.parse(id.toString()),
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Voir détails'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes eSIM'),
      ),
      body: RefreshIndicator(
        onRefresh: loadLines,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B6CFF), Color(0xFF2D9CDB)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mes lignes eSIM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Retrouvez vos eSIM actives, vos QR codes et vos détails d’activation.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (lines.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text('Ou poko achte okenn eSIM.'),
              )
            else
              ...lines.map((e) => buildLineCard(Map<String, dynamic>.from(e))),
          ],
        ),
      ),
    );
  }
}