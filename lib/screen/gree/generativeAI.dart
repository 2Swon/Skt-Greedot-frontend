import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../provider/pageNavi.dart';
import '../../service/gree_service.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  void _fetchImages() async {
    try {
      List<String> images =
      await ApiServiceGree.fetchUploadedImages(widget.greeId!, widget.greeStyle!);
      setState(() {
        uploadedImageUrls = images;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        print("Error fetching images: $e");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageNavi = Provider.of<PageNavi>(context, listen: false);
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 9.0,
        mainAxisSpacing: 9.0,
      ),
      itemCount: uploadedImageUrls?.length ?? 0,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () async {
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
          child: Container(
            padding: EdgeInsets.all(5),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    uploadedImageUrls![index],
                    fit: BoxFit.cover, // 이미지를 타일에 맞게 조절
                  ),
                ),
                // 선택하기 버튼
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
        );
      },
    );
  }

  Future<File?> downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = join(directory.path, 'downloadedImage.png');
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
