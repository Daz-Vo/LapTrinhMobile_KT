import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam_model.dart';
import '../data/local_exam_data.dart';

class LocalHistoryService {
  static const String _keyAttempts = 'toeic_local_exam_attempts_v1';

  /// Tự động chấm điểm bài thi hoàn toàn độc lập (Offline / Local)
  static ExamResultModel gradeExamLocally({
    required int examId,
    required String studentName,
    required String studentCode,
    required Map<int, String?> answers,
  }) {
    final examDetail = LocalExamRepository.getExamDetail();
    
    // Flatten all questions
    final List<QuestionModel> allQuestions = [];
    for (var part in examDetail.parts) {
      for (var group in part.groups) {
        allQuestions.addAll(group.questions);
      }
    }
    allQuestions.sort((a, b) => a.questionNumber.compareTo(b.questionNumber));

    int totalCorrect = 0;
    int totalWrong = 0;
    int totalSkipped = 0;
    final List<QuestionResultDetail> details = [];

    for (var q in allQuestions) {
      final selected = answers[q.questionNumber]?.trim().toUpperCase();
      final correct = (q.correctOption ?? 'A').trim().toUpperCase();
      final bool isAnswered = selected != null && selected.isNotEmpty;

      bool isCorrect = false;
      if (!isAnswered) {
        totalSkipped++;
      } else if (selected == correct) {
        totalCorrect++;
        isCorrect = true;
      } else {
        totalWrong++;
      }

      details.add(QuestionResultDetail(
        questionId: q.id,
        questionNumber: q.questionNumber,
        questionContent: q.content,
        selectedOption: selected,
        correctOption: correct,
        isCorrect: isCorrect,
      ));
    }

    final int totalQuestions = allQuestions.isNotEmpty ? allQuestions.length : 100;
    final double accuracy = totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0.0;
    final int estimatedScore = _calculateToeicScore(totalCorrect);

    final result = ExamResultModel(
      attemptId: DateTime.now().millisecondsSinceEpoch,
      examId: examId,
      examTitle: examDetail.title,
      studentName: studentName.isNotEmpty ? studentName : 'Alex Morgan',
      totalCorrect: totalCorrect,
      totalWrong: totalWrong,
      totalSkipped: totalSkipped,
      totalQuestions: totalQuestions,
      estimatedScore: estimatedScore,
      accuracyPercentage: double.parse(accuracy.toStringAsFixed(1)),
      details: details,
    );

    return result;
  }

  /// Công thức quy đổi điểm TOEIC Reading chuẩn ETS (5 - 495 điểm)
  static int _calculateToeicScore(int correct) {
    if (correct <= 0) return 5;
    if (correct >= 98) return 495;
    if (correct >= 95) return 490;
    if (correct >= 90) return 465;
    if (correct >= 85) return 435;
    if (correct >= 80) return 400;
    if (correct >= 75) return 365;
    if (correct >= 70) return 335;
    if (correct >= 65) return 305;
    if (correct >= 60) return 275;
    if (correct >= 55) return 245;
    if (correct >= 50) return 215;
    if (correct >= 40) return 160;
    if (correct >= 30) return 110;
    if (correct >= 20) return 65;
    if (correct >= 10) return 25;
    return 5 + (correct * 2);
  }

  /// Lưu kết quả làm bài vào bộ nhớ cục bộ (SharedPreferences)
  static Future<void> saveAttempt(ExamResultModel attempt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList(_keyAttempts) ?? [];
      
      final map = {
        'attemptId': attempt.attemptId,
        'examId': attempt.examId,
        'examTitle': attempt.examTitle,
        'studentName': attempt.studentName,
        'totalCorrect': attempt.totalCorrect,
        'totalWrong': attempt.totalWrong,
        'totalSkipped': attempt.totalSkipped,
        'totalQuestions': attempt.totalQuestions,
        'estimatedScore': attempt.estimatedScore,
        'accuracyPercentage': attempt.accuracyPercentage,
        'timestamp': DateTime.now().toIso8601String(),
        'details': attempt.details.map((d) => {
          'questionId': d.questionId,
          'questionNumber': d.questionNumber,
          'questionContent': d.questionContent,
          'selectedOption': d.selectedOption,
          'correctOption': d.correctOption,
          'isCorrect': d.isCorrect,
        }).toList(),
      };

      list.insert(0, jsonEncode(map));
      // Giữ tối đa 50 lần làm bài gần nhất
      if (list.length > 50) {
        list.removeRange(50, list.length);
      }

      await prefs.setStringList(_keyAttempts, list);
    } catch (_) {}
  }

  /// Lấy lượt làm bài gần nhất (nếu có)
  static Future<ExamResultModel?> getLatestAttempt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? list = prefs.getStringList(_keyAttempts);
      if (list != null && list.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(list.first);
        return ExamResultModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Lấy tất cả các lượt làm bài trong lịch sử
  static Future<List<ExamResultModel>> getAllAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? list = prefs.getStringList(_keyAttempts);
      if (list != null && list.isNotEmpty) {
        return list
            .map((str) => ExamResultModel.fromJson(jsonDecode(str) as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
