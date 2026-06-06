import '../models/channel_model.dart';


final List<ChannelModel> demoChannels = [
  ChannelModel(
    id: '1',
    name: 'FG MUSIC',
    category: 'Music',
    streamUrl: 'http://82.165.129.168/hls/live.m3u8',
    logoUrl: 'https://via.placeholder.com/80x80.png?text=FG',
    isLive: true,
    isFree: true,
  ),
  ChannelModel(
    id: '2',
    name: 'ARTE Demo',
    category: 'Culture',
    streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
    logoUrl: 'https://via.placeholder.com/80x80.png?text=ARTE',
    isLive: true,
    isFree: true,
  ),
  ChannelModel(
    id: '3',
    name: 'Sport Demo',
    category: 'Sport',
    streamUrl: 'https://test-streams.mux.dev/test_001/stream.m3u8',
    logoUrl: 'https://via.placeholder.com/80x80.png?text=SPORT',
    isLive: true,
    isFree: true,
  ),
  ChannelModel(
    id: '4',
    name: 'News Demo',
    category: 'News',
    streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
    logoUrl: 'https://via.placeholder.com/80x80.png?text=NEWS',
    isLive: true,
    isFree: true,
  ),
];