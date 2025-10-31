import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

class OmnibusSlideshow extends StatefulWidget {
  const OmnibusSlideshow({super.key});

  @override
  State<OmnibusSlideshow> createState() => _OmnibusSlideshowState();
}

class _OmnibusSlideshowState extends State<OmnibusSlideshow> {
  final PageController _controller = PageController();
  Timer? _timer;
  List<String> _images = const [];
  int _page = 0;

  int get _pageCount => (_images.length + 1) ~/ 2;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    try {
      final manifestContent = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = jsonDecode(manifestContent) as Map<String, dynamic>;
      final images = manifestMap.keys
          .where((k) => k.startsWith('assets/images/omnibus/'))
          .where((k) => k.toLowerCase().endsWith('.png') || k.toLowerCase().endsWith('.jpg') || k.toLowerCase().endsWith('.jpeg') || k.toLowerCase().endsWith('.webp'))
          .toList()
        ..sort();
      if (!mounted) return;
      setState(() => _images = images);
      _startTimer();
    } catch (_) {
      if (mounted) setState(() => _images = const []);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_pageCount == 0) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients || _pageCount == 0) return;
      final next = (_page + 1) % _pageCount;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 140,
        child: GestureDetector(
          onTap: () {
            final startImageIndex = (_page * 2).clamp(0, _images.isEmpty ? 0 : _images.length - 1);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _OmnibusReaderScreen2(images: _images, initialIndex: startImageIndex),
              ),
            );
          },
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: _pageCount,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final start = index * 2;
                  final slice = _images.skip(start).take(2).toList();
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(2, (i) => i).map((i) {
                      final hasImage = i < slice.length;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.zero,
                          color: Colors.transparent,
                          child: hasImage
                              ? Image.asset(
                                  slice[i],
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                  errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported)),
                                )
                              : const SizedBox.shrink(),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pageCount, (i) => i)
                      .map((i) => Container(
                            width: _page == i ? 12 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: _page == i ? const Color(0xFF6E63F6) : Colors.white70,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OmnibusReaderScreen2 extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _OmnibusReaderScreen2({required this.images, required this.initialIndex});
  @override
  State<_OmnibusReaderScreen2> createState() => _OmnibusReaderScreen2State();
}

class _OmnibusReaderScreen2State extends State<_OmnibusReaderScreen2> {
  late final PageController _controller;
  final TransformationController _ivController = TransformationController();

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ivController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Omnibus'),
      ),
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (_) => _ivController.value = Matrix4.identity(),
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          final path = widget.images[index];
          return Center(
            child: InteractiveViewer(
              transformationController: _ivController,
              minScale: 0.8,
              maxScale: 5.0,
              clipBehavior: Clip.hardEdge,
              child: Image.asset(
                path,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
