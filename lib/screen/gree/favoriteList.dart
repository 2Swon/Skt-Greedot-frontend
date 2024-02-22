import 'package:flutter/material.dart';
import '../gree/addFavorite.dart';
import 'addFavorite.dart';
import '../../widget/design/settingColor.dart';
import '../../service/gree_service.dart';
import '../../models/gree_model.dart';
import 'keepItem.dart';


class FavoriteListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    // List<Widget> items = favoriteItems.map((item) {
    //   return FavoriteItemCard(
    //     image: item.image,
    //     name: item.name,
    //     mbti: item.mbti,
    //     description: item.description,
    //   );
    // }).toList();

    return Container(
      color: colorMainBG_greedot,
      child: FutureBuilder<List<Gree>>(
        future: ApiServiceGree.readGrees(), // 서버에서 Gree 데이터를 비동기적으로 가져옴
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 데이터가 로드되는 동안 로딩 인디케이터를 표시
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // 에러가 발생했을 때 에러 메시지를 표시
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            // 데이터 로딩 성공하고 데이터가 비어있지 않을 때
            return GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 75.0), // 여기에 패딩을 추가했습니다.
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 한 줄에 2개의 그리드 항목을 표시
                childAspectRatio: 2 / 1.2, // 너비 대 높이 비율을 2:1.2로 설정
              ),
              itemCount: snapshot.data!.length, // 데이터 리스트의 길이만큼 아이템 수를 설정
              itemBuilder: (context, index) {
                // 리스트에서 각 Gree 객체에 접근
                Gree gree = snapshot.data![index];
                // Gree 객체를 사용하여 FavoriteItemCard 위젯을 생성
                return FavoriteItemCard(gree: gree);
              },
            );

          } else {
            // 데이터가 비어있을 때 표시할 위젯
            return Center(child: Text("No items available."));
          }
        },
      ),
    );
  }
}
