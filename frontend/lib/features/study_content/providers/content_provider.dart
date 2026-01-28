/// Content Provider for Study Materials
/// Manages slides and past exams for each department
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/slide_models.dart';

/// Content types
enum ContentType { slide, pastExam, note }

/// Study content model
class StudyContent {
  final String id;
  final String title;
  final String department;
  final ContentType type;
  final String filePath;
  final String? professor;
  final DateTime? addedDate;

  StudyContent({
    required this.id,
    required this.title,
    required this.department,
    required this.type,
    required this.filePath,
    this.professor,
    this.addedDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'department': department,
    'type': type.name,
    'filePath': filePath,
    'professor': professor,
    'addedDate': addedDate?.toIso8601String(),
  };

  factory StudyContent.fromJson(Map<String, dynamic> json) => StudyContent(
    id: json['id'],
    title: json['title'],
    department: json['department'],
    type: ContentType.values.byName(json['type']),
    filePath: json['filePath'],
    professor: json['professor'],
    addedDate: json['addedDate'] != null ? DateTime.parse(json['addedDate']) : null,
  );
}

/// 5. sınıf staj grupları (departmanları)
final fifthYearDepartments = [
  'Adli Tıp',
  'Anestezi ve Reanimasyon',
  'Dermatoloji',
  'Fizik Tedavi ve Rehabilitasyon',
  'Göz',
  'Göğüs Cerrahisi',
  'Göğüs Hastalıkları',
  'Halk Sağlığı',
  'Kalp ve Damar Cerrahisi',
  'Nöroşiruji',
  'Plastik',
  'Psikiyatri',
  'Kardiyoloji',
  'Kulak Burun Boğaz',
  'Nöroloji',
  'Ortopedi ve Travmatoloji',
];

/// Department list provider - fetches from API
final departmentsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.getSlideDepartments();
    final departments = (response['departments'] as List).cast<String>();
    return departments;
  } catch (e) {
    // Return default departments on error
    return fifthYearDepartments;
  }
});

/// Topic with slide count
class DepartmentTopic {
  final String topic;
  final int slideCount;
  final String? professor;

  DepartmentTopic({
    required this.topic,
    required this.slideCount,
    this.professor,
  });

  factory DepartmentTopic.fromJson(Map<String, dynamic> json) => DepartmentTopic(
    topic: json['topic'] ?? '',
    slideCount: json['slide_count'] ?? 0,
    professor: json['professor'],
  );
}

/// Topics provider for a department
final departmentTopicsProvider = FutureProvider.family<List<DepartmentTopic>, String>((ref, department) async {
  try {
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.getDepartmentTopics(department);
    final topics = (response['topics'] as List)
        .map((t) => DepartmentTopic.fromJson(t))
        .toList();
    return topics;
  } catch (e) {
    return [];
  }
});

/// Topic slides provider
final topicSlidesProvider = FutureProvider.family<List<Slide>, ({String department, String topic})>((ref, params) async {
  try {
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.getTopicSlides(params.department, params.topic);
    final slides = (response['slides'] as List)
        .map((s) => Slide.fromJson(s))
        .toList();
    return slides;
  } catch (e) {
    return [];
  }
});

/// Department questions provider - for past exams tab
final departmentQuestionsProvider = FutureProvider.family<List<SlideQuestion>, String>((ref, department) async {
  try {
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.getDepartmentQuestions(department);
    final questions = (response['questions'] as List)
        .map((q) => SlideQuestion.fromJson(q))
        .toList();
    return questions;
  } catch (e) {
    return [];
  }
});

/// Department content provider (legacy - for backward compatibility)
final departmentContentProvider = StateNotifierProvider<DepartmentContentNotifier, Map<String, List<StudyContent>>>((ref) {
  return DepartmentContentNotifier();
});

class DepartmentContentNotifier extends StateNotifier<Map<String, List<StudyContent>>> {
  DepartmentContentNotifier() : super({});

  /// Get content for a specific department
  List<StudyContent> getContentForDepartment(String department) {
    return state[department] ?? [];
  }

  /// Get slides for a department
  List<StudyContent> getSlidesForDepartment(String department) {
    return getContentForDepartment(department)
        .where((c) => c.type == ContentType.slide)
        .toList();
  }

  /// Get past exams for a department
  List<StudyContent> getPastExamsForDepartment(String department) {
    return getContentForDepartment(department)
        .where((c) => c.type == ContentType.pastExam)
        .toList();
  }

  /// Add content
  void addContent(StudyContent content) {
    final departmentContent = List<StudyContent>.from(state[content.department] ?? []);
    departmentContent.add(content);
    state = {...state, content.department: departmentContent};
  }

  /// Load content from storage/API
  Future<void> loadContent() async {
    // Content is now loaded via departmentsProvider and topicSlidesProvider
  }
}

/// Selected department provider
final selectedDepartmentProvider = StateProvider<String?>((ref) => null);

/// Selected topic provider
final selectedTopicProvider = StateProvider<String?>((ref) => null);
