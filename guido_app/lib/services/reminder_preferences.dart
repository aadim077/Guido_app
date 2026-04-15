import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderPreferences {
  static const String _keyEnabled = 'reminder_enabled';
  static const String _keyHour = 'reminder_hour';
  static const String _keyMinute = 'reminder_minute';

  final SharedPreferences _prefs;

  ReminderPreferences(this._prefs);

  static Future<ReminderPreferences> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderPreferences(prefs);
  }

  bool getReminderEnabled() {
    return _prefs.getBool(_keyEnabled) ?? false;
  }

  Future<void> setReminderEnabled(bool value) async {
    await _prefs.setBool(_keyEnabled, value);
  }

  TimeOfDay getReminderTime() {
    final hour = _prefs.getInt(_keyHour) ?? 9;
    final minute = _prefs.getInt(_keyMinute) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    await _prefs.setInt(_keyHour, time.hour);
    await _prefs.setInt(_keyMinute, time.minute);
  }

  Future<void> clearReminderSettings() async {
    await _prefs.remove(_keyEnabled);
    await _prefs.remove(_keyHour);
    await _prefs.remove(_keyMinute);
  }
}
