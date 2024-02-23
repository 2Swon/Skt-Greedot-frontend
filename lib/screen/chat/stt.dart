import 'dart:convert';

import 'package:just_audio/just_audio.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:projectfront/screen/chat/gifPlayer.dart';
import 'package:projectfront/widget/design/settingColor.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../service/user_service.dart';
import '../../widget/design/settingColor.dart';

import '../../widget/design/settingColor.dart';
import '../../service/gree_service.dart';
import '../../screen/chat/stt.dart';

class ChatMessage {
  String messageContent;
  bool isUser; // True if this is a user message, false if it's a response

  ChatMessage({required this.messageContent, required this.isUser});
}

class ChatPage extends StatefulWidget {
  final int? greeId;
  const ChatPage({Key? key, this.greeId}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}
class _ChatPageState extends State<ChatPage> {
  final SpeechToText speechToText = SpeechToText();
  var text = "Hold the button and speak";
  var isListening = false;
  List<ChatMessage> messages = [];
  Map<String, String> keywordToGifUrl = {};
  Map<String, String> keywordMapping = {};

  String currentGifUrl = '';

  bool _isLoadingGif = true;

  @override
  void initState() {
    super.initState();
    if (widget.greeId != null) {
      loadGifsAndUpdateMap(widget.greeId!); // 위젯 초기화 시 GIF 목록 로드
    } else {
      // greeId가 없는 경우 로딩 상태를 false로 설정하여 로딩 스피너를 숨깁니다.
      setState(() {
        _isLoadingGif = false;
      });
    }
  }


  void loadGifsAndUpdateMap(int greeId) async {
    Map<String, String> fetchedGifs = await ApiServiceGree.fetchGreeGifs(greeId);
    if (fetchedGifs.isNotEmpty) {
      setState(() {
        keywordToGifUrl = fetchedGifs;
        currentGifUrl = fetchedGifs.values.first;
        _isLoadingGif = false; // GIF 로딩 완료
        createKeywordMapping();
      });
    } else {
      // GIF를 가져오지 못했을 경우 처리
      setState(() {
        currentGifUrl = 'https://default-gif-url/default.gif'; // 기본 GIF URL
        _isLoadingGif = false; // 로딩 완료
      });
    }
  }

  void createKeywordMapping() {
    List<String> koreanKeywords = ['걷', '춤', '안녕']; // 한글 키워드 목록
    List<String> keys = keywordToGifUrl.keys.toList();

    for (int i = 0; i < keys.length; i++) {
      keywordMapping[koreanKeywords[i]] = keys[i];
    }
    print("keywordMapping contents: $keywordMapping");
  }

  void _onSpeechResult(String newText) {
    if (isListening) { // isListening이 true일 때만 결과를 처리합니다.
      setState(() {
        isListening = false; // 음성 인식을 중지합니다.
        speechToText.stop(); // SpeechToText 인스턴스에도 인식을 중지하도록 합니다.
        messages.add(ChatMessage(messageContent: newText, isUser: true));
      });
      _sendMessage(newText);
    }
  }

  void _startListening() async {
    bool available = await speechToText.initialize(
      onError: (val) => print('Error: $val'),
      onStatus: (val) => print('Status: $val'),
    );
    if (available) {
      setState(() => isListening = true);
      speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            _onSpeechResult(result.recognizedWords);
          }
        },
        pauseFor: Duration(seconds: 5), // 예를 들어 pauseFor 값을 3초로 조정
        localeId: 'ko_KR',
      );
    } else {
      setState(() => isListening = false);
      print("The user has denied the use of speech recognition.");
    }
  }


  void _sendMessage(String message) async {
    print('Sending message with greeId: ${widget.greeId}');

    if (widget.greeId != null) {
      try {
        var response = await ApiService.GetChatBotMessage({
          'gree_id': widget.greeId!,
          'message': message
        });
        print('Response received: ${jsonDecode(
            utf8.decode(response.bodyBytes))}'); // 응답 로그

        if (response.statusCode == 200) {
          final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
          final gptTalkContent = decodedResponse['chat_response']['gpt_talk']['content'];
          final voiceUrl = decodedResponse['chat_response']['gpt_talk']['voice_url'];

          String newGifUrl = currentGifUrl;
          for (var koreanKeyword in keywordMapping.keys) {
            if (gptTalkContent.contains(koreanKeyword)) {
              String? mappedKey = keywordMapping[koreanKeyword];
              if (mappedKey != null && keywordToGifUrl.containsKey(mappedKey)) {
                // 매핑된 영문 키워드로 URL 찾기
                newGifUrl = keywordToGifUrl[mappedKey]!;
                break;
              }
            }
          }

          AudioPlayer audioPlayer = AudioPlayer();

          setState(() {
            messages.add(ChatMessage(
                messageContent: gptTalkContent,
                isUser: false
            ));
            currentGifUrl = newGifUrl;
          });
          print("Selected new GIF URL: $newGifUrl");

          if (voiceUrl != null && voiceUrl is String && voiceUrl.isNotEmpty) {
            // voiceUrl이 유효하면 오디오 재생
            await audioPlayer.setUrl(voiceUrl);
            await audioPlayer.play();
          }
        } else {
          print('The request failed with status: ${response.statusCode}');
        }
      } catch (e) {
        print('An error occurred while sending the message: $e');
        setState(() {
          messages.add(ChatMessage(messageContent: "Error: $e", isUser: false));
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorMainBG_greedot,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (_isLoadingGif) // 로딩 스피너 조건부 표시
                  Center(
                    child: CircularProgressIndicator(color: colorBut_greedot),
                  )
                else // GIF가 준비되었을 때만 GifPlayer 표시
                  Align(
                    alignment: Alignment.center,
                    child: Image.network(
                      currentGifUrl.isNotEmpty ? currentGifUrl : 'https://some-default-url/default.gif',
                      width: 580.0, // 이미지의 너비
                      height: 580.0, // 이미지의 높이
                      fit: BoxFit.cover, // 이미지를 화면에 맞게 조정합니다.
                    ),
                  ),
                ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(30.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    return Align(
                      // 사용자 메시지는 오른쪽, 봇 메시지는 왼쪽 정렬
                      alignment: message.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        padding: EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        decoration: BoxDecoration(
                          color: message.isUser ? colorBut_greedot : Colors
                              .grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          message.messageContent,
                          style: TextStyle(
                              color: message.isUser ? Colors.white : Colors
                                  .black,fontFamily:'greedot_font'),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 50),
          AvatarGlow(
            animate: isListening,
            glowColor: Colors.grey,
            //endRadius: 75.0,
            duration: const Duration(milliseconds: 2000),
            //repeatPauseDuration: const Duration(milliseconds: 100),
            repeat: true,
            child: GestureDetector(
              onLongPressStart: (details) => _startListening(),
              onLongPressEnd: (details) {
                if (isListening) {
                  speechToText.stop();
                  setState(() => isListening = false);
                }
              },
              child: FloatingActionButton(
                onPressed: () {
                  // 일반 탭 동작
                },
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                ),
                backgroundColor: colorBut_greedot,
              ),
            ),
          ),
        ],
      ),
    );
  }
}