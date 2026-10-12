class ExamListItem {
  final int id;
  final String title;
  final int durationMinutes;
  final int totalQuestions;
  final String? description;
  final int totalAttempts;
  final String level;
  final int progress;

  ExamListItem({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.totalQuestions,
    this.description,
    this.totalAttempts = 0,
    this.level = 'Intermediate',
    this.progress = 0,
  });

  factory ExamListItem.fromJson(Map<String, dynamic> json) {
    return ExamListItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'TOEIC Reading Test',
      durationMinutes: json['durationMinutes'] ?? 75,
      totalQuestions: json['totalQuestions'] ?? 100,
      description: json['description'],
      totalAttempts: json['totalAttempts'] ?? 0,
      level: (json['title']?.toString().contains('08') ?? false) ? 'Advanced' : 'Intermediate',
      progress: (json['title']?.toString().contains('08') ?? false) ? 42 : 0,
    );
  }
}

class OptionModel {
  final int id;
  final String optionLabel;
  final String content;

  OptionModel({
    required this.id,
    required this.optionLabel,
    required this.content,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      id: json['id'] ?? 0,
      optionLabel: json['optionLabel'] ?? json['label'] ?? '',
      content: json['content'] ?? '',
    );
  }
}

class QuestionModel {
  final int id;
  final int questionNumber;
  final String content;
  final String? correctOption;
  final int orderIndex;
  final List<OptionModel> options;
  
  // Local state during test
  String? selectedOption;
  bool isFlagged;

  QuestionModel({
    required this.id,
    required this.questionNumber,
    required this.content,
    this.correctOption,
    required this.orderIndex,
    required this.options,
    this.selectedOption,
    this.isFlagged = false,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    var rawOptions = json['options'] as List? ?? [];
    return QuestionModel(
      id: json['id'] ?? 0,
      questionNumber: json['questionNumber'] ?? 0,
      content: json['content'] ?? '',
      correctOption: json['correctOption'],
      orderIndex: json['orderIndex'] ?? 0,
      options: rawOptions.map((o) => OptionModel.fromJson(o)).toList(),
    );
  }
}

class GroupModel {
  final int id;
  final String? groupCode;
  final String? groupTitle;
  final String? passageText;
  final String? imageUrl;
  final int orderIndex;
  final List<QuestionModel> questions;

  GroupModel({
    required this.id,
    this.groupCode,
    this.groupTitle,
    this.passageText,
    this.imageUrl,
    required this.orderIndex,
    required this.questions,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    var rawQuestions = json['questions'] as List? ?? [];
    return GroupModel(
      id: json['id'] ?? 0,
      groupCode: json['groupCode'],
      groupTitle: json['groupTitle'],
      passageText: json['passageText'],
      imageUrl: json['imageUrl'],
      orderIndex: json['orderIndex'] ?? 0,
      questions: rawQuestions.map((q) => QuestionModel.fromJson(q)).toList(),
    );
  }
}

class PartModel {
  final int id;
  final int partNumber;
  final String name;
  final int questionStart;
  final int questionEnd;
  final List<GroupModel> groups;

  PartModel({
    required this.id,
    required this.partNumber,
    required this.name,
    required this.questionStart,
    required this.questionEnd,
    required this.groups,
  });

  factory PartModel.fromJson(Map<String, dynamic> json) {
    var rawGroups = json['groups'] as List? ?? [];
    return PartModel(
      id: json['id'] ?? 0,
      partNumber: json['partNumber'] ?? 0,
      name: json['name'] ?? '',
      questionStart: json['questionStart'] ?? 0,
      questionEnd: json['questionEnd'] ?? 0,
      groups: rawGroups.map((g) => GroupModel.fromJson(g)).toList(),
    );
  }
}

class ExamDetailModel {
  final int id;
  final String title;
  final int durationMinutes;
  final int totalQuestions;
  final List<PartModel> parts;

  ExamDetailModel({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.parts,
  });

  factory ExamDetailModel.fromJson(Map<String, dynamic> json) {
    var rawParts = json['parts'] as List? ?? [];
    return ExamDetailModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 75,
      totalQuestions: json['totalQuestions'] ?? 100,
      parts: rawParts.map((p) => PartModel.fromJson(p)).toList(),
    );
  }

  List<QuestionModel> getAllQuestions() {
    List<QuestionModel> list = [];
    for (var part in parts) {
      for (var group in part.groups) {
        list.addAll(group.questions);
      }
    }
    list.sort((a, b) => a.questionNumber.compareTo(b.questionNumber));
    return list;
  }
}

class QuestionResultDetail {
  final int questionId;
  final int questionNumber;
  final String questionContent;
  final String? selectedOption;
  final String? correctOption;
  final bool isCorrect;

  QuestionResultDetail({
    required this.questionId,
    required this.questionNumber,
    required this.questionContent,
    this.selectedOption,
    this.correctOption,
    required this.isCorrect,
  });

  factory QuestionResultDetail.fromJson(Map<String, dynamic> json) {
    return QuestionResultDetail(
      questionId: json['questionId'] ?? 0,
      questionNumber: json['questionNumber'] ?? 0,
      questionContent: json['questionContent'] ?? '',
      selectedOption: json['selectedOption'],
      correctOption: json['correctOption'],
      isCorrect: json['isCorrect'] ?? false,
    );
  }
}

class ExamResultModel {
  final int attemptId;
  final int examId;
  final String examTitle;
  final String studentName;
  final int totalCorrect;
  final int totalWrong;
  final int totalSkipped;
  final int totalQuestions;
  final int estimatedScore;
  final double accuracyPercentage;
  final List<QuestionResultDetail> details;

  ExamResultModel({
    required this.attemptId,
    required this.examId,
    required this.examTitle,
    required this.studentName,
    required this.totalCorrect,
    required this.totalWrong,
    required this.totalSkipped,
    required this.totalQuestions,
    required this.estimatedScore,
    required this.accuracyPercentage,
    required this.details,
  });

  factory ExamResultModel.fromJson(Map<String, dynamic> json) {
    var rawDetails = json['details'] as List? ?? [];
    return ExamResultModel(
      attemptId: json['attemptId'] ?? 0,
      examId: json['examId'] ?? 0,
      examTitle: json['examTitle'] ?? '',
      studentName: json['studentName'] ?? 'Thí sinh',
      totalCorrect: json['totalCorrect'] ?? 0,
      totalWrong: json['totalWrong'] ?? 0,
      totalSkipped: json['totalSkipped'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 100,
      estimatedScore: json['estimatedScore'] ?? 5,
      accuracyPercentage: (json['accuracyPercentage'] as num?)?.toDouble() ?? 0.0,
      details: rawDetails.map((d) => QuestionResultDetail.fromJson(d)).toList(),
    );
  }
}
