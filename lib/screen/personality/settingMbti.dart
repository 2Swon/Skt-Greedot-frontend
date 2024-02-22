
import 'package:flutter/material.dart';
import '../../widget/design/settingColor.dart';




class QuestionWidget extends StatelessWidget {
  final int step;
  final List<String?> selectedOption;
  final List<String> questionList;
  final List<List<String>> optionsList;
  final Function(String?) onOptionChanged;

  const QuestionWidget({
    Key? key,
    required this.step,
    required this.selectedOption,
    required this.questionList,
    required this.optionsList,
    required this.onOptionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedOpacity(
          opacity: 1.0, // 이 부분은 필요에 따라 조정하실 수 있습니다.
          duration: Duration(milliseconds: 500),
          child: Text(questionList[step],style:TextStyle(fontSize:22,fontFamily:'greedot_font')),
        ),
        SizedBox(height: 30),
        AnimatedOpacity(
          opacity: 1.0, // 이 부분은 필요에 따라 조정하실 수 있습니다.
          duration: Duration(milliseconds: 500),
          child: _buildRadioOptions(),
        ),
        SizedBox(height: 30),
      ],
    );
  }

  Widget _buildRadioOptions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorBut_greedot,
        border: Border.all(color: colorBut_greedot, width: 4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < optionsList[step].length; i++)
            ListTile(
              title: Text(
                optionsList[step][i],
                style: TextStyle(color: Colors.white,fontSize:18,fontFamily:'greedot_font'),
              ),
              leading: Radio<String>(
                value: optionsList[step][i],
                groupValue: selectedOption[step],
                onChanged: (String? newValue) {
                  onOptionChanged(newValue);
                },
              ),
            ),
          if (step <= optionsList.length - 1)
            Divider(color: Colors.white, thickness: 2),
        ],
      ),
    );
  }
}
