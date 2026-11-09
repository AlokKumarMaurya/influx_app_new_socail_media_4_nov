import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../data/models/ticket_model.dart';
import '../data/services/support_service.dart';

class SupportController extends GetxController {
  final SupportService _supportService = SupportService();

  // Tickets List
  var tickets = <TicketModel>[].obs;
  var ticketsLoading = false.obs;
  var ticketsPage = 1;
  var hasMoreTickets = true.obs;

  // Single Ticket Details
  var currentTicket = Rxn<TicketModel>();
  var ticketMessages = <TicketMessageModel>[].obs;
  var detailsLoading = false.obs;

  // Form State
  var selectedFiles = <File>[].obs;
  var isSubmitting = false.obs;

  Future<void> fetchTickets({bool refresh = false}) async {
    if (refresh) {
      ticketsPage = 1;
      tickets.clear();
      hasMoreTickets.value = true;
    }
    if (!hasMoreTickets.value || ticketsLoading.value) return;

    ticketsLoading.value = true;
    try {
      final response = await _supportService.getTickets(ticketsPage);
      if (response['success']) {
        final List data = response['data'];
        final fetchedTickets = data.map((e) => TicketModel.fromJson(e)).toList();
        tickets.addAll(fetchedTickets);
        hasMoreTickets.value = response['next_page_url'] != null;
        if (fetchedTickets.isNotEmpty) ticketsPage++;
      }
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
    } finally {
      ticketsLoading.value = false;
    }
  }

  Future<void> fetchTicketDetails(int ticketId) async {
    detailsLoading.value = true;
    try {
      final response = await _supportService.getTicketFullData(ticketId);
      // Backend returns full ticket data including messages
      currentTicket.value = TicketModel.fromJson(response);
      final List messagesData = response['messages'];
      ticketMessages.value = messagesData.map((e) => TicketMessageModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching ticket details: $e');
      Get.snackbar('error'.tr, 'failed_to_load_ticket_details'.tr);
    } finally {
      detailsLoading.value = false;
    }
  }

  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf', 'docx', 'zip'],
    );

    if (result != null) {
      selectedFiles.addAll(result.paths.whereType<String>().map((path) => File(path)));
    }
  }

  void removeFile(int index) {
    selectedFiles.removeAt(index);
  }

  Future<bool> createTicket({
    required String subject,
    required String category,
    required String priority,
    required String message,
  }) async {
    isSubmitting.value = true;
    try {
      final response = await _supportService.createTicket(
        subject: subject,
        category: category,
        priority: priority,
        message: message,
        attachments: selectedFiles.toList(),
      );
      if (response['success']) {
        selectedFiles.clear();
        fetchTickets(refresh: true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating ticket: $e');
      Get.snackbar('error'.tr, 'failed_to_create_ticket'.tr);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> sendReply(int ticketId, String message) async {
    if (message.trim().isEmpty && selectedFiles.isEmpty) return false;

    isSubmitting.value = true;
    try {
      final response = await _supportService.replyTicket(
        ticketId,
        message,
        attachments: selectedFiles.toList(),
      );
      if (response['success']) {
        selectedFiles.clear();
        // Refresh details to show new message
        await fetchTicketDetails(ticketId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending reply: $e');
      Get.snackbar('error'.tr, 'failed_to_send_reply'.tr);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
