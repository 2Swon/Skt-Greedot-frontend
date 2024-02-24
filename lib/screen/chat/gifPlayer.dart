import 'package:flutter/material.dart';

class GifPlayer extends StatefulWidget {
  final String gifUrl;
  final double width;
  final double height;

  const GifPlayer({
    Key? key,
    required this.gifUrl,
    required this.width,
    required this.height,
    required BoxFit fit,
  }) : super(key: key);

  @override
  _GifPlayerState createState() => _GifPlayerState();
}

class _GifPlayerState extends State<GifPlayer> {
  @override
  Widget build(BuildContext context) {
    return Image.network(
      widget.gifUrl,
      width: widget.width,
      height: widget.height,
      // 이것은 GIF를 지속적으로 재생합니다.
      gaplessPlayback: true,
    );
  }
}