import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../provider/pageNavi.dart';
import '../../service/gree_service.dart';
import '../gree/generativeAI.dart';
import '../../widget/design/basicButtons.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import '../../widget/design/settingColor.dart';
import '../loading/loadingGif.dart';

class GenerativeAIprompt extends StatelessWidget {
  final double paddingValue = 30.0;
  final double fontSize = 24.0;
  final double spaceBetweenTextAndButtons = 20.0;
  final double buttonSpacing = 10.0;
  final int? greeId;

  GenerativeAIprompt({Key? key, this.greeId}) : super(key: key);




  @override
  Widget build(BuildContext context) {
    final pageNavi = Provider.of<PageNavi>(context);

    return FutureBuilder(
      future: ApiServiceGree.readGree(greeId!),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else {
          var greeData = snapshot.data;
          String imageUrl = greeData['raw_img'];

          return Container(
            padding: EdgeInsets.all(paddingValue),
            color: colorMainBG_greedot,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0), // Add some space above the text
                    child: Text(
                      "그리의 스타일을 정해봐요",
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        fontFamily:'greedot_font'
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            imageUrl,
                            width: 300,
                            height: 300,
                          ),
                          SizedBox(height: buttonSpacing),
                        ],
                      ),
                      SizedBox(width: spaceBetweenTextAndButtons),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          EleButton_greedot(
                            buttonText: '원본 유지',
                            additionalFunc: () {
                              pageNavi.changePage('GenerativeAI', data: PageData(greeId: greeId, greeStyle: 1));
                            },
                          ),
                          SizedBox(height: buttonSpacing), // Use height for vertical spacing
                          EleButton_greedot(
                            buttonText: '카툰풍',
                            additionalFunc: () {
                              pageNavi.changePage('GenerativeAI',data: PageData(greeId: greeId, greeStyle: 2));
                            },
                          ),
                          SizedBox(height: buttonSpacing), // Use height for vertical spacing
                          EleButton_greedot(
                            buttonText: '스캐치풍',
                            additionalFunc: () {
                              pageNavi.changePage('GenerativeAI',data: PageData(greeId: greeId, greeStyle: 3));
                            },
                          ),
                          SizedBox(height: buttonSpacing), // Use height for vertical spacing
                          EleButton_greedot(
                            buttonText: '디즈니풍',
                            additionalFunc: () {
                              pageNavi.changePage('GenerativeAI',data: PageData(greeId: greeId, greeStyle: 4));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
