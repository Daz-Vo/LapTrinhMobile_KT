import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/exam_model.dart';
import '../services/api_service.dart';
import 'overview_modal.dart';
import 'exam_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  List<ExamListItem> _exams = [];
  bool _isLoading = true;
  String _searchQuery = '';

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await ApiService.getExams();
      if (!mounted) return;
      setState(() {
        _exams = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _openOverview(ExamListItem exam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OverviewModal(
        exam: exam,
        onBegin: (name, studentId) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExamScreen(
                examId: exam.id,
                studentName: name,
                studentCode: studentId,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredExams = _exams
        .where((e) => e.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Pinned Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: Color(0xF5FFFFFF),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                boxShadow: [
                  BoxShadow(color: Color(0x080F172A), blurRadius: 20, offset: Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MONDAY, 24 JUNE',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Good morning, Alex',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            "Ready for today's practice?",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(color: Color(0x402563EB), blurRadius: 16, offset: Offset(0, 5)),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'AM',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Box
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'Search reading tests...',
                              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            '⌘ K',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      onRefresh: _fetchExams,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), // Bottom padding so fixed bottom bar never overlaps
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats Card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE8EDF4)),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x0C0F172A), blurRadius: 24, offset: Offset(0, 8)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  _buildStatItem(
                                    icon: Icons.description_outlined,
                                    iconBg: const Color(0xFFEFF6FF),
                                    iconColor: AppColors.primary,
                                    val: '12',
                                    label: 'Tests done',
                                  ),
                                  _buildDivider(),
                                  _buildStatItem(
                                    icon: Icons.track_changes,
                                    iconBg: const Color(0xFFECFDF5),
                                    iconColor: const Color(0xFF059669),
                                    val: '81%',
                                    label: 'Avg. score',
                                  ),
                                  _buildDivider(),
                                  _buildStatItem(
                                    icon: Icons.auto_awesome,
                                    iconBg: const Color(0xFFFFFBEB),
                                    iconColor: const Color(0xFFD97706),
                                    val: '7 days',
                                    label: 'Best streak',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Section Title
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'KEEP IMPROVING',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Available Tests',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'View all',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Cards List
                            if (_errorMessage != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.cloud_off_rounded, color: Color(0xFFEF4444), size: 36),
                                    const SizedBox(height: 10),
                                    Text(
                                      _errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 14),
                                    ElevatedButton.icon(
                                      onPressed: _fetchExams,
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: const Text('Thử lại'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFEF4444),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (filteredExams.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(32),
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    const Icon(Icons.folder_open_rounded, color: Color(0xFF94A3B8), size: 40),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Chưa có đề thi nào trong CSDL.\nHãy tải lên đề thi qua trang Quản trị (/Exam/Upload).',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: _fetchExams,
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: const Text('Làm mới'),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...filteredExams.map((exam) => _buildTestCard(exam)),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),

      // Fixed Bottom Navigation Bar (Stick to bottom, never scrolls!)
      bottomNavigationBar: Container(
        height: 76,
        decoration: const BoxDecoration(
          color: Color(0xF5FFFFFF),
          border: Border(top: BorderSide(color: Color(0xFFE8EDF4))),
          boxShadow: [
            BoxShadow(color: Color(0x180F172A), blurRadius: 28, offset: Offset(0, -10)),
          ],
        ),
        child: Row(
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.history_rounded, 'Results'),
            _buildNavItem(2, Icons.person_outline_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String val,
    required String label,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  val,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 8.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFFEDF1F5),
    );
  }

  Widget _buildTestCard(ExamListItem exam) {
    bool isHard = exam.level.toLowerCase() == 'advanced';
    bool inProgress = exam.progress > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EBF1)),
        boxShadow: const [
          BoxShadow(color: Color(0x0C0F172A), blurRadius: 22, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.level.toUpperCase(),
                      style: TextStyle(
                        color: isHard ? const Color(0xFFD97706) : const Color(0xFF059669),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      exam.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: Color(0xFF94A3B8), size: 20),
            ],
          ),

          // Tags row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              children: [
                Text('${exam.totalQuestions} Questions', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                _buildDot(),
                Text('${exam.durationMinutes} Mins', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                _buildDot(),
                Text('Parts 5, 6, 7', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ],
            ),
          ),

          // Mini progress if active
          if (inProgress) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: LinearProgressIndicator(
                      value: exam.progress / 100,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${exam.progress}% complete',
                  style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: inProgress
                ? OutlinedButton(
                    onPressed: () => _openOverview(exam),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFDBE4F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continue Test', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => _openOverview(exam),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: const Color(0x332563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Start Test', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 7),
      decoration: const BoxDecoration(color: Color(0xFFCBD5E1), shape: BoxShape.circle),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isActive = _currentNavIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _currentNavIndex = index);
        },
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            if (isActive)
              Container(
                width: 28,
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? AppColors.primary : const Color(0xFF94A3B8),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.primary : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
