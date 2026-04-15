import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/reminder_preferences.dart';

class ReminderProvider extends ChangeNotifier {
  bool _isReminderEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = false;

  bool get isReminderEnabled => _isReminderEnabled;
  TimeOfDay get selectedTime => _selectedTime;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await ReminderPreferences.create();
      _isReminderEnabled = prefs.getReminderEnabled();
      _selectedTime = prefs.getReminderTime();

      if (_isReminderEnabled) {
        final isScheduled = await NotificationService().isNotificationScheduled();
        if (!isScheduled) {
          await NotificationService().scheduleDailyReminder(_selectedTime);
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> enableReminder(TimeOfDay time) async {
    _isLoading = true;
    notifyListeners();

    try {
      await NotificationService().requestPermissions();
      await NotificationService().scheduleDailyReminder(time);

      final prefs = await ReminderPreferences.create();
      await prefs.setReminderEnabled(true);
      await prefs.setReminderTime(time);

      _isReminderEnabled = true;
      _selectedTime = time;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> disableReminder() async {
    _isLoading = true;
    notifyListeners();

    try {
      await NotificationService().cancelReminder();

      final prefs = await ReminderPreferences.create();
      await prefs.setReminderEnabled(false);

      _isReminderEnabled = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateReminderTime(TimeOfDay time) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_isReminderEnabled) {
        await NotificationService().scheduleDailyReminder(time);
      }

      final prefs = await ReminderPreferences.create();
      await prefs.setReminderTime(time);

      _selectedTime = time;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
