import 'dart:io';
import 'package:dio/dio.dart';
import '../providers/api_client.dart';
import '../models/ticket_model.dart';

class SupportService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getTickets(int page) async {
    try {
      final response = await _dio.get('/tickets', queryParameters: {'page': page});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<TicketModel> getTicketDetails(int ticketId) async {
    try {
      final response = await _dio.get('/tickets/$ticketId');
      return TicketModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTicketFullData(int ticketId) async {
    try {
      final response = await _dio.get('/tickets/$ticketId');
      return Map<String, dynamic>.from(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createTicket({
    required String subject,
    required String category,
    required String priority,
    required String message,
    List<File>? attachments,
  }) async {
    try {
      final formData = FormData.fromMap({
        'subject': subject,
        'category': category,
        'priority': priority,
        'message': message,
      });

      if (attachments != null && attachments.isNotEmpty) {
        for (var file in attachments) {
          formData.files.add(MapEntry(
            'attachments[]',
            await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
          ));
        }
      }

      final response = await _dio.post('/tickets', data: formData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> replyTicket(int ticketId, String message, {List<File>? attachments}) async {
    try {
      final formData = FormData.fromMap({
        'message': message,
      });

      if (attachments != null && attachments.isNotEmpty) {
        for (var file in attachments) {
          formData.files.add(MapEntry(
            'attachments[]',
            await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
          ));
        }
      }

      final response = await _dio.post('/tickets/$ticketId/reply', data: formData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
