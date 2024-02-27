import 'dart:async';
import 'package:flutter/material.dart';

class LoadingGifWidget extends StatefulWidget {
  @override
  _LoadingGifWidgetState createState() => _LoadingGifWidgetState();
}

class _LoadingGifWidgetState extends State<LoadingGifWidget> {
  List<String> gifPaths = [
    'assets/images/loading_gif/dab1.gif',
    'assets/images/loading_gif/dab2.gif',
    'assets/images/loading_gif/dab3.gif',
    'assets/images/loading_gif/dab4.gif',
    'assets/images/loading_gif/dab5.gif',
  ];
  int currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 9), (timer) {
      setState(() {
        currentIndex = (currentIndex + 1) % gifPaths.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        gifPaths[currentIndex],
        width: 400, // 이미지의 너비를 설정합니다.
        height: 400, // 이미지의 높이를 설정합니다.
        fit: BoxFit.cover, // 이미지가 할당된 공간을 꽉 채우도록 설정합니다.
      ),
    );
  }
}
