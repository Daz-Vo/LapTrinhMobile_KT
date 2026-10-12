import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/exam_model.dart';
import '../data/local_exam_data.dart';

class ApiService {
  // =========================================================================
  // NƠI CẤU HÌNH ĐỊA CHỈ IP / DOMAIN CỦA MÁY CHỦ WEB API
  // - Chạy trên Chrome / Web / Linux Desktop : 'http://localhost:5000/api/exams'
  // - Chạy trên máy ảo Android Emulator       : 'http://10.0.2.2:5000/api/exams'
  // - Chạy trên điện thoại di động thật       : 'http://<IP_LAN_MAY_TINH>:5000/api/exams'
  // =========================================================================
  static String baseUrl = 'http://localhost:5000/api/exams';

  /// 1. Lấy danh sách đề thi từ CSDL SQL Server (thông qua Web API)
  static Future<List<ExamListItem>> getExams() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => ExamListItem.fromJson(e)).toList();
      }
    } catch (_) {
      // Nếu Backend chưa bật hoặc lỗi mạng, tự động dùng dataset dự phòng
    }
    return LocalExamRepository.getExamList();
  }

  /// 2. Lấy chi tiết đề thi gồm 100 câu hỏi từ CSDL SQL Server
  static Future<ExamDetailModel> getExamDetail(int examId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/$examId'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ExamDetailModel.fromJson(data);
      }
    } catch (_) {
      // Fallback nếu không có mạng
    }
    return LocalExamRepository.getExamDetail();
  }

  /// 3. Nộp bài thi lên Web API để chấm điểm
  static Future<ExamResultModel?> submitExam({
    required int examId,
    required String studentName,
    required String studentCode,
    required Map<int, String?> answers,
  }) async {
    try {
      final answerList = answers.entries
          .map((e) => {
                'questionNumber': e.key,
                'selectedOption': e.value,
              })
          .toList();

      final body = jsonEncode({
        'examId': examId,
        'studentName': studentName,
        'studentCode': studentCode,
        'answers': answerList,
      });

      final response = await http
          .post(
            Uri.parse('$baseUrl/$examId/submit'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ExamResultModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }
}
