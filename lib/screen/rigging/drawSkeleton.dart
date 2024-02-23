import 'dart:io';

import 'package:flutter/material.dart';
import 'package:projectfront/widget/design/settingColor.dart';
import 'package:provider/provider.dart';

import '../../structure/structure.dart';
import '../../structure/structureInit.dart';
import './drawSkeletonNavi.dart';


class SkeletonCanvas extends StatefulWidget {
  final int? greeId;
  final String? imageUrl;

  SkeletonCanvas({Key? key, this.greeId, this.imageUrl}) : super(key: key);

  @override
  _SkeletonCanvasState createState() => _SkeletonCanvasState();
}

class _SkeletonCanvasState extends State<SkeletonCanvas> {
  List<Offset> positions = List.generate(
      skeletonInfo.length, (index) => Offset(100.0 * (index + 1), 100.0));

  double offsetX = 0.0;
  double offsetY = 0.0;
  double preX = 0.0;
  double preY = 0.0;
  double radiusDragBut = 15.0;

  bool trigger = false;
  bool _initState = true;

  late double moveX, moveY, newPosX, newPosY;

  // segment 단계에서 resizing이 들어가기 때문에 고정값
  double imageWidth = 400;
  double imageHeight = 400;

  double conSizeX = 400;
  double conSizeY = 400;
  
  final GlobalKey _containerKey = GlobalKey();
  Offset? offset;

  @override
  Widget build(BuildContext context) {
    final loadingNotifier = Provider.of<LoadingNotifier>(context);
    final screenSize = MediaQuery
        .of(context)
        .size;

    //좌상단 이미지 좌표 구하기 
    // final arrangeCenterX = screenSize.width / 2 - conSizeX / 2;
    // final arrangeCenterY = screenSize.height / 2 - conSizeY / 2 - 
    //    150; // todo 150 으로 하드 코딩한 부분 해결하는 로직 고민
    final double arrangeCenterX = 402;
    final double arrangeCenterY = 130;

    return Container(
      color: colorMainBG_greedot,
      child: Stack(
        children: [
          Container(
            alignment: Alignment.topCenter,
            padding: EdgeInsets.only(top: 50),
            child: _buildPhotoArea(),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: LinePainter(
                  positions, arrangeCenterX, arrangeCenterY, radiusDragBut),
            ),
          ),
          drawSkeletonNavi(context, imageWidth, imageHeight, widget.greeId),
          if (loadingNotifier.isLoading)
            Center(child: CircularProgressIndicator()),
          // Draggable buttons
          ...List.generate(skeletonInfo.length, (index) {
            return Positioned(
              left: skeletonInfo[index].point.dx + arrangeCenterX,
              top: skeletonInfo[index].point.dy + arrangeCenterY,
              // 버튼 좌표 skeletonInfo 안의 point로 설정
              child: Draggable(
                // 드래그 할 수 있는 요소 생성
                feedback: _buildDraggableCircle(index),
                onDragUpdate: (updateDragDetails) {
                  if (_initState) {
                    moveX = updateDragDetails.localPosition.dx -
                        skeletonInfo[index].point.dx;
                    moveY = updateDragDetails.localPosition.dy -
                        skeletonInfo[index].point.dy;
                             // moveX, moveY 시작위치와 현재위치의 차이 구함
                    _initState = false;
                  }
                  newPosX = updateDragDetails.localPosition.dx - moveX;
                  newPosY =
                      updateDragDetails.localPosition.dy - moveY; // 새로운 위치 계산

                  if (newPosX >= 0 && newPosX <= imageWidth && newPosY >= 0 &&
                      newPosY <= imageHeight) {
                    _onDrag(index, Offset(newPosX, newPosY));
                  }
                },
                onDragEnd: (endDragDetails) {
                  _initState = true;
                },
                child: _buildDraggableCircle(index),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDraggableCircle(int index) {
    return Tooltip(
      message: skeletonInfo[index].fromJoint, // 마우스 클릭 시 설명
      child: CircleAvatar(radius: radiusDragBut, child: Text('${index + 1}')),
    );
  }

  void _onDrag(int index, Offset offset) {
    // 드래그 위치가 이미지 영역 내에 있는지 확인
    bool withinWidthBounds = offset.dx >= 0 && offset.dx <= imageWidth;
    bool withinHeightBounds = offset.dy >= 0 && offset.dy <= imageHeight;

    // 조건을 만족하면 상태 업데이트
    if (withinWidthBounds && withinHeightBounds) {
      setState(() {
        skeletonInfo[index].point = offset;
      });
    }
  }

// _buildPhotoArea 메서드 수정
  Widget _buildPhotoArea() {
    return widget.imageUrl!.isNotEmpty
        ? Container(
      key: _containerKey,
      width: conSizeX,
      height: conSizeY,
      child: Image.network(
          widget.imageUrl!, fit: BoxFit.cover), // Image.network를 사용하여 이미지 표시
    )
        : Container(
      key: _containerKey,
      width: conSizeX,
      height: conSizeY,
      color: Colors.grey, // imageUrl이 비어있는 경우 회색 배경 표시
    );
  }

  // 중앙 위치 구하기
  Offset? _getOffset() {
    if (_containerKey.currentContext != null) {
      final RenderBox renderBox =
          _containerKey.currentContext!.findRenderObject() as RenderBox;
      Offset offset = renderBox.localToGlobal(Offset.zero);
      return offset;
    }
  }
    @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        offset = _getOffset();
        print('offset : $offset');
      });
    });
  }

}

class LinePainter extends CustomPainter {
  final List<Offset> positions;
  final double arrangeCenterX;
  final double arrangeCenterY;
  final double radiusDragBut;

  LinePainter(this.positions, this.arrangeCenterX, this.arrangeCenterY,this.radiusDragBut );
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    print('offset_origin : $arrangeCenterX , $arrangeCenterY');
    for (Joint fromJ in skeletonInfo) {
      //Node 객체들이 들어 있으며, 각 Node는 연결점을 나타냄
      String currentJoint = fromJ.fromJoint;
      for (Joint toJ in skeletonInfo) {
        String? connectedJoint = toJ.toJoint;
        if (currentJoint == connectedJoint) {
          Offset coord1 = Offset(
              fromJ.point.dx + radiusDragBut + arrangeCenterX , fromJ.point.dy + radiusDragBut +arrangeCenterY);
          Offset coord2 = Offset(
              toJ.point.dx + radiusDragBut + arrangeCenterX, toJ.point.dy + radiusDragBut + arrangeCenterY);
          canvas.drawLine(coord1, coord2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
