import 'package:flutter/material.dart';
import 'package:projectfront/provider/pageNavi.dart';
import 'package:projectfront/screen/rigging/drawSkeletonNavi.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screen/loading/startApp.dart';

Future main() async {
  // .env 파일을 불러오기 전에 필요한 초기 설정
  WidgetsFlutterBinding.ensureInitialized();
  // .env 파일 불러오기
  await dotenv.load(fileName: ".env");

  runApp(NavigationBarApp());
}

class NavigationBarApp extends StatelessWidget {
  NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PageNavi()),
        ChangeNotifierProvider(create: (context) => LoadingNotifier()),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: SplashScreen(),
      ),
    );
  }
}
