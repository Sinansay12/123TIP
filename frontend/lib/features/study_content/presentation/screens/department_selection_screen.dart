/// Department Selection Screen
/// Shows all 5th year departments for study material selection
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/content_provider.dart';
import 'study_content_screen.dart';

class DepartmentSelectionScreen extends ConsumerWidget {
  const DepartmentSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('5. Sınıf Staj Grupları'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: fifthYearDepartments.length,
        itemBuilder: (context, index) {
          final department = fifthYearDepartments[index];
          return _DepartmentCard(
            department: department,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudyContentScreen(department: department),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final String department;
  final VoidCallback onTap;

  const _DepartmentCard({
    required this.department,
    required this.onTap,
  });

  IconData _getDepartmentIcon() {
    switch (department) {
      case 'Adli Tıp':
        return Icons.gavel;
      case 'Anestezi ve Reanimasyon':
        return Icons.air;
      case 'Dermatoloji':
        return Icons.face;
      case 'Fizik Tedavi ve Rehabilitasyon':
        return Icons.accessibility_new;
      case 'Göz':
        return Icons.visibility;
      case 'Göğüs Cerrahisi':
      case 'Göğüs Hastalıkları':
        return Icons.airline_seat_flat;
      case 'Halk Sağlığı':
        return Icons.public;
      case 'Kalp ve Damar Cerrahisi':
      case 'Kardiyoloji':
        return Icons.favorite;
      case 'Nöroşiruji':
      case 'Nöroloji':
        return Icons.psychology;
      case 'Plastik':
        return Icons.face_retouching_natural;
      case 'Psikiyatri':
        return Icons.self_improvement;
      case 'Kulak Burun Boğaz':
        return Icons.hearing;
      case 'Ortopedi ve Travmatoloji':
        return Icons.sports_martial_arts;
      default:
        return Icons.local_hospital;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.darkCard,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getDepartmentIcon(), color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      department,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Slaytlar ve Çıkmış Sorular',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
