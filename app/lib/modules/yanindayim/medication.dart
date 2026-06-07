import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Bir ilaç hatırlatması.
class Medication {
  Medication({required this.id, required this.name, required this.hour, required this.minute});

  final int id;
  final String name;
  final int hour;
  final int minute;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'hour': hour, 'minute': minute};

  factory Medication.fromJson(Map<String, dynamic> j) => Medication(
        id: j['id'] as int,
        name: j['name'] as String,
        hour: j['hour'] as int,
        minute: j['minute'] as int,
      );
}

/// İlaçları cihazda saklayan basit depo (shared_preferences + JSON).
class MedicationStore {
  static const _key = 'medications';

  Future<List<Medication>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Medication.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> save(List<Medication> meds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(meds.map((m) => m.toJson()).toList()));
  }
}
