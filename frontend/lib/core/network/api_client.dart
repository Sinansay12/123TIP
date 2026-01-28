/// API Client Configuration using Dio
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = 'https://one23tip-backend.onrender.com/api/v1';

/// Secure storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Auth token provider
final authTokenProvider = StateProvider<String?>((ref) => null);

/// Dio client provider with interceptors
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));
  
  // Add auth interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authTokenProvider);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Handle token expiration
          ref.read(authTokenProvider.notifier).state = null;
        }
        handler.next(error);
      },
    ),
  );
  
  // Add logging interceptor in debug mode
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));
  
  return dio;
});

/// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider));
});

/// API Service wrapper
class ApiService {
  final Dio _dio;
  
  ApiService(this._dio);
  
  // AUTH
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'username': email,  // OAuth2 uses 'username' field
      'password': password,
    }, options: Options(contentType: Headers.formUrlEncodedContentType));
    return response.data;
  }
  
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required int term,
    String? studyGroup,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'term': term,
      'study_group': studyGroup,
    });
    return response.data;
  }
  
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }
  
  // COURSES
  Future<List<dynamic>> getCourses({int? term}) async {
    final response = await _dio.get('/courses', queryParameters: {
      if (term != null) 'term': term,
    });
    return response.data;
  }
  
  // EXAMS
  Future<Map<String, dynamic>> createExam({
    required String examName,
    required DateTime examDate,
    int? courseId,
  }) async {
    final response = await _dio.post('/exams/', data: {
      'exam_name': examName,
      'exam_date': examDate.toIso8601String(),
      if (courseId != null) 'course_id': courseId,
    });
    return response.data;
  }
  
  Future<List<dynamic>> getExams() async {
    final response = await _dio.get('/exams/');
    return response.data;
  }
  
  Future<Map<String, dynamic>> getDailyMix() async {
    final response = await _dio.get('/exams/daily');
    return response.data;
  }
  
  // QUESTIONS
  Future<List<dynamic>> getQuestions({int? limit, String? difficulty}) async {
    final response = await _dio.get('/questions/', queryParameters: {
      if (limit != null) 'limit': limit,
      if (difficulty != null) 'difficulty': difficulty,
    });
    return response.data;
  }
  
  Future<Map<String, dynamic>> getHint(int questionId) async {
    final response = await _dio.post('/questions/$questionId/hint');
    return response.data;
  }
  
  Future<Map<String, dynamic>> submitAnswer(int questionId, String answer) async {
    final response = await _dio.post('/questions/$questionId/answer', data: {
      'question_id': questionId,
      'user_answer': answer,
    });
    return response.data;
  }
  
  // SLIDES
  Future<Map<String, dynamic>> getSlideDepartments() async {
    final response = await _dio.get('/slides/departments');
    return response.data;
  }
  
  Future<Map<String, dynamic>> getDepartmentTopics(String department) async {
    final response = await _dio.get('/slides/department/$department/topics');
    return response.data;
  }
  
  Future<Map<String, dynamic>> getTopicSlides(String department, String topic) async {
    final response = await _dio.get('/slides/department/$department/topic/$topic');
    return response.data;
  }
  
  Future<Map<String, dynamic>> getSlideQuestions(int slideId) async {
    final response = await _dio.get('/slides/$slideId/questions');
    return response.data;
  }
  
  Future<Map<String, dynamic>> getDepartmentQuestions(String department) async {
    final response = await _dio.get('/slides/department/$department/questions');
    return response.data;
  }
}
