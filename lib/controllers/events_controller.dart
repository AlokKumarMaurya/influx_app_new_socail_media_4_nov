import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/event_model.dart';
import '../data/services/event_service.dart';
import '../utils/app_theme.dart';

class EventsController extends GetxController {
  final EventService _eventService = EventService();

  // ─── Discover Tab ──────────────────
  final discoverEvents = <EventModel>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  int _discoverPage = 1;
  int _discoverLastPage = 1;

  // ─── Attending Tab ──────────────────
  final attendingEvents = <EventModel>[].obs;

  // ─── Hosted Tab ──────────────────
  final hostedEvents = <EventModel>[].obs;
  final isHostedLoadingMore = false.obs;
  int _hostedPage = 1;
  int _hostedLastPage = 1;

  // ─── Detail ──────────────────
  final currentEvent = Rx<EventModel?>(null);
  final isDetailLoading = true.obs;

  // ─── Create / Edit ──────────────────
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadEvents();
  }

  // ═══════════════════════════════════════════
  // Event Listing (all 3 tabs in one call)
  // ═══════════════════════════════════════════

  Future<void> loadEvents() async {
    isLoading.value = true;
    _discoverPage = 1;
    _hostedPage = 1;

    try {
      final result = await _eventService.getEvents(page: 1);
      discoverEvents.value = result['discover'] as List<EventModel>;
      attendingEvents.value = result['attending'] as List<EventModel>;
      hostedEvents.value = result['hosted'] as List<EventModel>;

      _discoverPage = result['discoverCurrentPage'] as int;
      _discoverLastPage = result['discoverLastPage'] as int;
      _hostedPage = result['hostedCurrentPage'] as int;
      _hostedLastPage = result['hostedLastPage'] as int;
    } catch (e) {
      Get.log('Load events error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshEvents() async {
    await loadEvents();
  }

  Future<void> loadMoreDiscover() async {
    if (isLoadingMore.value || _discoverPage >= _discoverLastPage) return;
    isLoadingMore.value = true;

    try {
      final result = await _eventService.getMoreDiscoverEvents(page: _discoverPage + 1);
      final newEvents = result['events'] as List<EventModel>;
      discoverEvents.addAll(newEvents);
      _discoverPage = result['currentPage'] as int;
      _discoverLastPage = result['lastPage'] as int;
    } catch (e) {
      Get.log('Load more discover events error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMoreHosted() async {
    if (isHostedLoadingMore.value || _hostedPage >= _hostedLastPage) return;
    isHostedLoadingMore.value = true;

    try {
      final result = await _eventService.getMoreHostedEvents(page: _hostedPage + 1);
      final newEvents = result['events'] as List<EventModel>;
      hostedEvents.addAll(newEvents);
      _hostedPage = result['currentPage'] as int;
      _hostedLastPage = result['lastPage'] as int;
    } catch (e) {
      Get.log('Load more hosted events error: $e');
    } finally {
      isHostedLoadingMore.value = false;
    }
  }

  // ═══════════════════════════════════════════
  // Event Detail
  // ═══════════════════════════════════════════

  Future<void> loadEventDetail(int id) async {
    isDetailLoading.value = true;
    currentEvent.value = null;

    try {
      currentEvent.value = await _eventService.getEvent(id);
    } catch (e) {
      Get.log('Load event detail error: $e');
    } finally {
      isDetailLoading.value = false;
    }
  }

  // ═══════════════════════════════════════════
  // RSVP & Ticket Purchase
  // ═══════════════════════════════════════════

  Future<void> toggleRsvp(int eventId, String status) async {
    try {
      final result = await _eventService.attendEvent(eventId, status);

      if (result['success'] == true) {
        final newGoingCount = result['going_count'] as int;
        final newInterestedCount = result['interested_count'] as int;
        final newUserStatus = result['user_status'] as String?;

        // Update in all lists
        _updateEventInList(discoverEvents, eventId, newGoingCount, newInterestedCount, newUserStatus);
        _updateEventInList(attendingEvents, eventId, newGoingCount, newInterestedCount, newUserStatus);
        _updateEventInList(hostedEvents, eventId, newGoingCount, newInterestedCount, newUserStatus);

        // Update current detail if viewing
        if (currentEvent.value?.id == eventId) {
          currentEvent.value = currentEvent.value!.copyWith(
            goingCount: newGoingCount,
            interestedCount: newInterestedCount,
            userStatus: newUserStatus,
          );
        }
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 402) {
        final data = e.response?.data;
        Get.snackbar(
          'ticket_required'.tr,
          data?['message'] ?? 'ticket_required_msg'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.amber.shade800,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar('error'.tr, 'failed_to_update_rsvp'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    }
  }

  Future<bool> buyTicket(int eventId) async {
    isSubmitting.value = true;
    try {
      final res = await _eventService.buyTicket(eventId);
      if (res['success'] == true) {
        loadEvents();
        loadEventDetail(eventId);
        return true;
      }
      return false;
    } catch (e) {
      Get.log('Buy ticket error: $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> inviteUsers(int eventId, List<int> userIds) async {
    try {
      final res = await _eventService.inviteUsers(eventId, userIds);
      if (res['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_send_invitations'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return false;
    }
  }

  Future<bool> sendInvitations(int eventId, List<int> userIds) => inviteUsers(eventId, userIds);

  void _updateEventInList(RxList<EventModel> list, int eventId, int goingCount, int interestedCount, String? userStatus) {
    final idx = list.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        goingCount: goingCount,
        interestedCount: interestedCount,
        userStatus: userStatus,
      );
    }
  }

  // ═══════════════════════════════════════════
  // Create / Update / Delete
  // ═══════════════════════════════════════════

  Future<bool> createEvent({
    required String name,
    required String type,
    required String category,
    required String startDate,
    String? endDate,
    String? location,
    String? link,
    required String description,
    bool isPaid = false,
    double ticketPrice = 0.0,
    File? coverImage,
    List<File>? materials,
  }) async {
    isSubmitting.value = true;

    try {
      await _eventService.createEvent(
        name: name,
        type: type,
        category: category,
        startDate: startDate,
        endDate: endDate,
        location: location,
        link: link,
        description: description,
        isPaid: isPaid,
        ticketPrice: ticketPrice,
        coverImage: coverImage,
        materials: materials,
      );

      loadEvents();
      return true;
    } catch (e) {
      Get.log('Create event error: $e');
      String msg = 'failed_to_create_event'.tr;
      if (e is DioException) {
        Get.log('Dio response: ${e.response?.data}');
        final resData = e.response?.data;
        if (resData is Map && resData['message'] != null) {
          msg = resData['message'].toString();
        } else if (resData is Map && resData['errors'] != null) {
          final errs = resData['errors'] as Map;
          if (errs.values.isNotEmpty && errs.values.first is List) {
            msg = (errs.values.first as List).first.toString();
          }
        }
      }
      Get.snackbar('error'.tr, msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateEvent({
    required int id,
    required String name,
    required String type,
    required String category,
    required String startDate,
    String? endDate,
    String? location,
    String? link,
    required String description,
    bool isPaid = false,
    double ticketPrice = 0.0,
    File? coverImage,
    List<File>? materials,
  }) async {
    isSubmitting.value = true;

    try {
      await _eventService.updateEvent(
        id: id,
        name: name,
        type: type,
        category: category,
        startDate: startDate,
        endDate: endDate,
        location: location,
        link: link,
        description: description,
        isPaid: isPaid,
        ticketPrice: ticketPrice,
        coverImage: coverImage,
        materials: materials,
      );

      loadEvents();
      loadEventDetail(id);
      return true;
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_update_event'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteEvent(int id) async {
    try {
      final result = await _eventService.deleteEvent(id);
      if (result['success'] == true) {
        discoverEvents.removeWhere((e) => e.id == id);
        hostedEvents.removeWhere((e) => e.id == id);
        attendingEvents.removeWhere((e) => e.id == id);
        Get.snackbar('success'.tr, 'event_deleted_successfully'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.primary,
            colorText: Colors.white);
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_delete_event'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return false;
    }
  }
}
