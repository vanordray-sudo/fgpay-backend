import 'package:flutter/material.dart';
import '../pages/player_page.dart';
import '../pages/subscription_page.dart';

class IptvPage extends StatefulWidget {
  const IptvPage({super.key});

  @override
  State<IptvPage> createState() => _IptvPageState();
}

class _IptvPageState extends State<IptvPage> {
  bool isSubscribed = true; // mete false pou teste paj souscription an

  final List<Map<String, dynamic>> channels = [
    {
      'name': 'FG Sports',
      'category': 'Sports',
      'status': 'Live',
      'icon': Icons.sports_soccer,
      'url': 'http://85.215.59.98/channel1/index.m3u8',
      'enabled': true,
    },
    {
      'name': 'FG News Live',
      'category': 'News',
      'status': 'Live',
      'icon': Icons.newspaper,
      'url': 'http://85.215.59.98/channel1/index.m3u8',
      'enabled': true,
    },
    {
      'name': 'FG Music Live',
      'category': 'Music',
      'status': 'Live',
      'icon': Icons.music_note,
      'url': 'http://85.215.59.98/channel1/index.m3u8',
      'enabled': true,
    },
    {
      'name': 'FG Culture Live',
      'category': 'Culture',
      'status': 'Live',
      'icon': Icons.tv,
      'url': 'http://85.215.59.98/channel1/index.m3u8',
      'enabled': true,
    },
    {
      'name': 'FG Movies',
      'category': 'Entertainment',
      'status': 'Soon',
      'icon': Icons.movie,
      'url': '',
      'enabled': false,
    },
    {
      'name': 'FG Kids',
      'category': 'Kids',
      'status': 'Soon',
      'icon': Icons.child_care,
      'url': '',
      'enabled': false,
    },
  ];

  String selectedCategory = 'All';

  List<Map<String, dynamic>> get filteredChannels {
    if (selectedCategory == 'All') return channels;
    return channels
        .where((channel) => channel['category'] == selectedCategory)
        .toList();
  }

  Widget _buildCategoryChip(String label) {
    final bool isSelected = selectedCategory == label;

    return InkWell(
      onTap: () {
        setState(() {
          selectedCategory = label;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildChannelCard(Map<String, dynamic> channel) {
    final String status = (channel['status'] ?? 'Soon').toString();
    final bool isLive = status == 'Live';
    final bool isOffline = status == 'Offline';
    final bool isEnabled = channel['enabled'] == true;
    final String streamUrl = (channel['url'] ?? '').toString();

    Color statusBg;
    Color statusColor;
    String buttonLabel;

    if (isLive) {
      statusBg = const Color(0xFFFFEAEA);
      statusColor = Colors.red;
      buttonLabel = 'Watch';
    } else if (isOffline) {
      statusBg = const Color(0xFFEDEDED);
      statusColor = Colors.black54;
      buttonLabel = 'Offline';
    } else {
      statusBg = const Color(0xFFEAF7EE);
      statusColor = Colors.green;
      buttonLabel = 'Soon';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              channel['icon'],
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
                  channel['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  channel['category'],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  // 1. CHECK ABONNEMENT
                  if (!isSubscribed) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionPage(),
                      ),
                    );

                    if (result == true) {
                      setState(() {
                        isSubscribed = true;
                      });
                    }

                    return;
                  }

                  // 2. CHECK CHANNEL DISPONIBLE
                  if (!isEnabled || streamUrl.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${channel['name']} coming soon'),
                      ),
                    );
                    return;
                  }

                  // 3. LANCE PLAYER
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerPage(
                        title: channel['name'],
                        url: streamUrl,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLive ? Colors.blue : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(buttonLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'IPTV',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'FG IPTV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Watch live TV, sports, music and entertainment from one place.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildCategoryChip('All'),
                _buildCategoryChip('Sports'),
                _buildCategoryChip('Entertainment'),
                _buildCategoryChip('News'),
                _buildCategoryChip('Music'),
                _buildCategoryChip('Kids'),
                _buildCategoryChip('Culture'),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Channels',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...filteredChannels.map(_buildChannelCard),
          ],
        ),
      ),
    );
  }
}