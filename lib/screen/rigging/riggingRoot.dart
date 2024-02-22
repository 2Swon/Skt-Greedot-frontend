import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flip_card/flip_card.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:projectfront/widget/design/basicButtons.dart';
import '../../widget/design/settingColor.dart';
import '../../provider/pageNavi.dart';
import '../../models/gree_model.dart';
import '../../service/gree_service.dart';
import '../gree/keepItem.dart';
import '../gree/addFavorite.dart';
import '../rigging/drawSkeleton.dart';
import '../../screen/user/AdminPage.dart';
import '../gree/addFavorite.dart';
import '../emotionReport/reportPage.dart';

import '../../screen/user/ViewProfile.dart';
class RiggingRoot extends StatefulWidget {
  const RiggingRoot({Key? key}) : super(key: key);

  @override
  _RiggingRootState createState() => _RiggingRootState();
}

class _RiggingRootState extends State<RiggingRoot> {
  int activeIndex = 0;
  List<Gree> _grees = [];
  List<String?> _greeGifs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGreesAndGifs();
  }

  Future<void> _loadGreesAndGifs() async {
    // Gree 객체들을 로드하고, 각 객체에 대한 GIF URL을 가져옵니다.
    try {
      List<Gree> grees = await ApiServiceGree.readGrees();
      // 각 Gree 객체에 대한 GIF URL을 비동기적으로 가져옵니다.
      List<String?> greeGifs = await Future.wait(grees.map((gree) async {
        return await ApiServiceGree.fetchSpecificGreeGif(gree.id!);
      }));

      if (mounted) {
        setState(() {
          _grees = grees;
          _greeGifs = greeGifs;
          _isLoading = false;
        });
      }
    } catch (e) {
      // 오류 처리
      print("Error loading Gree data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageNavi = Provider.of<PageNavi>(context, listen: false);
    Size screenSize = MediaQuery.of(context).size;

    return Container(
        width: screenSize.width,
        height: screenSize.height,
        color: colorMainBG_greedot,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Stack(
          children: <Widget>[
            CarouselSlider(
              items: _grees.asMap().entries.map((entry) {
                int idx = entry.key;
                Gree gree = entry.value;
                String? gifUrl = _greeGifs[idx];
                return gifUrl == null
                    ? Text("No 'dab' GIF found")
                    : FlipCard(
                  front: Image.network(gifUrl, fit: BoxFit.cover),
                  back: buildCardBack(gree, context),
                );
              }).toList(),
              options: CarouselOptions(
                height: 600,
                viewportFraction: 0.33,
                autoPlay: true,
                onPageChanged: (index, reason) {
                  setState(() {
                    activeIndex = index;
                  });
                },
              ),
            ),
            Positioned(
              bottom: 200,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSmoothIndicator(
                  activeIndex: activeIndex,
                  count: _grees.length,
                  effect: SlideEffect(
                    dotHeight: 6,
                    dotWidth: 6,
                    dotColor: Colors.black26,
                    activeDotColor: Colors.white,
                  ),
                ),
              ),
            ),
            const Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Text(
                  "캐릭터를 터치하면 캐릭터 정보가 보여요!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorSnackBar_greedot, fontSize: 15, fontFamily:'greedot_font')
              ),
            ),
            Positioned(
              bottom: 60,
              left: 0,
              right: 0, // 이 부분을 수정하여 버튼을 화면 중앙에 배치
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 35),
                  EleButton_greedot(
                    width: 190,
                    height: 50,
                    additionalFunc: () => pageNavi.changePage('newgree'),
                    buttonText: "그리 새로 만들기",
                    icon: Icons.create, // 아이콘 지정
                  ),
                ],
              ),
            ),
          ],
        )
    );
  }

}


Widget buildCardBack(Gree gree, BuildContext context) {
  // 자기소개 텍스트 생성
  String introduction = "안녕하세요, ${gree.gree_name ?? '이름없음'}이야. "
      "나는 ${gree.prompt_age ?? '나이'}살, ${gree.prompt_gender ?? '성별'} 아이야. "
      "MBTI는 ${gree.prompt_mbti ?? 'MBTI'} 임!!! 나랑 대화를 원한다면 언제든지 찾아와!!";

  return Center(
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      color: Color(0xFF527853), // 배경색 설정
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            buildInfoRow(context, Icons.person_outline, '이름: ${gree.gree_name ?? '없음'}'),
            buildInfoSpacer(),
            buildInfoRow(context, Icons.transgender, '성별: ${gree.prompt_gender ?? '없음'}'),
            buildInfoSpacer(),
            buildInfoRow(context, Icons.cake, '나이: ${gree.prompt_age ?? '없음'}'),
            buildInfoSpacer(),
            buildInfoRow(context, Icons.psychology, '성격: ${gree.prompt_mbti ?? '없음'}'),
            buildInfoSpacer(),
            Text(introduction, // 자기소개 부분
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Color(0xFFFFFFFF),fontFamily:'greedot_font'),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}

Widget buildInfoRow(BuildContext context, IconData icon, String text) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Color(0xFFFFFFFF), size: 20), // 아이콘 색상 변경
      SizedBox(width: 10),
      Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: Color(0xFFFFFFFF),fontFamily:'greedot_font')), // 글씨체 얇게 변경
    ],
  );
}

Widget buildInfoSpacer() => SizedBox(height: 12);
