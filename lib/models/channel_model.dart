class ChannelModel {
  final String id;
  final String name;
  final String category;
  final String streamUrl;
  final String logoUrl;
  final bool isLive;
  final bool isFree;

  ChannelModel({
    required this.id,
    required this.name,
    required this.category,
    required this.streamUrl,
    required this.logoUrl,
    required this.isLive,
    required this.isFree,
  });
}