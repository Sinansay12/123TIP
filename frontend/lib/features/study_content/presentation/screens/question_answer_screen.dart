/// Question Answer Screen
/// Shows question result with explanation and "Go to Slide" button
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/slide_models.dart';

class QuestionAnswerScreen extends StatelessWidget {
  final SlideQuestion question;
  final String userAnswer;
  final bool isCorrect;
  final VoidCallback? onNextQuestion;
  final VoidCallback? onGoToSlide;

  const QuestionAnswerScreen({
    super.key,
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    this.onNextQuestion,
    this.onGoToSlide,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cevap'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Result indicator
              _buildResultIndicator(),
              
              const SizedBox(height: 24),
              
              // Question text
              Text(
                question.questionText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // User's answer
              _buildAnswerBox(
                label: 'Sizin Cevabınız',
                answer: userAnswer,
                isCorrect: isCorrect,
              ),
              
              const SizedBox(height: 12),
              
              // Correct answer (if wrong)
              if (!isCorrect)
                _buildAnswerBox(
                  label: 'Doğru Cevap',
                  answer: question.correctAnswer,
                  isCorrect: true,
                ),
              
              const SizedBox(height: 24),
              
              // Explanation
              if (question.explanation != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, 
                              color: AppTheme.accentOrange, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Açıklama',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        question.explanation!,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Action buttons
              Row(
                children: [
                  // Go to Slide button
                  if (question.slideId != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onGoToSlide ?? () {
                          // Navigate to slide
                          context.push('/slide/${question.slideId}');
                        },
                        icon: const Icon(Icons.slideshow),
                        label: const Text('İlgili Slayta Git'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                  
                  if (question.slideId != null && onNextQuestion != null)
                    const SizedBox(width: 12),
                  
                  // Next question button
                  if (onNextQuestion != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onNextQuestion,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Sonraki Soru'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: isCorrect
            ? const LinearGradient(
                colors: [Color(0xFF00C853), Color(0xFF00E676)],
              )
            : const LinearGradient(
                colors: [Color(0xFFFF5252), Color(0xFFFF8A80)],
              ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            isCorrect ? 'Doğru!' : 'Yanlış',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerBox({
    required String label,
    required String answer,
    required bool isCorrect,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppTheme.accentGreen.withAlpha(30)
            : AppTheme.errorColor.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? AppTheme.accentGreen : AppTheme.errorColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isCorrect ? AppTheme.accentGreen : AppTheme.errorColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
