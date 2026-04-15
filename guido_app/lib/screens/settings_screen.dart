import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/reminder_provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: const Color(0xFF1E1E2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<ReminderProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Study Reminders',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_active_outlined, color: Color(0xFF2563EB)),
                      title: const Text('Daily Reminder', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(kIsWeb ? 'Push notifications are available on mobile only' : 'Get a daily nudge to keep learning'),
                      trailing: Switch(
                        value: provider.isReminderEnabled,
                        onChanged: kIsWeb ? null : (val) async {
                          if (val) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: provider.selectedTime,
                            );
                            if (time != null && context.mounted) {
                              await provider.enableReminder(time);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder set for ${_formatTime(time)}')));
                            }
                          } else {
                            await provider.disableReminder();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder cancelled')));
                            }
                          }
                        },
                      ),
                    ),
                    if (provider.isReminderEnabled && !kIsWeb) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.access_time_rounded, color: Color(0xFF6B7280)),
                        title: const Text('Reminder Time', style: TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(_formatTime(provider.selectedTime)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: provider.selectedTime,
                          );
                          if (time != null && context.mounted) {
                            await provider.updateReminderTime(time);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder updated to ${_formatTime(time)}')));
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Reminders are stored on your device. No account or internet connection needed.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ),
              if (kDebugMode && !kIsWeb) ...[
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    NotificationService().showTestNotification();
                  },
                  child: const Text('Send Test Notification Now'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
