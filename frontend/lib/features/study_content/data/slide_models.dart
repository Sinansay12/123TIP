/// Slide data models for in-app content viewing
library;

import 'package:flutter/foundation.dart';

/// Single slide page model
class Slide {
  final int id;
  final String department;
  final String topic;
  final int pageNumber;
  final String? title;
  final String content;
  final List<String>? bulletPoints;
  final String? imageUrl;
  final String? professor;

  const Slide({
    required this.id,
    required this.department,
    required this.topic,
    required this.pageNumber,
    this.title,
    required this.content,
    this.bulletPoints,
    this.imageUrl,
    this.professor,
  });

  factory Slide.fromJson(Map<String, dynamic> json) {
    return Slide(
      id: json['id'],
      department: json['department'],
      topic: json['topic'],
      pageNumber: json['page_number'],
      title: json['title'],
      content: json['content'],
      bulletPoints: json['bullet_points'] != null 
          ? List<String>.from(json['bullet_points']) 
          : null,
      imageUrl: json['image_url'],
      professor: json['professor'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'department': department,
    'topic': topic,
    'page_number': pageNumber,
    'title': title,
    'content': content,
    'bullet_points': bulletPoints,
    'image_url': imageUrl,
    'professor': professor,
  };
}

/// Topic with slide count
class SlideTopic {
  final String topic;
  final int slideCount;
  final String? professor;

  const SlideTopic({
    required this.topic,
    required this.slideCount,
    this.professor,
  });

  factory SlideTopic.fromJson(Map<String, dynamic> json) {
    return SlideTopic(
      topic: json['topic'],
      slideCount: json['slide_count'],
      professor: json['professor'],
    );
  }
}

/// Question with slide reference
class SlideQuestion {
  final int id;
  final String questionText;
  final String correctAnswer;
  final List<String> distractors;
  final String? explanation;
  final int? slideId;  // İlgili slayt için
  final String? department;
  final String? topic;
  final bool isPastPaper;

  const SlideQuestion({
    required this.id,
    required this.questionText,
    required this.correctAnswer,
    required this.distractors,
    this.explanation,
    this.slideId,
    this.department,
    this.topic,
    this.isPastPaper = false,
  });

  factory SlideQuestion.fromJson(Map<String, dynamic> json) {
    return SlideQuestion(
      id: json['id'],
      questionText: json['question_text'],
      correctAnswer: json['correct_answer'],
      distractors: List<String>.from(json['distractors'] ?? []),
      explanation: json['explanation'],
      slideId: json['slide_id'],
      department: json['department'],
      topic: json['topic'],
      isPastPaper: json['is_past_paper'] ?? false,
    );
  }
}
