import 'dart:math';

import 'package:flutter/material.dart';
import 'package:projectfront/provider/pageNavi.dart';
import 'package:provider/provider.dart';
import '../../widget/design/settingColor.dart';
import '../rigging/drawSkeleton.dart';
import './personalitydata.dart';
import './settingMbti.dart';
import '../../service/gree_service.dart';
import '../../models/gree_model.dart';

class SettingPersonality extends StatefulWidget {
  final int? greeId; // 생성자를 통해 받을 greeId

  SettingPersonality({Key? key, this.greeId}) : super(key: key);

  @override
  _SettingPersonalityState createState() => _SettingPersonalityState();
}

class _SettingPersonalityState extends State<SettingPersonality> {
  String imageUrl = ''; // 이미지 URL을 저장할 상태 변수
  int step = -1;
  double _opacity = 1.0;
  List<String?> selectedOption = List.filled(4, null);
  bool _isLoadingImage = true;
  String _loadingError = '';

  String? _selectedSex;
  String? _selectedAge;
  TextEditingController _nameController = TextEditingController();
  List<String> sexList = PersonalityData.sexList;
  List<String> ageList = PersonalityData.ageList;
  List<List<String>> optionValues = PersonalityData.optionValues;
  List<String> questionList = PersonalityData.questionList;
  List<List<String>> optionsList = PersonalityData.optionsList;

  @override
  void initState() {
    super.initState();
    if (widget.greeId != null) {
      fetchGreeImage(widget.greeId!); // 널 체크 연산자 (!) 추가
    } else {
      // greeId가 null이면 이미지 로딩이 필요 없음
      _isLoadingImage = false;
    }
  }

  Future<void> fetchGreeImage(int greeId) async {
    try {
      setState(() {
        _isLoadingImage = true; // 로딩 시작
        _loadingError = ''; // 에러 메시지 초기화
      });
      var greeData = await ApiServiceGree.readGree(greeId);
      if (greeData != null && greeData['raw_img'] != null) {
        setState(() {
          imageUrl = greeData['raw_img'];
          _isLoadingImage = false; // 로딩 완료
        });
      } else {
        throw Exception('Invalid image data');
      }
    } catch (e) {
      setState(() {
        _loadingError = '이미지 로딩 실패: $e';
        _isLoadingImage = false;
      });
    }
  }


  void _handleRadioValueChanged(String? newValue) {
    setState(() {
      selectedOption[step] = newValue;
    });
  }

  void _goBack() {
    setState(() {
      if (step > 0) {
        step--;
      }
    });
  }

