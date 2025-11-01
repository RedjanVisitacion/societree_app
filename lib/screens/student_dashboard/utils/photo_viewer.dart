import 'package:flutter/material.dart';

void openPhoto(BuildContext context, String url) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(
                Icons.broken_image,
                color: Colors.white70,
                size: 56,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
