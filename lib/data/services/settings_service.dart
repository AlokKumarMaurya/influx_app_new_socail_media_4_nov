import 'dart:io';
import 'package:dio/dio.dart' as dio;
import '../providers/api_client.dart';

class SettingsService {
  final ApiClient apiClient = ApiClient();

  Future<Map<String, dynamic>> updateGeneral(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.dio.post('/settings/general', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateNotifications(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.dio.post('/settings/notifications', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updatePrivacy(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.dio.post('/settings/privacy', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> changePassword(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.dio.post('/settings/password', data: data);
      return response.data;
    } catch (e) {
      if (e is dio.DioException && e.response?.data is Map) {
        final resp = e.response!.data as Map;
        final errors = resp['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final List<String> allMsgs = [];
          for (final val in errors.values) {
            if (val is List) {
              for (final item in val) {
                allMsgs.add(item.toString());
              }
            } else if (val is String) {
              allMsgs.add(val);
            }
          }
          if (allMsgs.isNotEmpty) {
            return {'success': false, 'message': allMsgs.join('\n')};
          }
        }
        if (resp['message'] != null) {
          return {'success': false, 'message': resp['message'].toString()};
        }
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getSessions() async {
    try {
      final response = await apiClient.dio.get('/settings/sessions');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> revokeSession(int id) async {
    try {
      final response = await apiClient.dio.delete('/settings/sessions/$id');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> revokeAllSessions() async {
    try {
      final response = await apiClient.dio.delete('/settings/sessions');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBlockedUsers() async {
    try {
      final response = await apiClient.dio.get('/settings/blocked');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> unblockUser(int id) async {
    try {
      final response = await apiClient.dio.delete('/settings/blocked/$id');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getKycStatus() async {
    try {
      final response = await apiClient.dio.get('/settings/kyc');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> submitKyc({
    required String documentType,
    String? documentNumber,
    File? documentFront,
    File? documentBack,
    File? selfie,
    Map<String, dynamic>? customFields,
    Map<String, File>? customFiles,
  }) async {
    try {
      final map = <String, dynamic>{
        'document_type': documentType,
      };

      if (documentNumber != null && documentNumber.isNotEmpty) {
        map['document_number'] = documentNumber;
      }

      if (documentFront != null) {
        map['document_front'] =
            await dio.MultipartFile.fromFile(documentFront.path);
      }
      if (documentBack != null) {
        map['document_back'] =
            await dio.MultipartFile.fromFile(documentBack.path);
      }
      if (selfie != null) {
        map['selfie'] = await dio.MultipartFile.fromFile(selfie.path);
      }

      if (customFields != null) {
        customFields.forEach((key, value) {
          map['fields[$key]'] = value;
        });
      }

      if (customFiles != null) {
        for (final entry in customFiles.entries) {
          map['custom_files[${entry.key}]'] =
              await dio.MultipartFile.fromFile(entry.value.path);
        }
      }

      final formData = dio.FormData.fromMap(map);
      final response = await apiClient.dio.post('/settings/kyc', data: formData);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteAccount(String password) async {
    try {
      final response = await apiClient.dio.post('/settings/delete-account', data: {
        'password': password,
      });
      return response.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getProfessionalStatus() async {
    try {
      final response = await apiClient.dio.get('/settings/professional');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> upgradeToCreator() async {
    try {
      final response = await apiClient.dio.post('/settings/upgrade-creator');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> upgradeToBusiness({
    required String businessName,
    String? businessRegistration,
  }) async {
    try {
      final response = await apiClient.dio.post('/settings/upgrade-business', data: {
        'business_name': businessName,
        'business_registration_number': businessRegistration,
      });
      return response.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getProfileCustomFields() async {
    try {
      final response = await apiClient.dio.get('/profile-custom-fields');
      if (response.data['success'] == true && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
