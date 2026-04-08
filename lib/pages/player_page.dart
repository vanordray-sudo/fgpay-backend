import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class PlayerPage extends StatefulWidget {
  final String title;
  final String url;

  const PlayerPage({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final String _viewType;
  late final html.DivElement _container;
  late final html.VideoElement _videoElement;

  bool _isReady = false;
  bool _hasError = false;
  String _errorMessage = 'Chargement du flux...';

  @override
  void initState() {
    super.initState();

    _viewType = 'fg-hls-player-${DateTime.now().millisecondsSinceEpoch}';

    _videoElement = html.VideoElement()
      ..controls = true
      ..autoplay = true
      ..muted = false
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'black'
      ..style.objectFit = 'contain';

    _videoElement.setAttribute('playsinline', 'true');

    _container = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'black'
      ..children.add(_videoElement);

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _container,
    );

    _videoElement.onLoadedMetadata.listen((_) {
      if (!mounted) return;
      setState(() {
        _isReady = true;
        _hasError = false;
        _errorMessage = '';
      });
    });

    _videoElement.onPlaying.listen((_) {
      if (!mounted) return;
      setState(() {
        _isReady = true;
        _hasError = false;
        _errorMessage = '';
      });
    });

    _videoElement.onError.listen((_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Impossible de lire ce flux.';
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachStream();
    });
  }

  void _attachStream() {
    try {
      final dynamic hlsClass = js.context['Hls'];

      if (hlsClass != null && js.context.callMethod('eval', ['Hls.isSupported()']) == true) {
        final dynamic hls = js.JsObject(hlsClass, [
          js.JsObject.jsify({
            'enableWorker': true,
            'lowLatencyMode': false,
            'backBufferLength': 90,
          })
        ]);

        hls.callMethod('loadSource', [widget.url]);
        hls.callMethod('attachMedia', [_videoElement]);
      } else {
        _videoElement.src = widget.url;
        _videoElement.load();
        _videoElement.play();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Erreur player: $e';
      });
    }
  }

  void _reloadStream() {
    setState(() {
      _isReady = false;
      _hasError = false;
      _errorMessage = 'Rechargement du flux...';
    });

    try {
      _videoElement.pause();
      _videoElement.removeAttribute('src');
      _videoElement.load();
    } catch (_) {}

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _attachStream();
    });
  }

  @override
  void dispose() {
    try {
      _videoElement.pause();
      _videoElement.removeAttribute('src');
      _videoElement.load();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: HtmlElementView(viewType: _viewType),
          ),
          if (!_isReady || _hasError)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _reloadStream,
                      child: const Text('Recharger'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}