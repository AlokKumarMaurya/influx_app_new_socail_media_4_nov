import 'dart:io';
import 'package:dio/dio.dart';
import '../providers/api_client.dart';
import '../models/thread_model.dart';

class ThreadService {
  final Dio _dio = ApiClient().dio;

  Future<List<ThreadModel>> getThreads({int page = 1}) async {
    final response = await _dio.get('/threads', queryParameters: {'page': page});
    final list = response.data['data']['data'] as List? ?? [];
    return list.map((t) => ThreadModel.fromJson(t)).toList();
  }

  Future<ThreadModel> getThread(int id) async {
    final response = await _dio.get('/threads/$id');
    return ThreadModel.fromJson(response.data['data']);
  }

  Future<ThreadModel> createThread({
    required String content,
    List<File> attachments = const [],
  }) async {
    final formData = FormData.fromMap({'content': content});

    for (var file in attachments) {
      formData.files.add(MapEntry(
        'attachments[]',
        await MultipartFile.fromFile(file.path),
      ));
    }

    final response = await _dio.post('/threads/store', data: formData);
    return ThreadModel.fromJson(response.data['data']);
  }

  Future<ThreadModel> replyThread({
    required int threadId,
    required String content,
    List<File> attachments = const [],
  }) async {
    final formData = FormData.fromMap({'content': content});

    for (var file in attachments) {
      formData.files.add(MapEntry(
        'attachments[]',
        await MultipartFile.fromFile(file.path),
      ));
    }

    final response = await _dio.post('/threads/$threadId/reply', data: formData);
    return ThreadModel.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> toggleReaction(int threadId) async {
    final response = await _dio.post('/threads/react/$threadId');
    return response.data;
  }

  Future<ThreadModel> updateThread({
    required int threadId,
    required String content,
  }) async {
    final response = await _dio.post('/threads/$threadId/update', data: {
      'content': content,
    });
    return ThreadModel.fromJson(response.data['data']);
  }

  Future<ThreadModel> updateReply({
    required int replyId,
    required String content,
  }) async {
    final response = await _dio.post('/threads/reply/$replyId/update', data: {
      'content': content,
    });
    return ThreadModel.fromJson(response.data['data']);
  }

  Future<void> deleteThread(int threadId) async {
    await _dio.delete('/threads/$threadId');
  }

  Future<void> deleteReply(int replyId) async {
    await _dio.delete('/threads/reply/$replyId');
  }
}
