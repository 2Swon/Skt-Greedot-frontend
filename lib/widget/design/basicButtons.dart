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

    // 버튼 디자인을 위한 색상과 그림자 효과 정의
    const Color buttonColor = colorBut_greedot; // 예시 색상
    const double elevation = 8.0; // 그림자 높이
    final Color shadowColor = Colors.black.withOpacity(0.5); // 그림자 색상


    final double buttonWidth = isSmall ? 70 : width;
    final double buttonHeight = isSmall ? 15 : height;
    final double buttonFontSize = isSmall ? 11.0 : fontSize;
    final EdgeInsetsGeometry buttonPadding = isSmall ? EdgeInsets.zero : padding;


    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(bgColor),
        minimumSize: MaterialStateProperty.all(Size(buttonWidth, buttonHeight)),
        padding: MaterialStateProperty.all(buttonPadding),
        textStyle: MaterialStateProperty.all(TextStyle(fontSize: buttonFontSize, fontFamily: 'greedot_font')),
        elevation: MaterialStateProperty.all(elevation), // 그림자 높이 설정
        shadowColor: MaterialStateProperty.all(shadowColor), // 그림자 색상 설정
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // 모서리 둥글기 설정
          ),
        ),
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
          if (icon != null) Icon(icon, color: Colors.white, size: 24),
          if (icon != null) SizedBox(width: 8),
          Text(buttonText, style: TextStyle(color: textColor, fontSize: buttonFontSize, fontFamily: 'greedot_font')),
        ],
      ),
    );

  }
}