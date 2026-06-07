import 'package:flutter/material.dart';

import '../../core/notifications.dart';
import 'medication.dart';

/// İlaç hatırlatma ekranı — ilaç ekle, listele, günlük bildirim kur.
class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final _store = MedicationStore();
  List<Medication> _meds = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final meds = await _store.load();
    setState(() => _meds = meds);
  }

  Future<void> _addMedication() async {
    final nameController = TextEditingController();
    TimeOfDay time = TimeOfDay.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('İlaç Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(labelText: 'İlaç adı'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Saat: ${time.format(ctx)}', style: const TextStyle(fontSize: 18)),
                  TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(context: ctx, initialTime: time);
                      if (picked != null) setLocal(() => time = picked);
                    },
                    child: const Text('Seç', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final med = Medication(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        name: nameController.text.trim(),
        hour: time.hour,
        minute: time.minute,
      );
      final updated = [..._meds, med];
      await _store.save(updated);
      await Notifications.scheduleDaily(med.id, med.name, med.hour, med.minute);
      setState(() => _meds = updated);
    }
  }

  Future<void> _remove(Medication m) async {
    final updated = _meds.where((e) => e.id != m.id).toList();
    await _store.save(updated);
    await Notifications.cancel(m.id);
    setState(() => _meds = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İlaçlarım')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMedication,
        icon: const Icon(Icons.add),
        label: const Text('İlaç Ekle', style: TextStyle(fontSize: 18)),
      ),
      body: _meds.isEmpty
          ? Center(
              child: Text('Henüz ilaç eklenmedi', style: Theme.of(context).textTheme.bodyLarge),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _meds.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final m = _meds[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: const Icon(Icons.medication, size: 40, color: Colors.deepOrange),
                    title: Text(m.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    subtitle: Text('Her gün ${m.timeLabel}', style: const TextStyle(fontSize: 18)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 28),
                      onPressed: () => _remove(m),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