  void _goNext() async {
    if (step < questionList.length - 1) {
      // 다음 질문으로 이동
      setState(() {
        step++;
      });
    } else {
      // 모든 질문에 답함 - 결과 처리
      String MBTIResult = '';
      for (int i = 0; i < selectedOption.length; i++) {
        int index = optionsList[i].indexOf(selectedOption[i]!);
        MBTIResult += optionValues[i][index];
      }

      GreeUpdate updatedUserData = GreeUpdate(
        gree_name: _nameController.text,
        prompt_age: int.parse(_selectedAge ?? '0'),
        prompt_gender: _selectedSex ?? '',
        prompt_mbti: MBTIResult,
      );

      if (widget.greeId != null) {
        final pageNavi = Provider.of<PageNavi>(context, listen: false);
        try {
          await ApiServiceGree.updateGree(widget.greeId!, updatedUserData); // updatedUserData 전달
          print('Gree updated successfully.');
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => SkeletonCanvas(
          //       greeId: widget.greeId, // gree_id 전달
          //       imageUrl: imageUrl, // 이미지 URL 전달
          //     ),
          //   ),
          // );
          pageNavi.changePage('SkeletonCanvas', data: PageData(greeId: widget.greeId , imageUrl:imageUrl ));

        } catch (e) {
          print('Failed to update gree: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gree 정보 업데이트에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      setState(() {
        _showResult = true;
      });
    }

  }


  bool _showResult = false;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView( // 전체 스크롤 가능하게 설정
        child: Container(
          width: screenWidth,
          height: screenHeight,
          color: colorMainBG_greedot, // 배경색 설정
          child: Center( // 가운데 정렬로 변경
            child: _isLoadingImage
                ? CircularProgressIndicator() // 로딩 중 표시
                : Row(
              // 이미지와 폼을 포함하는 Row 위젯
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Image.network(
                    imageUrl,
                    width: 300,
                    height: 300,
                  ),
                ),
                SizedBox(width: 16),
                Flexible( // 폼을 Flexible로 감싸기
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: SingleChildScrollView( // 폼 내용이 길 경우 스크롤 가능하게 설정
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (step == -1) nameGenderAge(),
                          if (step != -1 && step < questionList.length)
                            QuestionWidget(
                              step: step,
                              selectedOption: selectedOption,
                              questionList: questionList,
                              optionsList: optionsList,
                              onOptionChanged: (newValue) {
                                _handleRadioValueChanged(newValue);
                              },
                            ),
                          SizedBox(height: 60),
                          _buildNavigationButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Column nameGenderAge() {
    return Column(
      children: [
        SizedBox(height: 50),
        Container(
          width: 408,
          height: 50,
          child: TextField(
            controller: _nameController,
            style: TextStyle(color: colorBig_But_greedot),
            decoration: InputDecoration(
              labelText: '이름:',
              hintText: ' 이름을 입력하세요',
              hintStyle: TextStyle(color: colorBig_But_greedot, fontSize: 14),
              filled: true,
              fillColor: colorBut_greedot,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: colorBut_greedot, width: 2.0),
                borderRadius: BorderRadius.circular(15),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorBut_greedot, width: 2.0),
                borderRadius: BorderRadius.circular(15),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorBut_greedot, width: 2.0),
                borderRadius: BorderRadius.circular(15),
              ),
              labelStyle: TextStyle(color: colorBig_But_greedot, fontSize: 14),
            ),
          ),
        ),
        SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
                fit: FlexFit.loose,
                child:
                    _buildDropdown(sexList, _selectedSex, ' 성별: ', (newValue) {
                  setState(() {
                    _selectedSex = newValue;
                  });
                })),
            SizedBox(width: 30),
            Flexible(
                fit: FlexFit.loose,
                child:
                    _buildDropdown(ageList, _selectedAge, ' 나이: ', (newValue) {
                  setState(() {
                    _selectedAge = newValue;
                  });
})),
          ],
        ),
      ],
    );
  }



  Widget _buildDropdown(List<String> optionsList, String? selectedValue, String hintText, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        fillColor: colorBut_greedot,
        filled: true,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: colorBut_greedot, width: 2.0),
          borderRadius: BorderRadius.circular(15),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorBut_greedot, width: 2.0),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorBut_greedot, width: 2.0),
          borderRadius: BorderRadius.circular(15),
        ),
        labelStyle: TextStyle(color: colorBig_But_greedot, fontSize: 14),
      ),
      value: selectedValue,
      hint: Text(hintText, style: TextStyle(color: colorBig_But_greedot, fontSize: 14)),
      icon: const Icon(Icons.arrow_drop_down, color: colorBig_But_greedot),
      style: TextStyle(color: colorBig_But_greedot, fontSize: 16),
      onChanged: onChanged,
      items: optionsList.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: TextStyle(
              color: value == selectedValue ? colorBig_But_greedot : Colors.black,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (step > 0 && !_showResult)
            ElevatedButton(
              onPressed: _goBack,
              child: Text('이전',
                style: TextStyle(color: colorBig_But_greedot,fontSize:18,fontFamily:'greedot_font'),),
              style: ElevatedButton.styleFrom(
                primary: colorBut_greedot, // Background color
              ),
            ),
          if (step < questionList.length || _showResult)
            SizedBox(width: 20), // 버튼 사이의 간격
          ElevatedButton(
            onPressed: _goNext,
            child: Text(_showResult ? '생성완료' : '다음',
              style: TextStyle(color: colorBig_But_greedot,fontSize:18,fontFamily:'greedot_font'),),
            style: ElevatedButton.styleFrom(
              primary: colorBut_greedot, // Background color
            ),
          ),
        ],
      ),
    );
  }
}
