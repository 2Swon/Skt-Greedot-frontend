import 'dart:io';

import 'package:projectfront/models/user_model.dart';
import 'package:projectfront/provider/pageNavi.dart';
import 'package:provider/provider.dart';

import '../../widget/design/settingColor.dart';
import '../../widget/design/basicButtons.dart';
import '../../structure/structureInit.dart';
import '../../service/gree_service.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../personality/settingAge.dart';

//design setting for GetImage_greedot
double paddingForButtons = 10; //다 상대적인 값으로 교체 예정
double canvasSize = 350;


class GetImage_greedot extends StatefulWidget {
  const GetImage_greedot({Key? key}) : super(key: key);
  @override
  State<GetImage_greedot> createState() => _getImageState();
}

class _getImageState extends State<GetImage_greedot> {
  XFile? _image; //이미지를 담을 변수 선언
  final ImagePicker picker = ImagePicker(); //ImagePicker 초기화
  String? _imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorMainBG_greedot,
      child: Stack(
        children: [
          Positioned(
            left: 50, // 왼쪽에서 50의 위치에
            bottom: 400, // 아래에서 400의 위치에
            child: Image.asset(
              'assets/images/cute_element/flower1.png', // 꽃 이미지 추가
              width: 200,
              height: 200,
            ),
          ),
          Positioned(
            right: 0, // 오른쪽 끝에
            bottom: 0, // 아래 끝에
            child: Image.asset(
              'assets/images/cute_element/tulip.png', // 개 이미지 추가
              width: 400,
              height: 400,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center, // 세로 방향으로 중앙 정렬
            crossAxisAlignment: CrossAxisAlignment.center, // 가로 방향으로 중앙 정렬
            children: [
              const SizedBox(height: 30),
              _buildPhotoArea(),
              const SizedBox(height: 20),
              _buildButton(),
            ],
          ),

        ],
      ),
    );
  }


  //이미지를 가져오는 함수
  Future getImage(ImageSource imageSource) async {
    //pickedFile에 ImagePicker로 가져온 이미지가 담긴다.
    final XFile? pickedFile = await picker.pickImage(
      source: imageSource,
      maxHeight: 350,
      maxWidth: 350,
    ); //사이즈 조정이 맞는지는 모름
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
        _image = XFile(pickedFile.path); //가져온 이미지를 _image에 저장
      });
    }
  }


  Future<void> showUploadSuccessSnackBar(int i) async {
    final pageNavi = Provider.of<PageNavi>(context, listen: false);
    if (_image != null) {
      final response = await ApiServiceGree.uploadImage(_imagePath!);
      if (response != null && response['message'] == 'File uploaded successfully.') {
        // 업로드 성공 로직
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('성공적으로 업로드되었습니다'),
            duration: Duration(seconds: 2),
            backgroundColor: colorSnackBar_greedot,
          ),
        );
        int greeId = response['gree_id'];
        if (i == 1){
        await ApiServiceGree.processGreeImages(greeId); // 추가 이미지 처리 요청

        pageNavi.changePage('SettingPersonality', data: PageData(greeId: greeId));
        }
        else if (i==2){
          pageNavi.changePage('GenerativeAIprompt', data: PageData(greeId: greeId,));
        }

      } else {
        // 업로드 실패 로직
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('업로드에 실패했습니다'),
            duration: Duration(seconds: 2),
            backgroundColor: colorSnackBar_greedot,
          ),
        );
      }
    } else {
      // 이미지 선택 안 됨 로직
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('업로드할 이미지를 선택해주세요.'),
          duration: Duration(seconds: 2),
          backgroundColor: colorSnackBar_greedot,
        ),
      );
    }
  }

  Widget _buildPhotoArea() {
    return Center(
      // Center 위젯을 사용하여 가운데로 정렬합니다.
      child: Container(
        width: canvasSize,
        height: canvasSize,
        decoration: BoxDecoration(
          // 모서리를 둥글게 처리하기 위해 borderRadius를 추가합니다.
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: Colors.grey, // 경계선의 색상을 지정합니다.
            width: 2.0, // 경계선의 너비를 지정합니다.
          ),
          // _image가 null이 아닐 때와 null일 때를 구분하여 처리합니다.
          image: _image != null
              ? DecorationImage(
            image: FileImage(File(_image!.path)), // 이미지 파일을 화면에 띄워줍니다.
            fit: BoxFit.cover, // 이미지가 컨테이너를 꽉 채우도록 설정합니다.
          )
              : null,
          color: _image == null ? Colors.white60 : null, // 이미지가 없을 경우 회색 배경을 표시합니다.
        ),
      ),
    );
  }


  Widget _buildButton() {
    double buttonWidth = 170;
    double buttonHeight = 50;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 첫 번째 줄에 카메라와 갤러리 버튼 배치
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt, color: Colors.white), // 카메라 아이콘 추가
              label: Text("카메라",style:TextStyle(fontSize:17,fontFamily:'greedot_font')),
              onPressed: () {
                getImage(ImageSource.camera); // 카메라로 찍은 사진 가져오기
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(buttonWidth, buttonHeight), // 모든 버튼에 대해 동일한 크기 설정
                primary: colorBut_greedot, // 배경 색상
                onPrimary: Colors.white, // 아이콘 및 텍스트 색상
              ),
            ),
            SizedBox(width: paddingForButtons), // 버튼 사이의 간격 조정
            ElevatedButton.icon(
              icon: Icon(Icons.photo_library, color: Colors.white), // 갤러리 아이콘 추가
              label: Text("갤러리",style:TextStyle(fontSize:17,fontFamily:'greedot_font')),
              onPressed: () {
                getImage(ImageSource.gallery); // 갤러리에서 사진 가져오기
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(buttonWidth, buttonHeight), // 모든 버튼에 대해 동일한 크기 설정
                primary: colorBut_greedot, // 버튼 배경 색상
                onPrimary: Colors.white, // 버튼 텍스트 및 아이콘 색상
              ),
            ),
          ],
        ),
        SizedBox(height: paddingForButtons),
        // 두 번째 줄에 업로드와 AI 캐릭터 만들기 버튼 배치
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.cloud_upload, color: Colors.white), // 업로드 아이콘 추가
              label: Text("업로드",style:TextStyle(fontSize:17,fontFamily:'greedot_font')),
              onPressed: () {
                showUploadSuccessSnackBar(1); // 업로드 성공 알림 표시
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(buttonWidth, buttonHeight), // 모든 버튼에 대해 동일한 크기 설정
                primary: colorBut_greedot, // 버튼 배경 색상
                onPrimary: Colors.white, // 버튼 텍스트 및 아이콘 색상
              ),
            ),
            SizedBox(width: paddingForButtons),
            ElevatedButton.icon(
              icon: Icon(Icons.face, color: Colors.white), // AI 캐릭터 만들기 아이콘 추가
              label: Text("AI 캐릭터 만들기",style:TextStyle(fontSize:17,fontFamily:'greedot_font')),
              onPressed: () {
                showUploadSuccessSnackBar(2); // 업로드 성공 알림 표시
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(buttonWidth, buttonHeight), // 모든 버튼에 대해 동일한 크기 설정
                primary: colorBut_greedot, // 버튼 배경 색상
                onPrimary: Colors.white, // 버튼 텍스트 및 아이콘 색상
              ),
            ),
          ],
        ),
      ],
    );
  }

}
