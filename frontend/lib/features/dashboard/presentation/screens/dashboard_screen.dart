/// Dashboard Screen - Main home with Daily Mix and Exam Countdown
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/network/api_client.dart';

// Providers
final dailyMixProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getDailyMix();
});

final examsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getExams();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyMixAsync = ref.watch(dailyMixProvider);
    
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dailyMixProvider);
            ref.invalidate(examsProvider);
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Merhaba 👋',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                AppTheme.primaryGradient.createShader(bounds),
                            child: const Text(
                              'Bugün ne çalışacaksın?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.darkCard,
                        child: const Icon(Icons.person_outline),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Exam Countdown Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: dailyMixAsync.when(
                    data: (data) => _ExamCountdownCard(
                      examName: data['exam_name'] ?? 'Sınav yok',
                      daysRemaining: data['days_remaining'] ?? -1,
                      mode: data['mode'] ?? 'free_study',
                      pastPapersUnlocked: data['past_papers_unlocked'] ?? false,
                    ),
                    loading: () => const _LoadingCard(),
                    error: (e, _) => _ErrorCard(message: e.toString()),
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              
              // Daily Mix Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Günlük Mix 🎯',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.quiz),
                        child: const Text('Tümünü Çöz'),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              
              // Question Preview Cards
              SliverToBoxAdapter(
                child: dailyMixAsync.when(
                  data: (data) {
                    final questions = data['questions'] as List? ?? [];
                    return SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: questions.length > 5 ? 5 : questions.length,
                        itemBuilder: (context, index) {
                          final q = questions[index];
                          return _QuestionPreviewCard(
                            index: index + 1,
                            questionText: q['question_text'] ?? '',
                            difficulty: q['difficulty'] ?? 'medium',
                            onTap: () => context.go(AppRoutes.quiz),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => const SizedBox.shrink(),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              
              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Hızlı Erişim',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.3,
                  ),
                  delegate: SliverChildListDelegate([
                    _QuickActionCard(
                      icon: Icons.timer_outlined,
                      title: 'Pomodoro',
                      subtitle: '25 dk odaklan',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                      ),
                      onTap: () => context.go(AppRoutes.pomodoro),
                    ),
                    _QuickActionCard(
                      icon: Icons.quiz_outlined,
                      title: 'Soru Çöz',
                      subtitle: 'Günlük mix',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                      ),
                      onTap: () => context.go(AppRoutes.quiz),
                    ),
                    _QuickActionCard(
                      icon: Icons.menu_book_outlined,
                      title: 'Çalışma Materyalleri',
                      subtitle: 'Slaytlar & Çıkmışlar',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                      ),
                      onTap: () => context.go(AppRoutes.studyContent),
                    ),
                    _QuickActionCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Sınav Ekle',
                      subtitle: 'Tarih belirle',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE66D), Color(0xFFFF6B6B)],
                      ),
                      onTap: () => _showAddExamDialog(context, ref),
                    ),
                  ]),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      
      // FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.quiz),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Çalışmaya Başla'),
      ),
    );
  }
  
  void _showAddExamDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sınav Ekle',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Sınav Adı',
                hintText: 'Örn: Dahiliye Vize',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sınav Tarihi'),
              subtitle: Text(
                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  selectedDate = date;
                }
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    final api = ref.read(apiServiceProvider);
                    await api.createExam(
                      examName: nameController.text,
                      examDate: selectedDate,
                    );
                    ref.invalidate(dailyMixProvider);
                    ref.invalidate(examsProvider);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ WIDGET COMPONENTS ============

class _ExamCountdownCard extends StatelessWidget {
  final String examName;
  final int daysRemaining;
  final String mode;
  final bool pastPapersUnlocked;

  const _ExamCountdownCard({
    required this.examName,
    required this.daysRemaining,
    required this.mode,
    required this.pastPapersUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final isCramming = mode == 'cramming';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isCramming
            ? const LinearGradient(colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)])
            : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isCramming ? const Color(0xFFFF416C) : AppTheme.primaryColor)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCramming ? '🔥 Yoğun Mod' : '📚 Genel Tekrar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  examName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (pastPapersUnlocked)
                  const Row(
                    children: [
                      Icon(Icons.lock_open, color: Colors.white70, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Çıkmış sorular açık!',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  daysRemaining >= 0 ? '$daysRemaining' : '∞',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'gün',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionPreviewCard extends StatelessWidget {
  final int index;
  final String questionText;
  final String difficulty;
  final VoidCallback onTap;

  const _QuestionPreviewCard({
    required this.index,
    required this.questionText,
    required this.difficulty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                _DifficultyBadge(difficulty: difficulty),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                questionText,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;

  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = AppTheme.accentGreen;
        label = 'Kolay';
        break;
      case 'hard':
        color = AppTheme.errorColor;
        label = 'Zor';
        break;
      default:
        color = AppTheme.accentOrange;
        label = 'Orta';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('Veri yüklenemedi'),
    );
  }
}
