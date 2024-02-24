import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widget/design/settingColor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../service/gree_service.dart';

import '../../widget/design/sharedController.dart';
import '../../provider/pageNavi.dart';
import '../../service/user_service.dart';
import 'package:provider/provider.dart';
import 'package:projectfront/widget/design/basicButtons.dart';
import '../../models/user_model.dart';

class ReportPage extends StatefulWidget {
  final int? greeId;
  const ReportPage({Key? key, this.greeId}) : super(key: key);
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int touchedIndex = -1;
  Map<String, List<String>> emotions = {}; // 초기 상태는 비어있음
  Map<String, String> urls = {};
  List<Map<String, dynamic>> dialogLogs = [];
  String summary = "";

  // @override
  // void initState() {
  //   super.initState();
  //   fetchEmotionData();
  //   fetchDialogLogs();
  //   fetchSummary();
  // }


  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    if (widget.greeId == null) {
      print('Gree ID is null');
      return;
    }
    try {
      await fetchEmotionData(); // Emotion Data를 먼저 가져온다.
      await fetchSummary(); // 그 다음 Summary 호출
      await fetchDialogLogs(); // 마지막으로 Dialog Logs 호출
    } catch (e) {
      print('Error during data fetching: $e');
    }
  }


  Future<void> fetchDialogLogs() async {
    if (widget.greeId == null) {
      print('Gree ID is null');
      return;
    }
    try {
      final logs = await ApiServiceGree.fetchDialogLogs(widget.greeId!);
      setState(() {
        dialogLogs = logs;
      });
    } catch (e) {
      print('Error fetching dialog logs: $e');
    }
  }


  Future<void> fetchEmotionData() async {
    try {
      List<String> sentences = await ApiServiceGree.fetchSentences(widget.greeId!);
      if (sentences.isEmpty) {
        throw Exception('No sentences returned');
      }

      var report = await ApiServiceGree.makeEmotionReport(sentences, widget.greeId!);
      if (report == null) {
        throw Exception('Report generation failed');
      }

      setState(() {
        emotions = report['emotions'].map((emotion, sentences) =>
            MapEntry(emotion, List<String>.from(sentences))).cast<String, List<String>>();
        urls = report['urls'].cast<String, String>();
      });
    } catch (e) {
      print('Error fetching data: $e');
      // 에러 처리 로직 (예: 상태 업데이트, 사용자에게 메시지 표시)
    }
  }


  Future<void> fetchSummary() async {
    if (widget.greeId == null) {
      print('Gree ID is null');
      return;
    }
    try {
      final response = await ApiServiceGree.fetchSummary(widget.greeId!); // gree_service.dart 파일에 해당 함수를 구현해야 함
      setState(() {
        summary = response;
      });
    } catch (e) {
      print('Error fetching summary: $e');
    }
  }

  final Map<String, Color> emotionColor = {
    '기쁨': Colors.orange[400]!,
    '당황': Colors.green[400]!,
    '분노': Colors.red[400]!,
    '불안': Colors.indigo[400]!,
    '상처': Colors.purple[400]!,
    '슬픔': Colors.blue[400]!,
  };

  Widget buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: emotionColor.keys.map((emotion) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: emotionColor[emotion],
                ),
              ),
              SizedBox(width: 2),
              Text(emotion),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<PieChartSectionData> showingSections() {
    int totalSentences = emotions.values.fold(0, (previous, element) => previous + element.length);
    if (totalSentences == 0) {
      // 데이터가 없을 때 기본 섹션 데이터를 반환
      return [PieChartSectionData(
        color: Colors.grey[500],
        value: 100,
        title: '대화를 분석 중입니다',
        radius: 60,
        titleStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      )];
    }

    List<PieChartSectionData> sections = [];
    emotions.forEach((key, sentences) {
      final bool isTouched = emotions.keys.toList().indexOf(key) == touchedIndex;
      final double fontSize = isTouched ? 16 : 14;
      final double radius = isTouched ? 90 : 70;
      final double percentage = sentences.length / totalSentences * 100;

      if (percentage > 0) {
        String titleText = isTouched ? '$key\n${percentage.toStringAsFixed(1)}%' : key;
        sections.add(PieChartSectionData(
          color: emotionColor[key],
          value: percentage,
          title: titleText,
          radius: radius,
          titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: const Color(0xffffffff)),
        ));
      }
    });

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          touchedIndex = -1;
        });
      },
      child: Scaffold(
        backgroundColor: colorMainBG_greedot,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text('< 차트를 클릭하면 대화 로그가 보여요! >', style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold)),
                ),
                Container(
                  height: MediaQuery.of(context).size.height / 2,
                  child: buildChartAndImageRow(),
                ),
                buildLegend(),
                if (touchedIndex != -1) //
                  buildScrollableEmotionSentences(emotions.keys.elementAt(touchedIndex)),
                SizedBox(height: 20),
                Row( // 여기에 변경사항을 적용합니다.
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 내부 요소들을 화면에 균등하게 분포시킵니다.
                  children: [
                    Expanded( // 첫 번째 컨테이너를 Expanded로 감싸 화면의 절반을 차지하도록 합니다.
                      child: Column(
                        children: <Widget>[
                          Text('< 전체 대화 로그 >', style: TextStyle(fontSize: 13.0,fontWeight: FontWeight.bold)),
                          buildScrollableDialogLog(),
                        ],
                      ),
                    ),
                    Expanded( // 두 번째 컨테이너도 Expanded로 감싸 화면의 나머지 절반을 차지하도록 합니다.
                      child: Column(
                        children: <Widget>[
                          Text('< 하루 대화 요약 >', style: TextStyle(fontSize: 13.0,fontWeight: FontWeight.bold)),
                          tempText(),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget buildChartAndImageRow() {
    return Container(
      height: MediaQuery.of(context).size.height / 3,
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    if (event is FlTapUpEvent && pieTouchResponse != null &&
                        pieTouchResponse.touchedSection != null) {
                      setState(() {
                        int currentIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        List<String> displayedEmotions = emotions.keys.where((key) => emotions[key]!.isNotEmpty).toList();
                        String touchedEmotion = displayedEmotions[currentIndex];
                        touchedIndex = emotions.keys.toList().indexOf(touchedEmotion);
                      });
                    }
                  },
                ),
                centerSpaceRadius: 60,
                sectionsSpace: 2,
                sections: showingSections(),
              ),
            ),
          ),
          if (touchedIndex != -1 && urls.isNotEmpty) // 이미지를 로드하는 조건을 확인합니다.
            Expanded(
              child: Image.network(
                urls[emotions.keys.elementAt(touchedIndex)] ?? '',
                width: 70.0,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // 로드 실패 시 콘솔에 에러 메시지 출력
                  print("Image load failed: $error");
                  // 대체 이미지 표시
                  return Image.asset('assets/images/gree.png', width: 70.0);
                },
              ),
            ),
        ],
      ),
    );
  }


  Widget buildScrollableEmotionSentences(String emotion) {
    List<String>? sentencesList = emotions[emotion];
    String allSentences = sentencesList != null ? sentencesList.join('\n\n') : 'No sentences found for this emotion.';
    double screenWidth = MediaQuery.of(context).size.width;
    double containerWidth = screenWidth - 20;
    return Container(
      width: containerWidth, // 여기에서 Container의 가로 길이를 설정합니다.
      margin: EdgeInsets.only(left: 10, right: 10),
      height: 200,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorFilling_greedot,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[400]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Text(
          allSentences,
          style: TextStyle(fontSize: 14.0, fontWeight:FontWeight.bold),
        ),
      ),
    );
  }

  Widget buildScrollableDialogLog() {
    // 대화 로그의 내용을 모두 결합하여 하나의 문자열로 만듭니다.
    String dialogText = dialogLogs.map((log) {
      return '${log['log_type'] == 'USER_TALK' ? 'User' : 'Gree'}: ${log['content']}';
    }).join('\n\n'); // 각 대화 로그 사이에 공백을 추가합니다.

    double screenWidth = MediaQuery.of(context).size.width;
    double containerWidth = screenWidth - 20;

    return Container(
      width: containerWidth/2, // 여기에서 Container의 가로 길이를 설정합니다.
      margin: EdgeInsets.only(left: 10, right: 10),
      height: 200,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorFilling_greedot,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[400]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Text(
          dialogText.isEmpty ? '대화 로그가 없습니다.' : dialogText, // 대화 로그가 비어있는 경우 대체 텍스트를 표시합니다.
          style: TextStyle(fontSize: 14.0, fontWeight:FontWeight.bold),
        ),
      ),
    );
  }

  Widget tempText() {
    double screenWidth = MediaQuery.of(context).size.width;
    double containerWidth = screenWidth - 20;

    return Container(
      width: containerWidth/2,
      margin: EdgeInsets.only(left: 10, right: 10),
      height: 200,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorFilling_greedot,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[400]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Text(
          summary,
          style: TextStyle(fontSize: 14.0),
        ),
      ),
    );
  }

}