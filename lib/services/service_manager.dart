import 'package:shared_preferences/shared_preferences.dart';

class ServiceManager {
  static final ServiceManager _instance = ServiceManager._internal();
  factory ServiceManager() => _instance;
  ServiceManager._internal() {
    _loadServices();
  }

  final List<String> _services = [];

  List<String> get services => _services;

  Future<void> _loadServices() async {
    final prefs = await SharedPreferences.getInstance();
    final savedServices = prefs.getStringList('services') ?? [];
    _services.clear();
    _services.addAll(savedServices);
  }

  Future<void> _saveServices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('services', _services);
  }

  void addService(String service) {
    _services.add(service);
    _saveServices();
  }

  void removeService(int index) {
    if (index >= 0 && index < _services.length) {
      _services.removeAt(index);
      _saveServices();
    }
  }
}
