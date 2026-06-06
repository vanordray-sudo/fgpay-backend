import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/channel_model.dart';

class ChannelService {
  static Future<List<ChannelModel>> fetchChannels() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:5000/api/channels'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['channels'];

        return list.map<ChannelModel>((e) {
          return ChannelModel(
            id: e['id'].toString(),
            name: e['name'] ?? '',
            category: e['category'] ?? '',
            streamUrl: e['stream_url'] ?? '',
            logoUrl: e['logo_url'] ?? '',
            isLive: e['is_live'] ?? true,
            isFree: e['is_free'] ?? false,
          );
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching channels: $e');
      return [];
    }
  }
}