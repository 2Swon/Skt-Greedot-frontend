import 'dart:math';
import 'package:flutter/material.dart';
import '../../service/gree_service.dart';
import '../../widget/design/settingColor.dart';
import '../../models/gree_model.dart';
import 'package:projectfront/widget/design/basicButtons.dart';
import '../rigging/getImage.dart';
import '../../screen/root.dart';
import '../../provider/pageNavi.dart';
import 'package:provider/provider.dart';

class FavoriteItemCard extends StatefulWidget {
  final Gree gree;

  FavoriteItemCard({
    Key? key,
    required this.gree,
  }) : super(key: key);

  @override
  _FavoriteItemCardState createState() => _FavoriteItemCardState();
}

class _FavoriteItemCardState extends State<FavoriteItemCard> {
  Color? cardColor; // 카드의 배경색을 저장할 변수

  @override
  void initState() {
    super.initState();
    cardColor = getRandomPastelColor(); // 카드의 배경색을 랜덤하게 설정
  }

  // 랜덤 파스텔 색상을 생성하는 함수
  Color getRandomPastelColor() {
    Random random = Random();
    int r = random.nextInt(56) + 175;
    int g = random.nextInt(56) + 175;
    int b = random.nextInt(56) + 175;
    return Color.fromRGBO(r, g, b, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final pageNavi = Provider.of<PageNavi>(context, listen: false);
    return Scaffold(
      backgroundColor: colorNaviBar_greedot,
      body: SingleChildScrollView(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: cardColor,
          margin: EdgeInsets.all(10), // 필요한 경우 마진 조정
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.gree.gree_name ?? 'Unknown',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.gree.prompt_mbti ?? 'Unknown',
                        style: TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      EleButton_greedot(
                        isSmall: false,
                        buttonText: "대화 시작",
                        fontSize: 16,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        width: 170,
                        height: 50,
                        additionalFunc: () => pageNavi.changePage('ChatPage', data: PageData(greeId: widget.gree.id)),
                        icon: Icons.chat, // '대화 시작' 버튼에 대화 아이콘 추가
                      ),
                      SizedBox(height: 4),
                      EleButton_greedot(
                        isSmall: false,
                        buttonText: "리포트 보기",
                        fontSize: 16,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        width: 170,
                        height: 50,
                        additionalFunc: () => pageNavi.changePage('ReportPage', data: PageData(greeId: widget.gree.id)),
                        icon: Icons.assessment, // '리포트 보기' 버튼에 리포트 아이콘 추가
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 6, // GIF 이미지를 위한 공간 비율
                child: FutureBuilder<String?>(
                  future: ApiServiceGree.fetchSpecificGreeGif(widget.gree.id ?? 0),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError || !snapshot.hasData) {
                      String errorMessage = "Error fetching GIFs";
                      if (snapshot.hasError) {
                        errorMessage += ": ${snapshot.error}";
                      } else if (!snapshot.hasData) {
                        errorMessage = "No GIF found";
                      }
                      return Center(child: Text(errorMessage));
                    } else {
                      return ClipRRect(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                        child: Image.network(snapshot.data!, fit: BoxFit.cover),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
