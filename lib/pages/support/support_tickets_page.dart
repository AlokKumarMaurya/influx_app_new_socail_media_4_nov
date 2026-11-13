import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/support_controller.dart';
import '../../utils/app_theme.dart';
import 'create_ticket_page.dart';
import 'ticket_details_page.dart';

class SupportTicketsPage extends StatefulWidget {
  const SupportTicketsPage({super.key});

  @override
  State<SupportTicketsPage> createState() => _SupportTicketsPageState();
}

class _SupportTicketsPageState extends State<SupportTicketsPage> {
  final SupportController controller = Get.put(SupportController());

  @override
  void initState() {
    super.initState();
    controller.fetchTickets(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('help_and_support'.tr, style: AppTextStyles.h2),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.ticketsLoading.value && controller.tickets.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.tickets.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchTickets(refresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.hasMoreTickets.value 
                ? controller.tickets.length + 1 
                : controller.tickets.length,
            itemBuilder: (context, index) {
              if (index == controller.tickets.length) {
                return const Center(child: CircularProgressIndicator());
              }

              final ticket = controller.tickets[index];
              return _buildTicketCard(ticket);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const CreateTicketPage()),
        backgroundColor: AppColors.primary,
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedPlusSign, color: Colors.white, size: 20),
        label: Text('new_ticket'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTicketCard(dynamic ticket) {
    Color statusColor;
    Color bgColor;
    
    switch (ticket.status) {
      case 'Open':
        statusColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.1);
        break;
      case 'Pending':
        statusColor = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        break;
      case 'Closed':
        statusColor = Colors.grey;
        bgColor = Colors.grey.withValues(alpha: 0.1);
        break;
      default:
        statusColor = Colors.blue;
        bgColor = Colors.blue.withValues(alpha: 0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                ticket.subject,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ticket.status.toString().toLowerCase().tr.isNotEmpty ? ticket.status.toString().toLowerCase().tr : ticket.status,
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Text(ticket.category, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Text('•', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Text('#TK-${ticket.id}', style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${'last_updated'.tr}: ${ticket.lastReplyAt}',
              style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary.withValues(alpha: 0.7)),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.to(() => TicketDetailsPage(ticketId: ticket.id)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedLifebuoy,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            size: 80,
          ),
          const SizedBox(height: 24),
          Text('no_tickets_found'.tr, style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Text(
            'no_tickets_description'.tr,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
