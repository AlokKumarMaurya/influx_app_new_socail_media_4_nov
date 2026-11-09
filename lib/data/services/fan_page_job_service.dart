import 'dart:io';
import 'package:dio/dio.dart';
import '../models/fan_page_job_model.dart';
import '../models/fan_page_job_application_model.dart';
import '../providers/api_client.dart';

class FanPageJobService {
  final Dio _dio = ApiClient().dio;

  Future<List<FanPageJobApplicationModel>> getMyApplications({String? stage}) async {
    try {
      final res = await _dio.get('/jobs/my-applications', queryParameters: {
        if (stage != null && stage.isNotEmpty && stage != 'all') 'stage': stage,
      });

      if (res.data['success'] == true) {
        final list = res.data['data'] as List;
        return list.map((e) => FanPageJobApplicationModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<FanPageJobModel>> exploreAllJobs({
    String? type,
    String? workplace,
    String? query,
    int page = 1,
  }) async {
    try {
      final res = await _dio.get('/jobs/explore', queryParameters: {
        if (type != null && type.isNotEmpty && type != 'all') 'job_type': type,
        if (workplace != null && workplace.isNotEmpty && workplace != 'all') 'workplace_type': workplace,
        if (query != null && query.isNotEmpty) 'search': query,
        'page': page,
      });

      final items = (res.data['data'] as List)
          .map((e) => FanPageJobModel.fromJson(e))
          .toList();

      return items;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getJobs(
    String slug, {
    String? type,
    String? workplace,
    String? query,
  }) async {
    try {
      final res = await _dio.get('/fan-pages/$slug/jobs', queryParameters: {
        if (type != null && type.isNotEmpty && type != 'all') 'job_type': type,
        if (workplace != null && workplace.isNotEmpty && workplace != 'all') 'workplace_type': workplace,
        if (query != null && query.isNotEmpty) 'q': query,
      });

      final bool canManage = res.data['can_manage'] == true;
      final items = (res.data['data'] as List)
          .map((e) => FanPageJobModel.fromJson(e))
          .toList();

      return {
        'can_manage': canManage,
        'jobs': items,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<FanPageJobModel> getJobDetails(String slug, int jobId) async {
    try {
      final res = await _dio.get('/fan-pages/$slug/jobs/$jobId');
      return FanPageJobModel.fromJson(res.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getJobById(int jobId) async {
    try {
      final res = await _dio.get('/jobs/$jobId');
      return {
        'can_manage': res.data['can_manage'] == true,
        'job': FanPageJobModel.fromJson(res.data['data']),
        'my_application': res.data['my_application'],
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<FanPageJobModel> createJob(String slug, Map<String, dynamic> data, {File? imageFile}) async {
    try {
      final formData = FormData.fromMap(data);
      if (imageFile != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last),
        ));
      }
      final res = await _dio.post('/fan-pages/$slug/jobs', data: formData);
      return FanPageJobModel.fromJson(res.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<FanPageJobModel> updateJob(String slug, int jobId, Map<String, dynamic> data, {File? imageFile}) async {
    try {
      final formData = FormData.fromMap(data);
      if (imageFile != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last),
        ));
      }
      final res = await _dio.post('/fan-pages/$slug/jobs/$jobId/update', data: formData);
      return FanPageJobModel.fromJson(res.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<FanPageJobModel> updateJobStatus(int jobId, String status, {String? pageSlug}) async {
    try {
      final url = (pageSlug != null && pageSlug.isNotEmpty)
          ? '/fan-pages/$pageSlug/jobs/$jobId/status'
          : '/jobs/$jobId/status';
      final res = await _dio.post(url, data: {'status': status});
      return FanPageJobModel.fromJson(res.data['data'] ?? res.data['job']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteJob(String slug, int jobId) async {
    try {
      await _dio.delete('/fan-pages/$slug/jobs/$jobId');
    } catch (e) {
      rethrow;
    }
  }

  Future<FanPageJobApplicationModel> applyToJob(
    String slug,
    int jobId, {
    required String fullName,
    required String email,
    String? phone,
    String? coverLetter,
    num? experienceYears,
    String? expectedSalary,
    String? noticePeriod,
    String? linkedinUrl,
    String? githubUrl,
    String? portfolioUrl,
    File? resumeFile,
  }) async {
    try {
      final Map<String, dynamic> map = {
        'full_name': fullName,
        'email': email,
      };
      if (phone != null && phone.isNotEmpty) map['phone'] = phone;
      if (coverLetter != null && coverLetter.isNotEmpty) map['cover_letter'] = coverLetter;
      if (experienceYears != null) map['experience_years'] = experienceYears;
      if (expectedSalary != null && expectedSalary.isNotEmpty) map['expected_salary'] = expectedSalary;
      if (noticePeriod != null && noticePeriod.isNotEmpty) map['notice_period'] = noticePeriod;
      if (linkedinUrl != null && linkedinUrl.isNotEmpty) map['linkedin_url'] = linkedinUrl;
      if (githubUrl != null && githubUrl.isNotEmpty) map['github_url'] = githubUrl;
      if (portfolioUrl != null && portfolioUrl.isNotEmpty) map['portfolio_url'] = portfolioUrl;

      if (resumeFile != null) {
        final filename = resumeFile.path.split('/').last;
        map['resume'] = await MultipartFile.fromFile(
          resumeFile.path,
          filename: filename,
        );
      }

      final formData = FormData.fromMap(map);
      final res = await _dio.post(
        '/fan-pages/$slug/jobs/$jobId/apply',
        data: formData,
      );

      return FanPageJobApplicationModel.fromJson(res.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FanPageJobApplicationModel>> getJobApplications(
    String slug,
    int jobId, {
    String? stage,
  }) async {
    try {
      final res = await _dio.get(
        '/fan-pages/$slug/jobs/$jobId/applications',
        queryParameters: {
          if (stage != null && stage.isNotEmpty && stage != 'all') 'stage': stage,
        },
      );

      final items = (res.data['data'] as List)
          .map((e) => FanPageJobApplicationModel.fromJson(e))
          .toList();

      return items;
    } catch (e) {
      rethrow;
    }
  }

  Future<FanPageJobApplicationModel> updateApplicationStage(
    String slug,
    int jobId,
    int applicationId, {
    required String stage,
    String? notes,
    int? rating,
  }) async {
    try {
      final Map<String, dynamic> data = {'stage': stage};
      if (notes != null) data['internal_notes'] = notes;
      if (rating != null) data['rating'] = rating;

      final res = await _dio.post(
        '/fan-pages/$slug/jobs/$jobId/applications/$applicationId/stage',
        data: data,
      );

      return FanPageJobApplicationModel.fromJson(res.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}
