import 'package:flutter/material.dart';
import '../models/internet_plan_model.dart';
import '../services/internet_service.dart';

class InternetPage extends StatefulWidget {
  const InternetPage({super.key});

  @override
  State<InternetPage> createState() => _InternetPageState();
}

class _InternetPageState extends State<InternetPage> {
  final InternetService _internetService = InternetService();

  bool _isLoading = true;
  bool _isBuying = false;
  List<InternetPlan> _plans = [];
  Map<String, dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final plans = await _internetService.fetchPlans();
      final sub = await _internetService.fetchMySubscription();

      if (!mounted) return;
      setState(() {
        _plans = plans;
        _subscription = sub;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _buyPlan(InternetPlan plan) async {
    setState(() => _isBuying = true);

    try {
      final result = await _internetService.buyPlan(plan.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Plan acheté avec succès')),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur achat: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBuying = false);
      }
    }
  }

  Widget _buildSubscriptionCard() {
    if (_subscription == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Ou poko gen plan internet aktif.'),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _subscription!['plan_name'] ?? 'Plan actif',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Go total: ${_subscription!['data_allocated_gb']} Go'),
            Text('Go itilize: ${_subscription!['data_used_gb']} Go'),
            Text('Go rete: ${_subscription!['data_remaining_gb']} Go'),
            Text('Vitès: ${_subscription!['speed_limit_mbps']} Mbps'),
            Text('Ekspire: ${_subscription!['expiry_date']}'),
            Text('Status: ${_subscription!['status']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(InternetPlan plan) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              plan.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('${plan.dataLimitGb} Go'),
            Text('${plan.speedLimitMbps} Mbps'),
            Text('${plan.validityDays} jou'),
            const SizedBox(height: 8),
            Text(
              '\$${plan.price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isBuying ? null : () => _buyPlan(plan),
              child: const Text('Acheter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FGCONNECT Internet'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Mon abonnement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildSubscriptionCard(),
                  const SizedBox(height: 20),
                  const Text(
                    'Plans disponibles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._plans.map(_buildPlanCard),
                ],
              ),
            ),
    );
  }
}