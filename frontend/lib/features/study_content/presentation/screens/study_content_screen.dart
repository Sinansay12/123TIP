/// Study Content Screen
/// Shows slides and past exams for selected department
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/content_provider.dart';
import '../../data/slide_models.dart';
import 'slide_viewer_screen.dart';

class StudyContentScreen extends ConsumerWidget {
  final String department;
  
  const StudyContentScreen({super.key, required this.department});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(departmentTopicsProvider(department));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(department),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.slideshow), text: 'Slaytlar'),
              Tab(icon: Icon(Icons.quiz), text: 'Çıkmış Sorular'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Slaytlar Tab
            _buildTopicsTab(context, ref, topicsAsync),
            // Çıkmış Sorular Tab
            _buildQuestionsTab(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsTab(BuildContext context, WidgetRef ref, AsyncValue<List<DepartmentTopic>> topicsAsync) {
    return topicsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Veriler yüklenemedi',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.refresh(departmentTopicsProvider(department)),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
      data: (topics) {
        if (topics.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'Henüz slayt eklenmedi',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: topics.length,
          itemBuilder: (context, index) {
            final topic = topics[index];
            return Card(
              color: AppTheme.darkCard,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.slideshow, color: Colors.white),
                ),
                title: Text(
                  topic.topic,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${topic.slideCount} slayt',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    if (topic.professor != null)
                      Text(
                        topic.professor!,
                        style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
                      ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openTopicSlides(context, ref, topic),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuestionsTab(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(departmentQuestionsProvider(department));
    
    return questionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Sorular yüklenemedi',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.refresh(departmentQuestionsProvider(department)),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
      data: (questions) {
        if (questions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz, size: 64, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'Henüz çıkmış soru eklenmedi',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final question = questions[index];
            return Card(
              color: AppTheme.darkCard,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Topic tag
                    if (question.topic != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withAlpha(50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          question.topic!,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    // Question text
                    Text(
                      question.questionText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Correct answer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.accentGreen, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              question.correctAnswer,
                              style: TextStyle(
                                color: AppTheme.accentGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Go to slide button
                    if (question.slideId != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.push('/slide/${question.slideId}');
                          },
                          icon: const Icon(Icons.slideshow, size: 18),
                          label: const Text('İlgili Slayta Git'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openTopicSlides(BuildContext context, WidgetRef ref, DepartmentTopic topic) {
    // Navigate to slide viewer with loading
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _SlidesLoaderScreen(
          department: department,
          topic: topic.topic,
        ),
      ),
    );
  }
}

/// Helper screen to load slides before showing viewer
class _SlidesLoaderScreen extends ConsumerWidget {
  final String department;
  final String topic;

  const _SlidesLoaderScreen({
    required this.department,
    required this.topic,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slidesAsync = ref.watch(topicSlidesProvider((department: department, topic: topic)));

    return Scaffold(
      appBar: AppBar(title: Text(topic)),
      body: slidesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Slaytlar yüklenemedi',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(topicSlidesProvider((department: department, topic: topic))),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
        data: (slides) {
          if (slides.isEmpty) {
            return Center(
              child: Text(
                'Bu konuda slayt bulunamadı',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }
          return SlideViewerScreen(
            topic: topic,
            slides: slides,
            department: department,
          );
        },
      ),
    );
  }
}
