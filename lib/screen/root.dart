import 'package:flutter/material.dart';
import 'package:projectfront/screen/login/findPassword.dart';
import 'package:provider/provider.dart';

import '../screen/rigging/riggingRoot.dart';
import '../screen/rigging/getImage.dart';
import '../widget/design/settingColor.dart';
import '../provider/pageNavi.dart';
import '../screen/chat/stt.dart';
import 'gree/generativeAI.dart';
import './drawer/drawer.dart';
import './rigging/drawSkeleton.dart';
import '/screen/login/login.dart';
import '/screen/login/memberRegister.dart';
import '/screen/gree/favoriteList.dart';
import 'personality/settingAge.dart';
import '../screen/emotionReport/reportPage.dart';
import '../screen/gree/generativeAIprompt.dart';



String currentPageKey = 'RiggingRoot';

class Navigation_Greedot extends StatefulWidget {
  const Navigation_Greedot({super.key});

  @override
  State<Navigation_Greedot> createState() => _Navigation_GreedotState();
}

class _Navigation_GreedotState extends State<Navigation_Greedot> {
  int currentPageIndex = 0;

  //추가할 페이지 case에 추가
  Widget buildBody(String pageKey) {
    final pageNavi = Provider.of<PageNavi>(context);
    String pageKey = pageNavi.currentPageKey;
    PageData? data = pageNavi.currentPageData;

    switch (pageKey) {
      case 'RiggingRoot':
        return RiggingRoot();
      case 'GetImage_greedot':
        return GetImage_greedot();
      case 'LogIn':
        return LogIn();
      case 'FavoriteListPage':
        return FavoriteListPage();
      case 'newgree':
        return GetImage_greedot();
      case 'SignupScreen':
        return SignupScreen();
      case 'ChatPage':
        return ChatPage(greeId:data?.greeId);
      case 'SettingPersonality':
        return SettingPersonality(greeId:data!.greeId);
      case 'SkeletonCanvas':
        return SkeletonCanvas(greeId:data!.greeId, imageUrl:data.imageUrl);
      case 'ReportPage':
        return ReportPage();
      case 'GenerativeAI':
        return GenerativeAI(greeId:data!.greeId,greeStyle: data!.greeStyle );
        case 'GenerativeAIprompt':
        return GenerativeAIprompt(greeId:data!.greeId);
      default:
        return RiggingRoot();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageNavi = Provider.of<PageNavi>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Greedot"),
        backgroundColor: colorMainBG_greedot,
        centerTitle: false,
        elevation: 0.0,
      ),
      endDrawer: const drawer_greedot(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getCurrentPageIndex(pageNavi.currentPageKey),
        onTap: (int index) {
          String pageKey;
          switch (index) {
            case 0:
              pageKey = 'RiggingRoot';
              break;
            case 1:
              pageKey = 'GetImage_greedot';
              break;
            case 2:
              pageKey = 'LogIn';
              break;
            default:
              pageKey = 'LogIn';
              break;
          }
          pageNavi.changePage(pageKey);
        },
        backgroundColor: colorNaviBar_greedot,
        selectedItemColor: colorText_greedot,
        //todo 색수정
        unselectedItemColor: colorText_greedot,
        items: bottomNavigationBarItems,
      ),
      body: buildBody(pageNavi.currentPageKey),
    );
  }

  int _getCurrentPageIndex(String pageKey) {
    switch (pageKey) {
      case 'RiggingRoot':
        return 0;
      case 'GetImage_greedot':
        return 1;
      case 'LogIn':
        return 2;
      default:
        return 2;
    }
  }

  List<BottomNavigationBarItem> get bottomNavigationBarItems {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: "home",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.notification_add),
        label: "notification",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.message),
        label: "setting",
      ),
    ];
  }
}
