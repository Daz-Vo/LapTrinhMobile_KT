import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/exam_model.dart';

class QuestionPaletteSheet extends StatelessWidget {
  final List<QuestionModel> questions;
  final int currentQuestionIndex;
  final Function(int) onSelectQuestion;

  const QuestionPaletteSheet({
    super.key,
    required this.questions,
    required this.currentQuestionIndex,
    required this.onSelectQuestion,
  });

  @override
  Widget build(BuildContext context) {
    int answeredCount = questions.where((q) => q.selectedOption != null && q.selectedOption!.isNotEmpty).length;
    int flaggedCount = questions.where((q) => q.isFlagged).length;
    int remainingCount = questions.length - answeredCount;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QUICK NAVIGATION',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Question palette',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Summary pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryDot(const Color(0xFF10B981), '$answeredCount Answered'),
                _buildSummaryDot(const Color(0xFFF59E0B), '$flaggedCount Flagged'),
                _buildSummaryDot(const Color(0xFF94A3B8), '$remainingCount Remaining', isBorder: true),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Scrollable Grid of Questions
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPartSection('Part 5', 'Questions 101–130', 101, 130),
                  const SizedBox(height: 16),
                  _buildPartSection('Part 6', 'Questions 131–146', 131, 146),
                  const SizedBox(height: 16),
                  _buildPartSection('Part 7', 'Questions 147–200', 147, 200),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Done button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'Back to Question ${questions[currentQuestionIndex].questionNumber}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDot(Color color, String label, {bool isBorder = false}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isBorder ? Colors.white : color,
            border: isBorder ? Border.all(color: color, width: 1.5) : null,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPartSection(String title, String subtitle, int startNum, int endNum) {
    var partQuestions = questions.where((q) => q.questionNumber >= startNum && q.questionNumber <= endNum).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: partQuestions.length,
          itemBuilder: (context, idx) {
            var q = partQuestions[idx];
            int globalIndex = questions.indexOf(q);
            bool isCurrent = globalIndex == currentQuestionIndex;
            bool isAnswered = q.selectedOption != null && q.selectedOption!.isNotEmpty;
            bool isFlagged = q.isFlagged;

            Color bgColor = Colors.white;
            Color textColor = AppColors.textSecondary;
            Border? border = Border.all(color: const Color(0xFFDBE4F0));

            if (isAnswered) {
              bgColor = const Color(0xFFECFDF5);
              textColor = const Color(0xFF047857);
              border = Border.all(color: const Color(0xFFA7F3D0));
            } else if (isFlagged) {
              bgColor = const Color(0xFFFFFBEB);
              textColor = const Color(0xFFB45309);
              border = Border.all(color: const Color(0xFFFDE68A));
            }

            return InkWell(
              onTap: () {
                onSelectQuestion(globalIndex);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(9),
                  border: isCurrent ? Border.all(color: AppColors.primary, width: 2) : border,
                ),
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        '${q.questionNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isCurrent ? AppColors.primary : textColor,
                        ),
                      ),
                    ),
                    if (isFlagged)
                      const Positioned(
                        top: 2,
                        right: 3,
                        child: Text(
                          '★',
                          style: TextStyle(color: Color(0xFFF59E0B), fontSize: 8),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
