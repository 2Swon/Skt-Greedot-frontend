import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../provider/pageNavi.dart';
import '../../service/gree_service.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as Path;

import '../loading/loadingGif.dart';

class GenerativeAI extends StatefulWidget {
  final int? greeId;
  final int? greeStyle;

  const GenerativeAI({Key? key, required this.greeId, required this.greeStyle})
      : super(key: key);

  @override
  _GenerativeAIState createState() => _GenerativeAIState();
}

class _GenerativeAIState extends State<GenerativeAI> {
  List<String>? uploadedImageUrls;
  int? selectedImageIndex;
  bool _isLoading = true;

  void showLoadingDialog(BuildContext context) {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false, // 사용자가 다이얼로그 밖을 터치하여 닫을 수 없도록 설정
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0), // 다이얼로그 내부의 여백 조정
            child: Column(
              mainAxisSize: MainAxisSize.min, // 내용물 크기에 맞게 Column 크기 조정
              children: <Widget>[
                LoadingGifWidget(), // 로딩 GIF 위젯
                SizedBox(height: 20), // GIF와 텍스트 사이의 간격
                CircularProgressIndicator(), // 로딩 스피너
                SizedBox(height: 20), // 텍스트와 스피너 사이의 간격
                Text(
                  "AI 그림을 생성 중입니다...(약 30초 소요)", // 로딩 메시지
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.0, // 텍스트 크기 조정
                  ),
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // 다이얼로그 모서리 둥글게 처리
          ),
        );
      },
    );
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchImages();
    });
  }

  void _fetchImages() async {
    showLoadingDialog(context); // 로딩 다이얼로그를 먼저 표시
    try {
      List<String> images = await ApiServiceGree.fetchUploadedImages(widget.greeId!, widget.greeStyle!);
      setState(() {
        uploadedImageUrls = images;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        print("Error fetching images: $e");
      });
    } finally {
      Navigator.of(context, rootNavigator: true).pop('dialog'); // 작업이 완료되면 다이얼로그 닫기
    }
  }


  @override
  Widget build(BuildContext context) {
    final pageNavi = Provider.of<PageNavi>(context, listen: false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 290.0), // 여기서 전체 위젯의 좌우에 패딩을 추가합니다.
      color: const Color(0xFFFFFDD3), // 배경색 설정
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1, // 여기서 GridView의 각 항목을 1:1 비율로 설정합니다.
          crossAxisSpacing: 9.0,
          mainAxisSpacing: 9.0,
        ),
        itemCount: uploadedImageUrls?.length ?? 0,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () async {
              // 이미지를 탭했을 때의 동작 구현
              if (selectedImageIndex != null) {
                final imageUrl = uploadedImageUrls![selectedImageIndex!];
                final downloadedFile = await downloadImage(imageUrl);
                if (downloadedFile != null) {
                  final response = await ApiServiceGree.uploadImage(downloadedFile.path);
                  if (response != null && response['message'] == 'File uploaded successfully.') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('성공적으로 업로드되었습니다'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.green,
                      ),
                    );
                    int greeId = response['gree_id'];
                    await ApiServiceGree.processGreeImages(greeId);
                    pageNavi.changePage('SettingPersonality', data: PageData(greeId: greeId));
                  }
                }
              }
            },
            child: AspectRatio(
              aspectRatio: 1, // Stack의 비율을 1:1로 고정합니다.
              child: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  // 모서리 둥글게 처리 및 그림자 추가
                  color: Colors.white, // 이 부분은 필요에 따라 조정하세요.
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        uploadedImageUrls![index],
                        fit: BoxFit.cover, // 이미지를 타일에 맞게 조절
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                selectedImageIndex = index;
                              });
                            },
                            child: Text(
                              '선택하기',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }



  Future<File?> downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = Path.join(directory.path, 'downloadedImage.png');
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      print("Error downloading image: $e");
      return null;
    }
  }
}
