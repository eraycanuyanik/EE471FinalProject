import 'package:shared_preferences/shared_preferences.dart';

/// Aranacak yakın kişi (örn. "anne") — cihazda saklanır.
class ContactStore {
  static const _kName = 'contact_name';
  static const _kNumber = 'contact_number';

  Future<(String, String)?> load() async {
    final p = await SharedPreferences.getInstance();
    final name = p.getString(_kName);
    final number = p.getString(_kNumber);
    if (name == null || number == null || number.isEmpty) return null;
    return (name, number);
  }

  Future<void> save(String name, String number) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, name);
    await p.setString(_kNumber, number);
  }
}
