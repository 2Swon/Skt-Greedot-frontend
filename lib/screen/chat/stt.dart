import 'dart:convert';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:projectfront/widget/design/settingColor.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../service/user_service.dart';
import '../../service/gree_service.dart';

import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Naver API 클라이언트 정보
String clientId = dotenv.env['NAVER_CLIENT_ID']!;
String clientSecret = dotenv.env['NAVER_CLIENT_SECRET']!;

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
  List<ChatMessage> messages = [];
  Map<String, String> keywordToGifUrl = {};
  Map<String, String> keywordMapping = {};

  String currentGifUrl = '';

  bool _isLoadingGif = true;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  var isListening = false;



  @override
  void initState() {
    super.initState();
    _initRecorder();
    if (widget.greeId != null) {
      loadGifsAndUpdateMap(widget.greeId!); // 위젯 초기화 시 GIF 목록 로드
    } else {
      // greeId가 없는 경우 로딩 상태를 false로 설정하여 로딩 스피너를 숨깁니다.
      setState(() {
        _isLoadingGif = false;
      });
    }
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    _isRecorderInitialized = true;
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


  void _sendMessage(String message) async {
    print('Sending message with greeId: ${widget.greeId}');
    if (widget.greeId != null) {
      try {
        var response = await ApiService.GetChatBotMessage({
          'gree_id': widget.greeId!,
          'message': message
        });
        print('Response received: ${jsonDecode(utf8.decode(response.bodyBytes))}');

        if (response.statusCode == 200) {
          final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
          final chatResponse = decodedResponse['chat_response'];
          final gptTalkContent = chatResponse['gpt_talk']['content'];
          // API로부터 받은 메시지를 상태에 추가합니다.
          setState(() {
            messages.add(ChatMessage(messageContent: gptTalkContent, isUser: false));
          });
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


  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) return;

    // 오디오 녹음 권한 요청
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }

    // 권한이 부여된 후에 녹음 시작
    status = await Permission.microphone.status;
    if (status.isGranted) {
      Directory appDirectory = await getApplicationDocumentsDirectory();
      String filePath = '${appDirectory.path}/${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );
      setState(() => isListening = true);
    } else {
      print("The user has denied the use of recording.");
    }
  }



  // 녹음 중지 및 Naver 음성 인식 API 호출
  Future<void> _stopAndRecognizeSpeech() async {
    var recording = await _recorder.stopRecorder();
    setState(() => isListening = false);

    if (recording != null) {
      File voiceFile = File(recording);
      try {
        var response = await _sendVoiceToNaver(voiceFile);
        if (response.statusCode == 200) {
          print("Success: ${response.body}");
          final jsonResponse = jsonDecode(response.body);
          final text = jsonResponse['text']; // STT 응답으로부터 텍스트 추출
          if (text != null) {
            setState(() {
              messages.add(ChatMessage(messageContent: text, isUser: true));
            });
            _sendMessage(text); // 추출된 텍스트를 이용하여 _sendMessage 호출
          }
        } else {
          print("Error: ${response.body}");
        }
      } catch (e) {
        print("Error calling Naver Speech-to-Text API: $e");
      }
    }
  }


  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  // Naver 음성 인식 API 호출
  Future<http.Response> _sendVoiceToNaver(File voiceFile) {
    String url = "https://naveropenapi.apigw.ntruss.com/recog/v1/stt?lang=Kor";
    Map<String, String> headers = {
      "X-NCP-APIGW-API-KEY-ID": clientId,
      "X-NCP-APIGW-API-KEY": clientSecret,
      "Content-Type": "application/octet-stream",
    };
    return http.post(Uri.parse(url), headers: headers, body: voiceFile.readAsBytesSync());
  }

  // 기존의 _startListening 함수를 변경합니다.
  void _startListening() async {
    await _startRecording();
    // Naver 음성 인식 API로부터 결과를 받은 후 처리할 로직을 여기에 구현합니다.
    // 예를 들어, 음성 녹음을 일정 시간 후에 자동으로 중지하려면 Future.delayed를 사용할 수 있습니다.
    Future.delayed(Duration(seconds: 5), () {
      _stopAndRecognizeSpeech();
    });
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
                      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        decoration: BoxDecoration(
                          color: message.isUser ? colorBut_greedot : Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          message.messageContent,
                          style: TextStyle(color: message.isUser ? Colors.white : Colors.black),
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