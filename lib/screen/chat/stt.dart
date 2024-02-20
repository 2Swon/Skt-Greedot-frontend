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

  String currentGifUrl = '';

  void initState() {
    super.initState();
    if (widget.greeId != null) {
      loadGifsAndUpdateMap(widget.greeId!); // 위젯 초기화 시 GIF 목록 로드
    }
  }

  void loadGifsAndUpdateMap(int greeId) async {
    Map<String, String> fetchedGifs = await ApiServiceGree.fetchGreeGifs(
        greeId);
    if (fetchedGifs.isNotEmpty) {
      setState(() {
        keywordToGifUrl = fetchedGifs;
        currentGifUrl =
            fetchedGifs.values.first; //
      });
    } else {
      // GIF를 가져오지 못했을 경우 처리
      setState(() {
        currentGifUrl = 'https://default-gif-url/default.gif'; // 기본 GIF URL
      });
    }
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
    var available = await speechToText.initialize(
      onError: (val) => print('Error: $val'),
      onStatus: (val) => print('Status: $val'),
    );
    if (available) {
      setState(() => isListening = true);
      speechToText.listen(
        onResult: (result) {
          if (result.finalResult) { // 최종 결과가 나왔을 때만 처리합니다.
            _onSpeechResult(result.recognizedWords);
          }
        },
        listenFor: Duration(seconds: 15),
        pauseFor: Duration(milliseconds: 1500),
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
        print('Response received: ${jsonDecode(utf8.decode(response.bodyBytes))}'); // 응답 로그

        if (response.statusCode == 200) {
          final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
          final gptTalkContent = decodedResponse['chat_response']['gpt_talk']['content'];
          final voiceUrl = decodedResponse['chat_response']['gpt_talk']['voice_url'];

          String newGifUrl = currentGifUrl;
          for (var keyword in keywordToGifUrl.keys) {
            if (gptTalkContent.contains(keyword)) {
              newGifUrl = keywordToGifUrl[keyword]!; //TODO 이부분 수정필요
              break;
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
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3, // 채팅창이 차지하는 비율을 조정합니다.
                  child: ListView.builder(
                    reverse: true,
                    //padding: const EdgeInsets.only(top:30.0),
                    padding: const EdgeInsets.all(30.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 -
                          index]; // 메시지 리스트를 역순으로 렌더링합니다.
                      return Align(
                        alignment: message.isUser
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
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
                                    .black),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: GifPlayer(
                    // null이 아니면 currentGifUrl을 사용하고, null이면 기본 URL을 제공합니다.
                    gifUrl: currentGifUrl ?? 'https://some-default-url/default.gif',
                    width: 200.0,
                    height: 500.0,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 50),
          AvatarGlow(
            animate: isListening,
            duration: const Duration(milliseconds: 2000),
            repeat: true,
            glowColor: Colors.grey,
            child: FloatingActionButton(
              backgroundColor: colorBut_greedot,
              onPressed: () {
                if (isListening) {
                  speechToText.stop();
                  setState(() => isListening = false);
                } else {
                  _startListening();
                }
              },
              child: Icon(isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white),
            ),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }
}