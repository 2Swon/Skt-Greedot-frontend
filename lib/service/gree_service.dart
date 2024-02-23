import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import 'package:projectfront/service/user_service.dart';
import '../constants/constants.dart';
import 'dart:async';
import 'dart:convert';
import 'package:mime_type/mime_type.dart';
import 'package:logger/logger.dart';
import '../models/gree_model.dart';
import 'dart:convert';


class ApiServiceGree {
  static final Logger _logger = Logger();

  static Future<Map<String, dynamic>?> uploadImage(String imagePath) async {
    final url = Uri.parse('$baseUrl/api/v1/gree/upload-raw-img');
    final token = await AuthService.getToken();
    if (token == null) {
      _logger.e('No token found');
      return null;
    }

    File imageFile = File(imagePath);
    String fileName = basename(imagePath);
    String? mimeType = mime(imagePath);
    MediaType mediaType = MediaType.parse(mimeType ?? 'image/png');

    var request = http.MultipartRequest('POST', url)
      ..headers.addAll({'Authorization': 'Bearer $token'})
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: mediaType,
        filename: fileName,
      ));

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        _logger.i("Upload successful");
        var responseData = json.decode(response.body);
        // 전체 응답 데이터를 반환
        return responseData;
      } else {
        _logger.w("Upload failed with status: ${response.statusCode}");
        return null; // 실패 시 null 반환
      }
    } catch (e) {
      _logger.e("Error uploading image: $e");
      return null; // 예외 발생 시 null 반환
    }
  }


  static Future<void> updateGree(int greeId, GreeUpdate model) async {
    var url = '$baseUrl/api/v1/gree/update/$greeId';
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('no token');
    }
    var response = await http.put(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token",
        "Content-Type": "application/json"},
      body: json.encode(model.toJson()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('Gree updated successfully.');
    } else {
      print('Failed to update gree. StatusCode: ${response
          .statusCode}, Body: ${response.body}');
    }
  }


  static Future<List<Gree>> readGrees() async {
    var url = '$baseUrl/api/v1/gree/view';
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('no token');
    }
    var response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      // 서버로부터 받은 응답의 바디를 utf-8로 디코딩합니다.
      var decodedBody = utf8.decode(response.bodyBytes);
      List jsonResponse = json.decode(decodedBody);
      return jsonResponse.map((data) => Gree.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load grees.');
    }
  }



  static Future<dynamic> readGree(int greeId) async {
    var url = '$baseUrl/api/v1/gree/view/$greeId';
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('no token');
    }
    print('test');
    var response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    print(response.statusCode);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load gree.');
    }
  }


  static Future<void> disableGree(int greeId) async {
    var url = '$baseUrl/api/v1/gree/disable/$greeId';
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('no token');
    }
    var response = await http.put(Uri.parse(url));

    if (response.statusCode == 200) {
      print('Gree disabled successfully.');
    } else {
      print('Failed to disable gree.');
    }
  }

  // 이미지 처리 요청을 위한 함수
  static Future<void> processGreeImages(int greeId) async {
    final url = Uri.parse('$baseUrl/api/v1/gree/greefile/upload/$greeId');
    final token = await AuthService.getToken();
    if (token == null) {
      _logger.e('No token found');
      return;
    }

    try {
      var response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _logger.i("Image processing successful");
        // 성공 로직, 예: 성공 알림
      } else {
        _logger.w(
            "Image processing failed with status: ${response.statusCode}");
        // 실패 로직, 예: 실패 알림
      }
    } catch (e) {
      _logger.e("Error processing images: $e");
    }
  }


  static Future<void> uploadYamlFileToServer(String filePath,
      int greeId) async {
    final uri = Uri.parse('$baseUrl/api/v1/gree/greefile/upload_yaml/$greeId');
    final token = await AuthService.getToken(); // 인증 토큰 가져오기
    if (token == null) {
      print('No token found');
      return;
    }

    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', filePath))
      ..headers.addAll({
        'Authorization': 'Bearer $token', // 요청 헤더에 인증 토큰 추가
      });

    final response = await request.send();
    if (response.statusCode == 200) {
      print('yaml uploaded successfully');
    } else {
      print('yaml to upload file');
    }
  }

  static Future<void> uploadFilesToBackend(int greeId) async {
    var uri = Uri.parse(
        '$baseUrl/api/v1/gree/create-and-upload-assets/$greeId');
    final token = await AuthService.getToken(); // 인증 토큰 가져오기
    if (token == null) {
      print('No token found');
      return;
    }
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Authorization': 'Bearer $token', // 요청 헤더에 인증 토큰 추가
      });


    var response = await request.send();
    final responseString = await http.Response.fromStream(response);

    if (response.statusCode == 200) {
      print('gif uploaded successfully');
    } else {
      print('gif to upload files: ${response.statusCode}');
      print('Reason: ${responseString.body}');
    }
  }

  static Future<List<String>> fetchSentences(int greeId) async {
    final url = Uri.parse(
        '$baseUrl/api/v1/log/sentence/$greeId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      print('% sentence load success');
      final data = json.decode(utf8.decode(response.bodyBytes));
      List<String> sentences = List<String>.from(data['sentences']);
      return sentences;
    } else {
      // 오류 처리
      throw Exception('% Failed to load sentences');
    }
  }

  static Future<Map<String, dynamic>> makeEmotionReport(List<String> sentences, int greeId) async {
    final url = Uri.parse('$baseUrl/api/v1/ai/make-emotion-report/$greeId');
    print('Requesting URL: $url');

    final requestBody = json.encode({'sentences': sentences});
    print('Request Body: $requestBody');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    print('Response Status Code: ${response.statusCode}');
    try {
      final decodedBody = utf8.decode(response.bodyBytes);
      print('Response Body: $decodedBody');
      if (response.statusCode == 200) {
        print('make report success');
        return json.decode(decodedBody);
      } else {
        // 상태 코드가 200이 아닌 경우, 서버 응답 본문을 사용하여 예외를 발생시킵니다.
        throw Exception('Failed to make emotion report - Status Code: ${response.statusCode}, Body: $decodedBody');
      }
    } catch (e) {
      // 디코딩 과정에서 발생하는 예외를 처리합니다.
      print('Error during response processing: $e');
      throw Exception('Error during response processing - Status Code: ${response.statusCode}, Error: $e');
    }

  }



  static Future<List<Map<String, dynamic>>> fetchDialogLogs(int greeId) async {
    final url = Uri.parse('$baseUrl/api/v1/log/gree/$greeId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load dialog logs');
    }
  }

  static Future<String> fetchSummary(int greeId) async {
    // URL을 수정하여 함수명과 일치시키고, 충돌 가능성을 줄임
    final Uri url = Uri.parse('http://20.196.198.166:8001/emotion-summary/$greeId');
    try {
      final response = await http.post(
        url,
        headers: {'Accept': 'application/json'}, // 헤더의 키를 표준에 맞게 수정
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('Emotion summary load success'); // 성공 로그 추가
        return data['summary'];
      } else {
        print('Failed to load emotion summary: ${response.statusCode}'); // 실패 로그에 상태 코드 추가
        throw Exception('Failed to load emotion summary with status code: ${response.statusCode}');
      }
    } catch (e) {
      // 네트워크 요청 중 발생할 수 있는 예외를 처리
      print('Error fetching emotion summary: $e');
      throw Exception('Error fetching emotion summary: $e');
    }
  }


  static Future<String?> fetchSpecificGreeGif(int greeId) async {
    final url = Uri.parse('$baseUrl/api/v1/gree/getgif/$greeId');
    final token = await AuthService.getToken();
    if (token == null) {
      _logger.e('No token found');
      return null;
    }

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final gifInfo = jsonResponse.firstWhere(
              (gif) => gif['file_name'] == 'dab',
          orElse: () => null,
        );
        return gifInfo != null ? gifInfo['real_name'] : null;
      } else {
        _logger.w("Failed to fetch GIFs with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      _logger.e("Error fetching GIFs: $e");
      return null;
    }
  }


  static Future<Map<String, String>> fetchGreeGifs(int greeId) async {
    final url = Uri.parse('$baseUrl/api/v1/gree/getgif/$greeId');
    final token = await AuthService.getToken();
    if (token == null) {
      _logger.e('No token found');
      return {};
    }

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        // 모든 GIF 정보를 포함하는 맵을 반환합니다.
        return Map.fromIterable(jsonResponse, key: (gif) => gif['file_name'],
            value: (gif) => gif['real_name']);
      } else {
        _logger.w("Failed to fetch GIFs with status: ${response.statusCode}");
        return {};
      }
    } catch (e) {
      _logger.e("Error fetching GIFs: $e");
      return {};
    }
  }

  static Future<List<String>> fetchUploadedImages(int greeId, int promptSelect) async {
    var url = '$baseUrl/api/v1/gree/generate-and-upload-image/$greeId';
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('No token');
    }

    var body = jsonEncode({
      'promptSelect': promptSelect,
    });

    var response = await http.post(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: body,
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      List<String> uploadedUrls = List<String>.from(jsonResponse["uploaded_image_urls"]);
      return uploadedUrls;
    } else {
      throw Exception('Failed to fetch uploaded images.');
    }
  }
}

