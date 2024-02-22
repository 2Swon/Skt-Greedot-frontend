import 'package:flutter/material.dart';
import './settingColor.dart';

class EleButton_greedot extends StatelessWidget {
  final Widget Function()? gotoScene;
  final Color textColor, bgColor;
  final double width, height, fontSize;
  final EdgeInsetsGeometry padding;
  final String buttonText;
  final void Function()? additionalFunc; // nullable
  final IconData? icon; // 아이콘 추가
  final bool isSmall;

  const EleButton_greedot({
    this.width = 125,
    this.height = 45,
    this.bgColor = colorBut_greedot,
    this.textColor = Colors.white,
    required this.buttonText,
    this.fontSize = 16.0,
    this.gotoScene,
    this.padding = const EdgeInsets.symmetric(vertical: 0.2, horizontal: 0.3),
    this.additionalFunc, // nullable
    this.isSmall = false,
    this.icon, // 아이콘 추가
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = isSmall ? 70 : width;
    final double buttonHeight = isSmall ? 15 : height;
    final double buttonFontSize = isSmall ? 11.0 : fontSize;
    final EdgeInsetsGeometry buttonPadding = isSmall ? EdgeInsets.zero : padding;

    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(bgColor),
        minimumSize: MaterialStateProperty.all(Size(buttonWidth, buttonHeight)),
        padding: MaterialStateProperty.all(buttonPadding),
        textStyle: MaterialStateProperty.all(TextStyle(fontSize: buttonFontSize,fontFamily:'greedot_font')),
      ),
      onPressed: () {
        additionalFunc?.call(); // additionalFunc 호출 방식 간소화
        if (gotoScene != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => gotoScene!()));
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, color: Colors.white, size: 24), // 아이콘 색상을 흰색으로 설정
          if (icon != null) SizedBox(width: 8), // 아이콘과 텍스트 사이에 공간 추가
          Text(buttonText, style: TextStyle(color: textColor, fontSize: buttonFontSize,fontFamily:'greedot_font')),
        ],
      ),
    );
  }
}