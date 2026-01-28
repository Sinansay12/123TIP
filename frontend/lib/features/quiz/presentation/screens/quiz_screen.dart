/// Quiz Screen - Question solving with Smart Hints
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/network/api_client.dart';

// Quiz State
class QuizState {
  final List<dynamic> questions;
  final int currentIndex;
  final Map<int, String?> answers;
  final Map<int, bool?> results;
  final String? currentHint;
  final bool isLoading;

  const QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.answers = const {},
    this.results = const {},
    this.currentHint,
    this.isLoading = false,
  });

  QuizState copyWith({
    List<dynamic>? questions,
    int? currentIndex,
    Map<int, String?>? answers,
    Map<int, bool?>? results,
    String? currentHint,
    bool? isLoading,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      results: results ?? this.results,
      currentHint: currentHint,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic>? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get correctCount => results.values.where((v) => v == true).length;
  int get answeredCount => answers.length;
  bool get isComplete => currentIndex >= questions.length;
}

// Quiz Notifier
class QuizNotifier extends StateNotifier<QuizState> {
  final ApiService _api;

  QuizNotifier(this._api) : super(const QuizState());

  Future<void> loadQuestions() async {
    state = state.copyWith(isLoading: true);
    try {
      final dailyMix = await _api.getDailyMix();
      final questions = dailyMix['questions'] as List? ?? [];
      state = state.copyWith(
        questions: questions,
        currentIndex: 0,
        answers: {},
        results: {},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> selectAnswer(String answer) async {
    final question = state.currentQuestion;
    if (question == null) return;

    final questionId = question['id'] as int;
    final newAnswers = Map<int, String?>.from(state.answers);
    newAnswers[questionId] = answer;

    state = state.copyWith(answers: newAnswers);

    // Submit answer to backend
    try {
      final result = await _api.submitAnswer(questionId, answer);
      final newResults = Map<int, bool?>.from(state.results);
      newResults[questionId] = result['is_correct'] as bool;
      state = state.copyWith(results: newResults);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> requestHint() async {
    final question = state.currentQuestion;
    if (question == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final hint = await _api.getHint(question['id'] as int);
      state = state.copyWith(
        currentHint: hint['hint'] as String?,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        currentHint: null,
      );
    } else {
      state = state.copyWith(currentIndex: state.questions.length);
    }
  }

  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(
        currentIndex: state.currentIndex - 1,
        currentHint: null,
      );
    }
  }
}

// Provider
final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(ref.watch(apiServiceProvider));
});

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(quizProvider.notifier).loadQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);

    // Show results if complete
    if (quizState.isComplete && quizState.questions.isNotEmpty) {
      return _QuizCompleteScreen(
        score: quizState.correctCount,
        total: quizState.questions.length,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: quizState.questions.isNotEmpty
            ? Text('${quizState.currentIndex + 1} / ${quizState.questions.length}')
            : null,
        actions: [
          // Progress indicator
          if (quizState.questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 80,
                  child: LinearProgressIndicator(
                    value: (quizState.currentIndex + 1) / quizState.questions.length,
                    backgroundColor: AppTheme.darkBorder,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: quizState.isLoading && quizState.questions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : quizState.currentQuestion == null
              ? const Center(child: Text('Soru bulunamadı'))
              : _QuestionCard(quizState: quizState),
    );
  }
}

class _QuestionCard extends ConsumerWidget {
  final QuizState quizState;

  const _QuestionCard({required this.quizState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = quizState.currentQuestion!;
    final questionId = question['id'] as int;
    final selectedAnswer = quizState.answers[questionId];
    final isAnswered = selectedAnswer != null;
    final result = quizState.results[questionId];
    final choices = question['choices'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Difficulty badge
          _DifficultyBadge(difficulty: question['difficulty'] ?? 'medium'),
          const SizedBox(height: 16),

          // Question text
          Text(
            question['question_text'] ?? '',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  height: 1.4,
                ),
          ),

          const SizedBox(height: 32),

          // Answer choices
          ...choices.asMap().entries.map((entry) {
            final index = entry.key;
            final choice = entry.value.toString();
            final letter = String.fromCharCode(65 + index); // A, B, C, D
            final isSelected = selectedAnswer == choice;
            final isCorrect = isAnswered && result != null && choice == question['correct_answer'];
            final isWrong = isSelected && result == false;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AnswerChoice(
                letter: letter,
                text: choice,
                isSelected: isSelected,
                isCorrect: isCorrect,
                isWrong: isWrong,
                isDisabled: isAnswered,
                onTap: isAnswered
                    ? null
                    : () => ref.read(quizProvider.notifier).selectAnswer(choice),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Hint Section
          if (!isAnswered) ...[
            Center(
              child: OutlinedButton.icon(
                onPressed: quizState.isLoading
                    ? null
                    : () => ref.read(quizProvider.notifier).requestHint(),
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('İpucu Ver'),
              ),
            ),
          ],

          // Show hint if available
          if (quizState.currentHint != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentOrange.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb,
                    color: AppTheme.accentOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      quizState.currentHint!,
                      style: const TextStyle(
                        color: AppTheme.accentOrange,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Navigation and Go to Slide buttons (after answering)
          if (isAnswered) ...[
            // Explanation
            if (question['explanation'] != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Açıklama',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question['explanation'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Go to Slide button
            if (question['source_document_id'] != null &&
                question['page_number'] != null)
              OutlinedButton.icon(
                onPressed: () {
                  context.go(
                    '/pdf/${question['source_document_id']}?page=${question['page_number']}',
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('İlgili Slayta Git'),
              ),

            const SizedBox(height: 24),

            // Next button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => ref.read(quizProvider.notifier).nextQuestion(),
                child: Text(
                  quizState.currentIndex < quizState.questions.length - 1
                      ? 'Sonraki Soru'
                      : 'Sonuçları Gör',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerChoice extends StatelessWidget {
  final String letter;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _AnswerChoice({
    required this.letter,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.isDisabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppTheme.darkCard;
    Color borderColor = AppTheme.darkBorder;
    Color letterBgColor = AppTheme.darkSurface;

    if (isCorrect) {
      bgColor = AppTheme.accentGreen.withOpacity(0.15);
      borderColor = AppTheme.accentGreen;
      letterBgColor = AppTheme.accentGreen;
    } else if (isWrong) {
      bgColor = AppTheme.errorColor.withOpacity(0.15);
      borderColor = AppTheme.errorColor;
      letterBgColor = AppTheme.errorColor;
    } else if (isSelected) {
      borderColor = AppTheme.primaryColor;
      letterBgColor = AppTheme.primaryColor;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: letterBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    color: isSelected || isCorrect || isWrong
                        ? Colors.white
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (isCorrect)
              const Icon(Icons.check_circle, color: AppTheme.accentGreen)
            else if (isWrong)
              const Icon(Icons.cancel, color: AppTheme.errorColor),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _QuizCompleteScreen extends StatelessWidget {
  final int score;
  final int total;

  const _QuizCompleteScreen({required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    final percentage = (score / total * 100).round();
    final isGood = percentage >= 70;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Result Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: isGood
                      ? const LinearGradient(
                          colors: [AppTheme.accentGreen, Color(0xFF11998E)])
                      : const LinearGradient(
                          colors: [AppTheme.accentOrange, Color(0xFFFF6B6B)]),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGood ? Icons.emoji_events : Icons.school,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                isGood ? 'Harika! 🎉' : 'İyi çalışma!',
                style: Theme.of(context).textTheme.displayMedium,
              ),

              const SizedBox(height: 16),

              Text(
                '$score / $total doğru (%$percentage)',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),

              const SizedBox(height: 48),

              // Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.dashboard),
                  child: const Text('Ana Sayfaya Dön'),
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: () => context.go(AppRoutes.quiz),
                child: const Text('Tekrar Çöz'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
