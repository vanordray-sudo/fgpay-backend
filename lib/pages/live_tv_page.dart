import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LiveTVPage extends StatefulWidget {
  const LiveTVPage({super.key});

  @override
  State<LiveTVPage> createState() => _LiveTVPageState();
}

class _LiveTVPageState extends State<LiveTVPage> {
  final String streamUrl = 'http://82.165.129.168/hls/live.m3u8';
  final String _viewType = 'fgconnect-live-tv-player';
  final String _videoId = 'fgconnect-live-tv-video';

  late final html.VideoElement _videoElement;
  bool _isReady = false;
  bool _factoryRegistered = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setupPlayer();
  }

  void _setupPlayer() {
    try {
      _videoElement = html.VideoElement()
        ..id = _videoId
        ..controls = true
        ..autoplay = true
        ..muted = false
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = 'black';

      if (!_factoryRegistered) {
        ui_web.platformViewRegistry.registerViewFactory(
          _viewType,
          (int id) => _videoElement,
        );
        _factoryRegistered = true;
      }

      Future.delayed(const Duration(milliseconds: 300), _startHls);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur player: $e';
      });
    }
  }

  Future<void> _startHls() async {
    try {
      if (!mounted) return;

      setState(() {
        _isReady = false;
        _errorMessage = '';
      });

      final hasInitFunction = js_util.hasProperty(html.window, 'initHlsPlayer');

      if (!hasInitFunction) {
        throw Exception(
          'Fonksyon initHlsPlayer pa jwenn. Verifye web/index.html.',
        );
      }

      js_util.callMethod(html.window, 'initHlsPlayer', [_videoId, streamUrl]);

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final video =
          html.document.getElementById(_videoId) as html.VideoElement?;

      if (video == null) {
        throw Exception('Video element pa jwenn');
      }

      final hasSource =
          video.currentSrc.isNotEmpty || video.src.isNotEmpty;

      if (!hasSource) {
        throw Exception('Stream pa t atache sou video a');
      }

      setState(() {
        _isReady = true;
        _errorMessage = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isReady = false;
        _errorMessage = 'Erreur HLS: $e';
      });
    }
  }

  @override
  void dispose() {
    try {
      if (js_util.hasProperty(html.window, 'disposeHlsPlayer')) {
        js_util.callMethod(html.window, 'disposeHlsPlayer', [_videoId]);
      }
    } catch (_) {}

    _videoElement.pause();
    _videoElement.removeAttribute('src');
    _videoElement.load();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(
          child: Text('Paj sa fèt pou Web.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('LIVE TV'),
        actions: [
          IconButton(
            onPressed: _startHls,
            icon: const Icon(Icons.refresh),
            tooltip: 'Réessayer',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    HtmlElementView(viewType: _viewType),
                    if (!_isReady && _errorMessage.isEmpty)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}