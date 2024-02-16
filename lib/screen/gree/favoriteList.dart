import 'package:flutter/material.dart';
import '../gree/addFavorite.dart';
import '../../widget/design/settingColor.dart';
import '../../service/gree_service.dart';
import '../../models/gree_model.dart';
import 'keepItem.dart';


class FavoriteListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 한 줄에 2개의 그리드 항목을 표시
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
