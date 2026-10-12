import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/exam_model.dart';
import '../services/api_service.dart';
import '../services/local_history_service.dart';
import 'question_palette_sheet.dart';
import 'result_screen.dart';
import 'home_screen.dart';

class ExamScreen extends StatefulWidget {
  final int examId;
  final String studentName;
  final String studentCode;

  const ExamScreen({
    super.key,
    required this.examId,
    required this.studentName,
    required this.studentCode,
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  bool _isLoading = true;
  ExamDetailModel? _exam;
  List<QuestionModel> _questions = [];
  int _currentIndex = 0;
  int _currentPart = 5;

  // Timer
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = 75 * 60; // 75 minutes
    _loadExam();
  }

  Future<void> _loadExam() async {
    final exam = await ApiService.getExamDetail(widget.examId);
    if (!mounted) return;

    setState(() {
      _exam = exam;
      _questions = exam.getAllQuestions();
      _remainingSeconds = exam.durationMinutes * 60;
      _isLoading = false;
      _updateCurrentPart();
    });

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        _timer?.cancel();
        _submitTest();
      }
    });
  }

  void _updateCurrentPart() {
    if (_questions.isEmpty) return;
    int qNum = _questions[_currentIndex].questionNumber;
    if (qNum <= 130) {
      _currentPart = 5;
    } else if (qNum <= 146) {
      _currentPart = 6;
    } else {
      _currentPart = 7;
    }
  }

  void _switchPart(int partNumber) {
    int targetStart = partNumber == 5 ? 101 : (partNumber == 6 ? 131 : 147);
    int idx = _questions.indexWhere((q) => q.questionNumber >= targetStart);
    if (idx != -1) {
      setState(() {
        _currentIndex = idx;
        _currentPart = partNumber;
      });
    }
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  GroupModel? _getCurrentGroup() {
    if (_exam == null) return null;
    int qNum = _questions[_currentIndex].questionNumber;
    for (var part in _exam!.parts) {
      for (var group in part.groups) {
        if (group.questions.any((q) => q.questionNumber == qNum)) {
          return group;
        }
      }
    }
    return null;
  }

  void _selectOption(String label) {
    setState(() {
      if (_questions[_currentIndex].selectedOption == label) {
        _questions[_currentIndex].selectedOption = null;
      } else {
        _questions[_currentIndex].selectedOption = label;
      }
    });
  }

  void _toggleFlag() {
    setState(() {
      _questions[_currentIndex].isFlagged = !_questions[_currentIndex].isFlagged;
    });
  }

  Future<void> _submitTest() async {
    _timer?.cancel();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    Map<int, String?> answerMap = {};
    for (var q in _questions) {
      answerMap[q.questionNumber] = q.selectedOption;
    }

    // Nộp bài lên Web API (chấm điểm từ CSDL) hoặc tự động chấm fallback nếu offline
    final ExamResultModel finalResult = (await ApiService.submitExam(
          examId: widget.examId,
          studentName: widget.studentName,
          studentCode: widget.studentCode,
          answers: answerMap,
        )) ??
        LocalHistoryService.gradeExamLocally(
          examId: widget.examId,
          studentName: widget.studentName,
          studentCode: widget.studentCode,
          answers: answerMap,
        );

    // Lưu vào lịch sử cục bộ của App
    await LocalHistoryService.saveAttempt(finalResult);

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (ctx) => ResultScreen(
          result: finalResult,
          onHome: () {
            Navigator.of(ctx).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  void _confirmSubmit() {
    int answered = _questions.where((q) => q.selectedOption != null && q.selectedOption!.isNotEmpty).length;
    int remaining = _questions.length - answered;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Submit Exam?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          remaining > 0
              ? 'You have answered $answered/${_questions.length} questions. You still have $remaining unanswered questions left. Are you sure you want to submit now?'
              : 'You have completed all ${_questions.length} questions. Are you sure you want to submit now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Test'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitTest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Now'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No questions available in this test.'),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final currentQ = _questions[_currentIndex];
    final currentGroup = _getCurrentGroup();
    final hasPassage = currentGroup != null && (currentGroup.passageText?.trim().isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Exam Topbar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Exit Exam?'),
                          content: const Text('Your exam progress will not be saved if you leave now.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Stay')),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                              },
                              child: const Text('Exit', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${currentQ.questionNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                        ),
                        Text(
                          'of ${_questions.length}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  // Timer badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, color: Color(0xFFB45309), size: 14),
                        const SizedBox(width: 5),
                        Text(
                          _formatTime(_remainingSeconds),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: _confirmSubmit,
                    child: const Text(
                      'Submit',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // Progress line
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              minHeight: 3,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),

            // Part Tabs
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [5, 6, 7].map((partNum) {
                  bool isActive = _currentPart == partNum;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _switchPart(partNum),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: isActive
                              ? const [BoxShadow(color: Color(0x140F172A), blurRadius: 8, offset: Offset(0, 2))]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Part $partNum',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isActive ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Exam Scroll Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reading passage if present
                    if (hasPassage) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0A0F172A), blurRadius: 18, offset: Offset(0, 6)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFBFDFF),
                                border: Border(bottom: BorderSide(color: Color(0xFFEDF1F5))),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    currentGroup.groupCode ?? 'Reading passage',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const Row(
                                    children: [
                                      Text(
                                        'Passage',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                      ),
                                      Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primary),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                currentGroup.passageText ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.6,
                                  color: Color(0xFF3D4A5D),
                                  fontFamily: 'serif',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Question stem
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${currentQ.questionNumber}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentQ.content,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 4 Options
                    ...currentQ.options.map((opt) {
                      bool isSelected = currentQ.selectedOption == opt.optionLabel;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => _selectOption(opt.optionLabel),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : const Color(0xFFDFE6EF),
                                width: isSelected ? 1.8 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? const [BoxShadow(color: Color(0x223B82F6), blurRadius: 8, offset: Offset(0, 2))]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    opt.optionLabel,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    opt.content,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: isSelected
                                      ? Container(
                                          width: 9,
                                          height: 9,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Exam Footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                boxShadow: [
                  BoxShadow(color: Color(0x0F0F172A), blurRadius: 25, offset: Offset(0, -8)),
                ],
              ),
              child: Column(
                children: [
                  // Tools row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _toggleFlag,
                        icon: Icon(
                          currentQ.isFlagged ? Icons.bookmark : Icons.bookmark_border,
                          size: 18,
                          color: currentQ.isFlagged ? const Color(0xFFD97706) : AppColors.textSecondary,
                        ),
                        label: Text(
                          currentQ.isFlagged ? 'Flagged' : 'Flag for review',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: currentQ.isFlagged ? const Color(0xFFD97706) : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => QuestionPaletteSheet(
                              questions: _questions,
                              currentQuestionIndex: _currentIndex,
                              onSelectQuestion: (index) {
                                setState(() {
                                  _currentIndex = index;
                                  _updateCurrentPart();
                                });
                              },
                            ),
                          );
                        },
                        icon: const Icon(Icons.grid_view_rounded, size: 18, color: AppColors.textSecondary),
                        label: const Text(
                          'Question palette',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Navigation row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _currentIndex > 0
                              ? () {
                                  setState(() {
                                    _currentIndex--;
                                    _updateCurrentPart();
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                          label: const Text('Previous', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: Color(0xFFDBE4F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentIndex < _questions.length - 1) {
                              setState(() {
                                _currentIndex++;
                                _updateCurrentPart();
                              });
                            } else {
                              _confirmSubmit();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentIndex < _questions.length - 1 ? 'Next' : 'Submit',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                _currentIndex < _questions.length - 1 ? Icons.arrow_forward : Icons.check,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
